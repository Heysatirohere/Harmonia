#!/usr/bin/env bash
# Deploy da API do HarmonIA no Google Cloud Run, na região do banco (RNF03, RNF04).
#
# O Supabase do projeto fica na AWS ca-central-1 (Montreal); a região do Cloud Run mais
# próxima é northamerica-northeast1, também em Montreal. O host direto do banco
# (db.<ref>.supabase.co) só tem IPv6, que o Cloud Run não usa sem rede extra, então a API
# conecta pelo pooler de sessão IPv4 do Supabase.
#
# Pré-requisitos: gcloud instalado, `gcloud auth login`, um projeto com faturamento ativo e
# backend/.env preenchido. Uso, a partir de backend/:
#     PROJECT_ID=meu-projeto ./deploy/cloud_run.sh
set -euo pipefail

: "${PROJECT_ID:?Defina PROJECT_ID com o id do projeto no Google Cloud}"
REGION="${REGION:-northamerica-northeast1}"
SERVICE="${SERVICE:-harmonia-api}"
POOLER_HOST="${POOLER_HOST:-aws-0-ca-central-1.pooler.supabase.com}"

cd "$(dirname "$0")/.."
env_value() { grep -E "^$1=" .env | head -1 | cut -d= -f2-; }

DIRECT_URL="$(env_value DATABASE_URL)"
SUPABASE_URL="$(env_value SUPABASE_URL)"
SUPABASE_KEY="$(env_value SUPABASE_KEY)"
SERVICE_ROLE_KEY="$(env_value SUPABASE_SERVICE_ROLE_KEY)"
JWT_SECRET="$(env_value SUPABASE_JWT_SECRET || true)"

# postgresql+asyncpg://postgres:<senha>@db.<ref>.supabase.co:5432/postgres
#   -> postgresql+asyncpg://postgres.<ref>:<senha>@<pooler>:5432/postgres (modo sessão)
REF="$(sed -E 's#.*@db\.([a-z0-9]+)\.supabase\.co.*#\1#' <<<"$DIRECT_URL")"
POOLER_URL="$(sed -E "s#://postgres:#://postgres.${REF}:#; s#@db\.${REF}\.supabase\.co:5432#@${POOLER_HOST}:5432#" <<<"$DIRECT_URL")"

gcloud config set project "$PROJECT_ID" >/dev/null
gcloud services enable run.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com \
  secretmanager.googleapis.com

# Segredos no Secret Manager, nunca em variáveis de ambiente do serviço
put_secret() {
  if gcloud secrets describe "$1" >/dev/null 2>&1; then
    printf '%s' "$2" | gcloud secrets versions add "$1" --data-file=- >/dev/null
  else
    printf '%s' "$2" | gcloud secrets create "$1" --data-file=- --replication-policy=automatic >/dev/null
  fi
}
put_secret harmonia-database-url "$POOLER_URL"
put_secret harmonia-service-role-key "$SERVICE_ROLE_KEY"
SECRETS="DATABASE_URL=harmonia-database-url:latest,SUPABASE_SERVICE_ROLE_KEY=harmonia-service-role-key:latest"
if [[ -n "$JWT_SECRET" ]]; then
  put_secret harmonia-jwt-secret "$JWT_SECRET"
  SECRETS="$SECRETS,SUPABASE_JWT_SECRET=harmonia-jwt-secret:latest"
fi

# A conta padrão do Cloud Run precisa ler os segredos
NUMBER="$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)')"
for secret in harmonia-database-url harmonia-service-role-key ${JWT_SECRET:+harmonia-jwt-secret}; do
  gcloud secrets add-iam-policy-binding "$secret" \
    --member="serviceAccount:${NUMBER}-compute@developer.gserviceaccount.com" \
    --role=roles/secretmanager.secretAccessor >/dev/null
done

# rembg + CLIP somam ~1 GB em memória; poucas instâncias para caber no limite de conexões do pooler.
# A API é pública na rede, mas toda rota de dados exige o JWT do Supabase.
gcloud run deploy "$SERVICE" \
  --source . \
  --region "$REGION" \
  --memory 2Gi --cpu 2 --cpu-boost \
  --timeout 120 \
  --min-instances 0 --max-instances 2 \
  --allow-unauthenticated \
  --set-env-vars "ENVIRONMENT=production,SUPABASE_URL=${SUPABASE_URL},SUPABASE_KEY=${SUPABASE_KEY},SUPABASE_STORAGE_BUCKET=wardrobe-items" \
  --set-secrets "$SECRETS"

URL="$(gcloud run services describe "$SERVICE" --region "$REGION" --format='value(status.url)')"
echo
echo "API no ar: $URL"
echo "Saúde:     curl $URL/api/v1/health"
echo "App:       flutter run --dart-define=API_BASE_URL=$URL"
