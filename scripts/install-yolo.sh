#!/bin/bash
# LM Light - YOLO Model Installer
# Downloads YOLO model for object detection functionality

set -e

INSTALL_DIR="${HOME}/.local/lmlight"
MODEL_DIR="${INSTALL_DIR}/models/yolo"

# Available models
show_usage() {
    echo "使用方法: $0 [モデル名]"
    echo ""
    echo "モデル一覧:"
    echo "  yolov8n - 6MB   (デフォルト、軽量・高速)"
    echo "  yolov8s - 22MB  (バランス型)"
    echo "  yolov8m - 52MB  (高精度)"
    echo "  yolov8l - 87MB  (高精度・GPU推奨)"
    echo "  yolov8x - 131MB (最高精度・GPU推奨)"
    echo ""
    echo "例:"
    echo "  $0              # yolov8nをインストール"
    echo "  $0 yolov8s      # yolov8sをインストール"
    echo ""
    echo "カスタムモデル:"
    echo "  学習済み .pt ファイルを ${MODEL_DIR}/ に配置してください"
    echo ""
    echo "リモート実行:"
    echo "  curl -fsSL https://raw.githubusercontent.com/lmlight-app/dist_v3/main/scripts/install-yolo.sh | bash -s -- yolov8s"
}

get_model_size() {
    case "$1" in
        yolov8n) echo "6MB" ;;
        yolov8s) echo "22MB" ;;
        yolov8m) echo "52MB" ;;
        yolov8l) echo "87MB" ;;
        yolov8x) echo "131MB" ;;
        *)       echo "unknown" ;;
    esac
}

# Parse arguments
MODEL_NAME="${1:-yolov8n}"

# Validate model name
if [[ ! " yolov8n yolov8s yolov8m yolov8l yolov8x " =~ " ${MODEL_NAME} " ]]; then
    echo "❌ 無効なモデル名: $MODEL_NAME"
    echo ""
    show_usage
    exit 1
fi

MODEL_URL="https://github.com/ultralytics/assets/releases/download/v8.3.0/${MODEL_NAME}.pt"
MODEL_FILE="${MODEL_DIR}/${MODEL_NAME}.pt"
MODEL_SIZE="$(get_model_size "$MODEL_NAME")"

echo "=========================================="
echo "  LM Light YOLO物体検出モデル インストーラー"
echo "=========================================="
echo ""
echo "選択モデル: ${MODEL_NAME} (${MODEL_SIZE})"
echo ""

# Check if already installed
if [ -f "$MODEL_FILE" ]; then
    echo "✅ モデルは既にインストールされています: $MODEL_FILE"
    echo ""
    echo "再インストールする場合は、まず以下を削除してください:"
    echo "  rm $MODEL_FILE"
    exit 0
fi

# Check install directory
if [ ! -d "$INSTALL_DIR" ]; then
    echo "❌ LM Lightがインストールされていません"
    echo "   先にLM Lightをインストールしてください"
    exit 1
fi

# Create model directory (don't remove existing - allow multiple models)
echo "📁 モデルディレクトリを作成: $MODEL_DIR"
mkdir -p "$MODEL_DIR"

# Download model
echo "📥 YOLO ${MODEL_NAME}モデルをダウンロード中..."
echo "   URL: $MODEL_URL"
echo "   サイズ: 約${MODEL_SIZE}"
echo ""

if command -v curl &> /dev/null; then
    curl -L --progress-bar -o "$MODEL_FILE" "$MODEL_URL"
elif command -v wget &> /dev/null; then
    wget --show-progress -O "$MODEL_FILE" "$MODEL_URL"
else
    echo "❌ curlまたはwgetが必要です"
    exit 1
fi

# Install ultralytics if not present
echo ""
echo "📦 ultralyticsパッケージを確認中..."

# Find venv pip if available
VENV_PIP=""
for venv_dir in "${INSTALL_DIR}/.venv" "${INSTALL_DIR}/venv"; do
    if [ -f "$venv_dir/bin/pip" ]; then
        VENV_PIP="$venv_dir/bin/pip"
        break
    fi
done

# Check if already installed (in venv or system)
ALREADY_INSTALLED=false
if [ -n "$VENV_PIP" ]; then
    VENV_PYTHON="$(dirname "$VENV_PIP")/python"
    if "$VENV_PYTHON" -c "import ultralytics" 2>/dev/null; then
        ALREADY_INSTALLED=true
    fi
elif python3 -c "import ultralytics" 2>/dev/null; then
    ALREADY_INSTALLED=true
fi

if [ "$ALREADY_INSTALLED" = true ]; then
    echo "✅ ultralytics は既にインストール済み"
else
    # Determine install command
    if [ -n "$VENV_PIP" ]; then
        PIP_CMD="$VENV_PIP install"
        echo "📥 ultralytics をインストール中... (venv: $VENV_PIP)"
    elif command -v uv &> /dev/null; then
        PIP_CMD="uv pip install --python python3"
        echo "📥 ultralytics をインストール中... (uv)"
    elif command -v pip3 &> /dev/null; then
        PIP_CMD="pip3 install"
        echo "📥 ultralytics をインストール中... (pip3)"
    elif command -v pip &> /dev/null; then
        PIP_CMD="pip install"
        echo "📥 ultralytics をインストール中... (pip)"
    else
        echo "❌ pip が見つかりません。venv を作成するか pip をインストールしてください"
        echo "   例: python3 -m venv ${INSTALL_DIR}/.venv && ${INSTALL_DIR}/.venv/bin/pip install ultralytics"
        exit 1
    fi

    if [ -f "${INSTALL_DIR}/api/pyproject.toml" ]; then
        $PIP_CMD -e "${INSTALL_DIR}/api[yolo]" --quiet
    else
        $PIP_CMD ultralytics --quiet
    fi
fi

# Verify download
if [ -f "$MODEL_FILE" ]; then
    SIZE=$(ls -lh "$MODEL_FILE" | awk '{print $5}')
    echo ""
    echo "✅ インストール完了!"
    echo "   モデル: ${MODEL_NAME}"
    echo "   ファイル: $MODEL_FILE"
    echo "   サイズ: $SIZE"
    echo ""
    echo "LM Lightを再起動すると、画像処理ページで物体検出が利用可能になります"
else
    echo "❌ ダウンロードに失敗しました"
    exit 1
fi
