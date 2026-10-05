"""
Avaliador em memória de consultas SQLAlchemy para os testes de API.

O MockAsyncSession original roteia pelo nome da tabela e adivinha filtros pelos parâmetros,
o que basta para buscas por ID mas não para o feed (RF14/RF15), que filtra por visibilidade,
biótipo, ocasião e texto. Este módulo interpreta de verdade o WHERE, ORDER BY, LIMIT e
GROUP BY das formas que o feed usa, sobre listas de objetos ORM, para que os testes
exercitem a semântica das consultas de produção e não uma versão simplificada delas.

Suporta: comparações (=, !=, <, <=, >, >=), IS/IS NOT, IN/NOT IN com lista ou subconsulta,
AND/OR, ILIKE/LIKE com escape, CAST para texto (JSONB vira JSON), ORDER BY asc/desc, LIMIT,
e SELECT de entidade, de colunas ou de coluna + count() com GROUP BY.
"""

import json
import re
from datetime import datetime
from typing import Any, Callable, Dict, Iterable, List

from sqlalchemy.sql import operators
from sqlalchemy.sql.elements import (
    BinaryExpression,
    BindParameter,
    BooleanClauseList,
    Cast,
    False_,
    Grouping,
    Null,
    True_,
    UnaryExpression,
)
from sqlalchemy.sql.functions import count as Count
from sqlalchemy.sql.selectable import ScalarSelect, Select

# Tabela -> linhas (objetos ORM); a função é chamada a cada consulta para ver o estado atual
TableSource = Callable[[str], Iterable[Any]]


class UnsupportedClause(NotImplementedError):
    """A consulta usa algo que o avaliador não conhece: falhar alto é melhor que errar quieto."""


def _like_to_regex(pattern: str, escape: str | None, flags: int) -> re.Pattern:
    out, i = [], 0
    while i < len(pattern):
        ch = pattern[i]
        if escape and ch == escape and i + 1 < len(pattern):
            out.append(re.escape(pattern[i + 1]))
            i += 2
            continue
        out.append(".*" if ch == "%" else "." if ch == "_" else re.escape(ch))
        i += 1
    return re.compile("^" + "".join(out) + "$", flags | re.S)


class Evaluator:
    def __init__(self, source: TableSource):
        self._source = source

    # --- SELECT -----------------------------------------------------------------

    def select(self, stmt: Select) -> List[Any]:
        froms = stmt.get_final_froms()
        if len(froms) != 1:
            raise UnsupportedClause("Só consultas de uma tabela (use subconsultas em IN).")
        rows = [r for r in self._source(froms[0].name) if self.matches(stmt.whereclause, r)]

        for clause in reversed(stmt._order_by_clauses):
            descending = isinstance(clause, UnaryExpression) and clause.modifier is operators.desc_op
            column = clause.element if isinstance(clause, UnaryExpression) else clause
            rows.sort(key=lambda r: self._sort_key(self.value(column, r)), reverse=descending)

        descriptions = stmt.column_descriptions
        if stmt._group_by_clauses:
            rows = self._group(stmt, rows)
        elif len(descriptions) == 1 and descriptions[0]["expr"] is descriptions[0]["entity"]:
            pass  # select(Entidade): devolve os próprios objetos
        elif len(descriptions) == 1:
            rows = [self.value(stmt.selected_columns[0], r) for r in rows]
        else:
            rows = [tuple(self.value(c, r) for c in stmt.selected_columns) for r in rows]

        if stmt._limit is not None:
            rows = rows[: stmt._limit]
        return rows

    def _group(self, stmt: Select, rows: List[Any]) -> List[tuple]:
        keys = stmt._group_by_clauses
        groups: Dict[tuple, List[Any]] = {}
        for r in rows:
            groups.setdefault(tuple(self.value(k, r) for k in keys), []).append(r)
        result = []
        for key, members in groups.items():
            values = []
            for column in stmt.selected_columns:
                if isinstance(column, Count):
                    values.append(len(members))
                else:
                    values.append(self.value(column, members[0]))
            result.append(tuple(values))
        return result

    @staticmethod
    def _sort_key(v: Any):
        # Nulos por último, como no ASC do Postgres; o feed só ordena por colunas NOT NULL
        return (v is None, v.timestamp() if isinstance(v, datetime) else v)

    # --- WHERE / DELETE ----------------------------------------------------------

    def matching_rows(self, table: str, whereclause) -> List[Any]:
        return [r for r in self._source(table) if self.matches(whereclause, r)]

    def matches(self, clause, row) -> bool:
        if clause is None:
            return True
        if isinstance(clause, Grouping):
            return self.matches(clause.element, row)
        if isinstance(clause, BooleanClauseList):
            results = (self.matches(c, row) for c in clause.clauses)
            if clause.operator is operators.and_:
                return all(results)
            if clause.operator is operators.or_:
                return any(results)
            raise UnsupportedClause(f"Lista booleana {clause.operator}")
        if isinstance(clause, BinaryExpression):
            return self._binary(clause, row)
        if isinstance(clause, True_):
            return True
        if isinstance(clause, False_):
            return False
        raise UnsupportedClause(f"Cláusula {type(clause).__name__}")

    def _binary(self, clause: BinaryExpression, row) -> bool:
        op = clause.operator
        left = self.value(clause.left, row)
        right = self.value(clause.right, row)
        if op is operators.eq:
            return left is not None and left == right
        if op is operators.ne:
            return left is not None and right is not None and left != right
        if op in (operators.lt, operators.le, operators.gt, operators.ge):
            if left is None or right is None:
                return False
            return op(left, right)
        if op is operators.is_:
            return left is right or left == right
        if op is operators.is_not:
            return not (left is right or left == right)
        if op is operators.in_op:
            return left in right
        if op is operators.not_in_op:
            return left not in right
        if op in (operators.ilike_op, operators.like_op):
            if left is None:
                return False
            flags = re.I if op is operators.ilike_op else 0
            return _like_to_regex(right, clause.modifiers.get("escape"), flags).match(str(left)) is not None
        raise UnsupportedClause(f"Operador {op}")

    # --- Valores -----------------------------------------------------------------

    def value(self, expr, row) -> Any:
        if isinstance(expr, BindParameter):
            return expr.effective_value
        if isinstance(expr, True_):
            return True
        if isinstance(expr, False_):
            return False
        if isinstance(expr, Null):
            return None
        if isinstance(expr, Grouping):
            return self.value(expr.element, row)
        if isinstance(expr, Cast):
            inner = self.value(expr.clause, row)
            if isinstance(inner, (list, dict)):
                return json.dumps(inner, ensure_ascii=False)
            return None if inner is None else str(inner)
        if isinstance(expr, ScalarSelect):
            return self.select(expr.element)
        if isinstance(expr, Select):
            return self.select(expr)
        if hasattr(expr, "table") and hasattr(expr, "key"):
            return getattr(row, expr.key)
        raise UnsupportedClause(f"Expressão {type(expr).__name__}")
