import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';

import '../../theme/app_theme.dart';

/// Textura procedural de cada Sala (ver shaders/atelier_room.frag)
enum RoomTexture { drape, plaster, tapestry }

/// Salas Cromáticas da Renascença do Ateliê (AGENTS.md seção 4)
enum AtelierRoom {
  velvetBordeaux(AppColors.velvetBordeaux, RoomTexture.drape, 1.3),
  silkEmerald(AppColors.silkEmerald, RoomTexture.drape, 7.1),
  frescoBlue(AppColors.frescoBlue, RoomTexture.plaster, 3.7),
  verdigris(AppColors.verdigris, RoomTexture.plaster, 11.2),
  gildedOchre(AppColors.gildedOchre, RoomTexture.plaster, 5.5),
  tapestryNoir(AppColors.tapestryNoir, RoomTexture.tapestry, 2.2);

  final Color color;
  final RoomTexture texture;

  /// Desloca o ruído para que Salas com a mesma textura não pareçam iguais
  final double seed;

  const AtelierRoom(this.color, this.texture, this.seed);

  /// gildedLeaf em texto pequeno só passa 4,5:1 nas Salas profundas; nas de reboco,
  /// o dourado fica restrito a números e títulos a partir de 24pt (3:1).
  bool get allowsSmallGoldText => this == velvetBordeaux || this == silkEmerald || this == tapestryNoir;
}

/// Estado da cenografia: Sala [from] dissolvendo em [to] na proporção [t]
@immutable
class RoomBlend {
  final AtelierRoom from;
  final AtelierRoom to;
  final double t;

  const RoomBlend(this.from, this.to, this.t);
  const RoomBlend.solid(AtelierRoom room) : this(room, room, 0);

  /// Sala que predomina visualmente (define, por exemplo, o brilho da status bar)
  AtelierRoom get dominant => t < 0.5 ? from : to;

  Color get color => Color.lerp(from.color, to.color, t)!;

  @override
  bool operator ==(Object other) =>
      other is RoomBlend && other.from == from && other.to == to && other.t == t;

  @override
  int get hashCode => Object.hash(from, to, t);

  @override
  String toString() => 'RoomBlend(${from.name} → ${to.name}, ${t.toStringAsFixed(2)})';
}

/// Altura (fração da tela, a partir do topo) em que o início da próxima seção começa a trocar a Sala
const double roomTransitionStart = 0.55;

/// Fração da altura da tela que a nova seção percorre até a Sala trocar por completo
const double roomTransitionSpan = 0.4;

/// Curva da troca guiada pelo dedo: suave nas duas pontas, sem salto no início
const Curve roomScrollCurve = Curves.easeInOutCubic;

/// Resolve a Sala visível a partir do início (em offset de scroll) de cada seção.
///
/// O fundo segue a seção que está sendo lida: a troca começa quando o início da
/// próxima seção cruza [roomTransitionStart] da tela e termina depois de ela subir
/// [roomTransitionSpan]. Com [reduceMotion], a troca é um corte no meio desse trajeto.
RoomBlend resolveRoomBlend(
  List<(double, AtelierRoom)> sections, {
  required double scrollOffset,
  required double viewportExtent,
  required AtelierRoom fallback,
  bool reduceMotion = false,
}) {
  if (sections.isEmpty || viewportExtent <= 0) return RoomBlend.solid(fallback);

  final ordered = [...sections]..sort((a, b) => a.$1.compareTo(b.$1));
  var base = ordered.first.$2;

  for (final (start, room) in ordered.skip(1)) {
    final top = start - scrollOffset;
    final progress = (viewportExtent * roomTransitionStart - top) / (viewportExtent * roomTransitionSpan);

    if (progress <= 0) break;
    if (reduceMotion) {
      if (progress < 0.5) break;
      base = room;
      continue;
    }
    if (progress >= 1) {
      base = room;
      continue;
    }
    if (room == base) continue;
    final t = roomScrollCurve.transform(progress);
    if (t < 0.001) break;
    if (t > 0.999) {
      base = room;
      continue;
    }
    return RoomBlend(base, room, t);
  }
  return RoomBlend.solid(base);
}

/// Curva aplicada à dissolução fora do scroll (troca de filtro, abertura de tela)
const Curve roomDissolveCurve = AppMotion.editorialDecel;
