#!/bin/bash
# LM Light Docker Installer
# Usage:
#   Ollama版:  curl -fsSL https://raw.githubusercontent.com/lmlight-app/dist_v3/main/scripts/install-docker.sh | bash
#   vLLM版:    EDITION=vllm curl -fsSL https://raw.githubusercontent.com/lmlight-app/dist_v3/main/scripts/install-docker.sh | bash

set -e

EDITION="${EDITION:-perpetual}"
DOCKER_USER="${LMLIGHT_DOCKER_USER:-lmlight}"

if [ "$EDITION" = "vllm" ]; then
    INSTALL_DIR="${LMLIGHT_INSTALL_DIR:-$HOME/.local/lmlight-vllm}"
    API_IMAGE="$DOCKER_USER/lmlight-vllm:latest"
    DISPLAY_NAME="LM Light Docker Installer (vLLM Edition)"
else
    INSTALL_DIR="${LMLIGHT_INSTALL_DIR:-$HOME/.local/lmlight}"
    API_IMAGE="$DOCKER_USER/lmlight-perpetual:latest"
    DISPLAY_NAME="LM Light Docker Installer (Ollama Edition)"
fi

APP_IMAGE="$DOCKER_USER/lmlight-app:latest"

info() { echo -e "\033[1;34m[INFO]\033[0m $1"; }
success() { echo -e "\033[1;32m[OK]\033[0m $1"; }
error() { echo -e "\033[1;31m[ERROR]\033[0m $1"; exit 1; }
warn() { echo -e "\033[1;33m[WARN]\033[0m $1"; }

echo ""
echo "============================================================"
echo "  $DISPLAY_NAME"
echo "============================================================"
echo ""

# Check Docker
if ! command -v docker &>/dev/null; then
    error "Docker not found. Please install Docker first: https://docs.docker.com/get-docker/"
fi

if ! command -v docker compose &>/dev/null && ! command -v docker-compose &>/dev/null; then
    error "Docker Compose not found. Please install Docker Compose."
fi

success "Docker found: $(docker --version)"

# Check Ollama (perpetual only)
if [ "$EDITION" != "vllm" ]; then
    if command -v ollama &>/dev/null; then
        success "Ollama found: $(ollama --version 2>/dev/null || echo 'installed')"
    else
        warn "Ollama not found. Install from: https://ollama.com"
        warn "LM Light requires Ollama to run LLM models."
    fi
fi

# Create install directory
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# Pull Docker images from Docker Hub
info "Pulling API image ($API_IMAGE)..."
docker pull "$API_IMAGE"

info "Pulling Web image ($APP_IMAGE)..."
docker pull "$APP_IMAGE"

# Create docker-compose.yml
info "Creating docker-compose.yml..."
cat > docker-compose.yml << EOF
services:
  postgres:
    image: pgvector/pgvector:pg16
    environment:
      POSTGRES_USER: lmlight
      POSTGRES_PASSWORD: lmlight
      POSTGRES_DB: lmlight
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U lmlight"]
      interval: 5s
      timeout: 5s
      retries: 5

  api:
    image: $API_IMAGE
    ports:
      - "\${API_PORT:-8000}:8000"
    env_file: .env
    extra_hosts:
      - "host.docker.internal:host-gateway"
    volumes:
      - ./license.lic:/app/license.lic:ro
    depends_on:
      postgres:
        condition: service_healthy

  app:
    image: $APP_IMAGE
    ports:
      - "\${WEB_PORT:-3000}:3000"
    env_file: .env
    depends_on:
      - api

volumes:
  pgdata:
EOF

# Create .env file (only if not exists)
if [ ! -f .env ]; then
    info "Creating .env file..."
    if [ "$EDITION" = "vllm" ]; then
        cat > .env << 'EOF'
# =============================================================================
# LM Light Configuration (Docker - vLLM Edition)
# =============================================================================

# PostgreSQL Database
DATABASE_URL=postgresql://lmlight:lmlight@postgres:5432/lmlight

# =============================================================================
# vLLM Server URLs (running on host, accessed via host.docker.internal)
# =============================================================================
VLLM_BASE_URL=http://host.docker.internal:8080
VLLM_EMBED_BASE_URL=http://host.docker.internal:8081
# VLLM_VISION_BASE_URL=http://host.docker.internal:8082

# vLLM auto-start is disabled in Docker (start vLLM servers externally)
VLLM_AUTO_START=false

# Models (HuggingFace model IDs)
VLLM_CHAT_MODEL=Qwen/Qwen2.5-1.5B-Instruct
VLLM_EMBED_MODEL=intfloat/multilingual-e5-large-instruct
# VLLM_VISION_MODEL=Qwen/Qwen2.5-VL-7B-Instruct

# GPU Configuration
VLLM_TENSOR_PARALLEL=1
VLLM_GPU_MEMORY_UTILIZATION=0.45
VLLM_MAX_MODEL_LEN=4096

# Whisper Transcription
WHISPER_MODEL=base

# =============================================================================
# Server Configuration
# =============================================================================
API_PORT=8000
WEB_PORT=3000
LICENSE_FILE_PATH=/app/license.lic

# NextAuth
NEXTAUTH_SECRET=randomsecret123
NEXTAUTH_URL=http://localhost:3000
NEXT_PUBLIC_API_URL=http://localhost:8000
EOF
    else
        cat > .env << 'EOF'
# =============================================================================
# LM Light Configuration (Docker - Ollama Edition)
# =============================================================================

# PostgreSQL Database
DATABASE_URL=postgresql://lmlight:lmlight@postgres:5432/lmlight

# Ollama (running on host, accessed via host.docker.internal)
OLLAMA_BASE_URL=http://host.docker.internal:11434
# OLLAMA_NUM_PARALLEL=8

# =============================================================================
# Server Configuration
# =============================================================================
API_PORT=8000
WEB_PORT=3000
LICENSE_FILE_PATH=/app/license.lic

# NextAuth
NEXTAUTH_SECRET=randomsecret123
NEXTAUTH_URL=http://localhost:3000
NEXT_PUBLIC_API_URL=http://localhost:8000
EOF
    fi
fi

# Create start script
if [ "$EDITION" = "vllm" ]; then
    cat > start.sh << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"

echo "Starting LM Light (vLLM Edition)..."

docker compose up -d

echo ""
echo "LM Light is starting..."
echo "  Web UI: http://localhost:3000"
echo "  API:    http://localhost:8000"
echo ""
echo "  Note: Start vLLM servers externally (VLLM_AUTO_START=false in Docker)"
echo ""
echo "To view logs: docker compose logs -f"
echo "To stop:      docker compose down"
EOF
else
    cat > start.sh << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"

echo "Starting LM Light..."

# Check if Ollama is running
if ! curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo "Warning: Ollama is not running. Start it with: ollama serve"
fi

docker compose up -d

echo ""
echo "LM Light is starting..."
echo "  Web UI: http://localhost:3000"
echo "  API:    http://localhost:8000"
echo ""
echo "To view logs: docker compose logs -f"
echo "To stop:      docker compose down"
EOF
fi
chmod +x start.sh

# Create stop script
cat > stop.sh << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
docker compose down
echo "LM Light stopped."
EOF
chmod +x stop.sh

echo ""
echo "============================================================"
success "LM Light Docker setup complete!"
echo "============================================================"
echo ""
echo "  Edition:  $EDITION"
echo "  Location: $INSTALL_DIR"
echo ""
echo "  Next steps:"
echo "    1. Place license.lic in $INSTALL_DIR"
if [ "$EDITION" != "vllm" ]; then
echo "    2. Start Ollama: ollama serve"
echo "    3. Start LM Light: $INSTALL_DIR/start.sh"
else
echo "    2. Start vLLM servers externally"
echo "    3. Start LM Light: $INSTALL_DIR/start.sh"
fi
echo ""
echo "  Default login: admin@local / admin123"
echo ""