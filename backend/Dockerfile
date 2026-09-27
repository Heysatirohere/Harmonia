# Dockerfile de Produção para a API FastAPI do HarmonIA
FROM python:3.11-slim

# Garantir desativação de buffer de saída e bytecodes .pyc
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# Instalação de utilitários do sistema
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Instalação das dependências Python
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copiar a aplicação FastAPI
COPY app ./app

# Exposição da porta da aplicação
EXPOSE 8000

# Execução do servidor Uvicorn em produção
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
