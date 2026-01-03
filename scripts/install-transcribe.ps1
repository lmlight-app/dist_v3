# LM Light - Transcription Model Installer
# Downloads Whisper tiny model for speech-to-text functionality

$ErrorActionPreference = "Stop"

$ModelUrl = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.bin"
$InstallDir = "$env:LOCALAPPDATA\lmlight"
$ModelDir = "$InstallDir\models\whisper"
$ModelFile = "$ModelDir\ggml-tiny.bin"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  LM Light 文字起こしモデル インストーラー" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Check if already installed
if (Test-Path $ModelFile) {
    Write-Host "✅ モデルは既にインストールされています: $ModelFile" -ForegroundColor Green
    Write-Host ""
    Write-Host "再インストールする場合は、まず以下を削除してください:"
    Write-Host "  Remove-Item -Recurse -Force `"$ModelDir`""
    exit 0
}

# Check install directory
if (-not (Test-Path $InstallDir)) {
    Write-Host "❌ LM Lightがインストールされていません" -ForegroundColor Red
    Write-Host "   先にLM Lightをインストールしてください"
    exit 1
}

# Create model directory
Write-Host "📁 モデルディレクトリを作成: $ModelDir"
New-Item -ItemType Directory -Force -Path $ModelDir | Out-Null

# Download model
Write-Host "📥 Whisper tinyモデルをダウンロード中..." -ForegroundColor Yellow
Write-Host "   URL: $ModelUrl"
Write-Host "   サイズ: 約74MB"
Write-Host ""

try {
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $ModelUrl -OutFile $ModelFile -UseBasicParsing
    $ProgressPreference = 'Continue'
} catch {
    Write-Host "❌ ダウンロードに失敗しました: $_" -ForegroundColor Red
    exit 1
}

# Verify download
if (Test-Path $ModelFile) {
    $Size = (Get-Item $ModelFile).Length / 1MB
    $SizeStr = "{0:N1} MB" -f $Size
    Write-Host ""
    Write-Host "✅ インストール完了!" -ForegroundColor Green
    Write-Host "   ファイル: $ModelFile"
    Write-Host "   サイズ: $SizeStr"
    Write-Host ""
    Write-Host "LM Lightを再起動すると、サイドバーに「文字起こし」が表示されます" -ForegroundColor Cyan
} else {
    Write-Host "❌ ダウンロードに失敗しました" -ForegroundColor Red
    exit 1
}