#!/bin/bash
# LM Light - Transcription Model Installer
# Downloads Whisper tiny model for speech-to-text functionality

set -e

MODEL_URL="https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.bin"
INSTALL_DIR="${HOME}/.local/lmlight"
MODEL_DIR="${INSTALL_DIR}/models/whisper"
MODEL_FILE="${MODEL_DIR}/ggml-tiny.bin"

echo "=========================================="
echo "  LM Light 文字起こしモデル インストーラー"
echo "=========================================="
echo ""

# Check if already installed
if [ -f "$MODEL_FILE" ]; then
    echo "✅ モデルは既にインストールされています: $MODEL_FILE"
    echo ""
    echo "再インストールする場合は、まず以下を削除してください:"
    echo "  rm -rf $MODEL_DIR"
    exit 0
fi

# Check install directory
if [ ! -d "$INSTALL_DIR" ]; then
    echo "❌ LM Lightがインストールされていません"
    echo "   先にLM Lightをインストールしてください"
    exit 1
fi

# Create model directory
echo "📁 モデルディレクトリを作成: $MODEL_DIR"
mkdir -p "$MODEL_DIR"

# Download model
echo "📥 Whisper tinyモデルをダウンロード中..."
echo "   URL: $MODEL_URL"
echo "   サイズ: 約74MB"
echo ""

if command -v curl &> /dev/null; then
    curl -L --progress-bar -o "$MODEL_FILE" "$MODEL_URL"
elif command -v wget &> /dev/null; then
    wget --show-progress -O "$MODEL_FILE" "$MODEL_URL"
else
    echo "❌ curlまたはwgetが必要です"
    exit 1
fi

# Verify download
if [ -f "$MODEL_FILE" ]; then
    SIZE=$(ls -lh "$MODEL_FILE" | awk '{print $5}')
    echo ""
    echo "✅ インストール完了!"
    echo "   ファイル: $MODEL_FILE"
    echo "   サイズ: $SIZE"
    echo ""
    echo "LM Lightを再起動すると、サイドバーに「文字起こし」が表示されます"
else
    echo "❌ ダウンロードに失敗しました"
    exit 1
fi