#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Railway Infrastructure Provisioning Script
# Cria: projeto, 4 serviços, variáveis de ambiente
# Grava os IDs como GitHub Variables no environment 'production'
# ============================================================

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log()  { echo -e "${BLUE}[INFO]${NC}  $*"; }
ok()   { echo -e "${GREEN}[OK]${NC}    $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC}  $*"; }
fail() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

# ---- Variáveis ----
PROJECT_NAME="${PROJECT_NAME:-portifolio}"
REPO="${REPO:-ElioNeto/portifolio}"
ENVIRONMENT="production"

SERVICES=("backend" "frontend-pt" "frontend-en" "frontend-es")

# ---- 1. Criar ou reutilizar projeto ----
log "Verificando projeto Railway '$PROJECT_NAME'..."

PROJECT_ID=$(railway project list --json 2>/dev/null \
  | jq -r ".[] | select(.name==\"$PROJECT_NAME\") | .id" 2>/dev/null || echo "")

if [ -z "$PROJECT_ID" ]; then
  log "Criando projeto '$PROJECT_NAME'..."
  railway project create --name "$PROJECT_NAME" --json 2>/dev/null | tee /tmp/project.json || true
  PROJECT_ID=$(cat /tmp/project.json | jq -r '.id' 2>/dev/null || echo "")

  if [ -z "$PROJECT_ID" ]; then
    # fallback: pega após criar via link
    PROJECT_ID=$(railway project list --json 2>/dev/null \
      | jq -r ".[] | select(.name==\"$PROJECT_NAME\") | .id" 2>/dev/null || echo "")
  fi
else
  ok "Projeto já existe: $PROJECT_ID"
fi

[ -z "$PROJECT_ID" ] && fail "Não foi possível obter o Project ID."
ok "Project ID: $PROJECT_ID"

# ---- 2. Criar os 4 serviços ----
declare -A SERVICE_IDS

for SVC in "${SERVICES[@]}"; do
  log "Verificando serviço '$SVC'..."

  EXISTING_ID=$(railway service list --project "$PROJECT_ID" --json 2>/dev/null \
    | jq -r ".[] | select(.name==\"$SVC\") | .id" 2>/dev/null || echo "")

  if [ -n "$EXISTING_ID" ]; then
    ok "Serviço '$SVC' já existe: $EXISTING_ID"
    SERVICE_IDS[$SVC]="$EXISTING_ID"
    continue
  fi

  log "Criando serviço '$SVC'..."
  SVC_JSON=$(railway service create \
    --name "$SVC" \
    --project "$PROJECT_ID" \
    --json 2>/dev/null || echo "{}")

  SVC_ID=$(echo "$SVC_JSON" | jq -r '.id' 2>/dev/null || echo "")

  # fallback: busca pelo nome
  if [ -z "$SVC_ID" ] || [ "$SVC_ID" = "null" ]; then
    SVC_ID=$(railway service list --project "$PROJECT_ID" --json 2>/dev/null \
      | jq -r ".[] | select(.name==\"$SVC\") | .id" 2>/dev/null || echo "")
  fi

  [ -z "$SVC_ID" ] && fail "Não foi possível criar o serviço '$SVC'."
  ok "Serviço '$SVC' criado: $SVC_ID"
  SERVICE_IDS[$SVC]="$SVC_ID"
done

# ---- 3. Configurar variáveis de ambiente nos serviços ----
log "Configurando variáveis de ambiente..."

# Backend
railway variables set \
  --service "${SERVICE_IDS[backend]}" \
  --project "$PROJECT_ID" \
  PORT=8080 \
  ALLOWED_ORIGINS="https://portifolio-pt.up.railway.app" 2>/dev/null || warn "Vars do backend já existem ou erro na configuração."

ok "Variáveis do backend configuradas."

# ---- 4. Gravar IDs como GitHub Variables no environment ----
log "Gravando IDs como GitHub Variables no environment '$ENVIRONMENT'..."

set_gh_var() {
  local KEY="$1"
  local VALUE="$2"
  log "  Setting $KEY=$VALUE"
  gh api \
    --method POST \
    -H "Accept: application/vnd.github+json" \
    "/repos/$REPO/environments/$ENVIRONMENT/variables" \
    -f name="$KEY" \
    -f value="$VALUE" 2>/dev/null || \
  gh api \
    --method PATCH \
    -H "Accept: application/vnd.github+json" \
    "/repos/$REPO/environments/$ENVIRONMENT/variables/$KEY" \
    -f value="$VALUE" 2>/dev/null || \
  warn "Não foi possível gravar $KEY (ambiente pode precisar ser criado manualmente)."
}

set_gh_var "RAILWAY_PROJECT_ID"           "$PROJECT_ID"
set_gh_var "RAILWAY_BACKEND_SERVICE"      "${SERVICE_IDS[backend]}"
set_gh_var "RAILWAY_FRONTEND_PT_SERVICE" "${SERVICE_IDS[frontend-pt]}"
set_gh_var "RAILWAY_FRONTEND_EN_SERVICE" "${SERVICE_IDS[frontend-en]}"
set_gh_var "RAILWAY_FRONTEND_ES_SERVICE" "${SERVICE_IDS[frontend-es]}"

# BACKEND_URL: usa override ou monta a URL padrão do Railway
if [ -n "${BACKEND_URL_OVERRIDE:-}" ]; then
  BACKEND_URL="$BACKEND_URL_OVERRIDE"
else
  BACKEND_URL="https://backend.up.railway.app"
  warn "BACKEND_URL não informada. Usando placeholder: $BACKEND_URL"
  warn "Atualize a variável BACKEND_URL após o primeiro deploy do backend."
fi
set_gh_var "BACKEND_URL" "$BACKEND_URL"

# ---- 5. Resumo ----
echo ""
echo "========================================="
ok "INFRA PROVISIONADA COM SUCESSO!"
echo "========================================="
echo ""
echo "  Projeto  : $PROJECT_NAME ($PROJECT_ID)"
echo ""
for SVC in "${SERVICES[@]}"; do
  echo "  $SVC : ${SERVICE_IDS[$SVC]}"
done
echo ""
warn "Próximos passos:"
echo "  1. Verifique as variáveis em:"
echo "     https://github.com/$REPO/settings/environments"
echo "  2. Rode: Deploy Backend → Railway"
echo "  3. Rode: Deploy Frontend → Railway"
echo "  4. Atualize BACKEND_URL com a URL real gerada pelo Railway."
echo ""
