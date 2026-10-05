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

# Baixa o modelo de recorte de fundo (RF04) no build, evitando o download na primeira requisição
ENV SEGMENTATION_MODEL=isnet-general-use
RUN python -c "import os; from rembg import new_session; new_session(os.environ['SEGMENTATION_MODEL'])"

# Baixa o modelo do vetor de estilo (S_cos) no build, conferido pelo SHA-256 (mesmos valores de app/core/config.py)
ENV STYLE_MODEL_PATH=/opt/harmonia/clip-vit-b32-vision.onnx
RUN mkdir -p /opt/harmonia && \
    curl -fsSL -o "$STYLE_MODEL_PATH" \
    "https://huggingface.co/Xenova/clip-vit-base-patch32/resolve/d15189d7028b43f1d3e65039190477f6af591c2a/onnx/vision_model.onnx" && \
    echo "fd6e1402a588279d1723c7534d4bcba5bc0b14b47dfab0e46f8c47b8270d7d40  $STYLE_MODEL_PATH" | sha256sum -c -

# Copiar a aplicação FastAPI
COPY app ./app

# Exposição da porta da aplicação (padrão 8000 local, Cloud Run injeta $PORT)
EXPOSE 8000

# Execução do servidor Uvicorn em produção compatível com Google Cloud Run
CMD ["sh", "-c", "exec uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]
