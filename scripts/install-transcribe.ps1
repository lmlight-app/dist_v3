# LM Light - Transcription Model Installer
# Downloads Whisper model for speech-to-text functionality

param(
    [Parameter(Position=0)]
    [ValidateSet("tiny", "base", "small", "medium", "large")]
    [string]$ModelName = "tiny"
)

$ErrorActionPreference = "Stop"

$InstallDir = "$env:LOCALAPPDATA\lmlight"
$ModelDir = "$InstallDir\models\whisper"
$EnvFile = "$InstallDir\.env"

# Model definitions
$ModelSizes = @{
    "tiny"   = "74MB"
    "base"   = "142MB"
    "small"  = "466MB"
    "medium" = "1.5GB"
    "large"  = "2.9GB"
}

function Show-Usage {
    Write-Host "使用方法: install-transcribe.ps1 [モデル名]" -ForegroundColor White
    Write-Host ""
    Write-Host "モデル一覧:"
    Write-Host "  tiny   - 74MB  (デフォルト、軽量・高速)"
    Write-Host "  base   - 142MB (バランス型)"
    Write-Host "  small  - 466MB (高精度)"
    Write-Host "  medium - 1.5GB (高精度・GPU推奨)"
    Write-Host "  large  - 2.9GB (最高精度・GPU必須)"
    Write-Host ""
    Write-Host "例:"
    Write-Host "  .\install-transcribe.ps1           # tinyモデルをインストール"
    Write-Host "  .\install-transcribe.ps1 small     # smallモデルをインストール"
    Write-Host ""
    Write-Host "リモート実行:"
    Write-Host '  irm https://raw.githubusercontent.com/lmlight-app/dist_v3/main/scripts/install-transcribe.ps1 | iex'
    Write-Host '  & ([scriptblock]::Create((irm https://raw.githubusercontent.com/lmlight-app/dist_v3/main/scripts/install-transcribe.ps1))) -ModelName small'
}

# large uses v3 version
if ($ModelName -eq "large") {
    $ModelUrl = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3.bin"
    $ModelFile = "$ModelDir\ggml-large-v3.bin"
} else {
    $ModelUrl = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-$ModelName.bin"
    $ModelFile = "$ModelDir\ggml-$ModelName.bin"
}
$ModelSize = $ModelSizes[$ModelName]

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  LM Light 文字起こしモデル インストーラー" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "選択モデル: $ModelName ($ModelSize)" -ForegroundColor White
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

# Remove old model files (different model)
if (Test-Path $ModelDir) {
    Write-Host "📁 既存のモデルを削除..."
    Remove-Item -Recurse -Force $ModelDir
}

# Create model directory
Write-Host "📁 モデルディレクトリを作成: $ModelDir"
New-Item -ItemType Directory -Force -Path $ModelDir | Out-Null

# Download model
Write-Host "📥 Whisper ${ModelName}モデルをダウンロード中..." -ForegroundColor Yellow
Write-Host "   URL: $ModelUrl"
Write-Host "   サイズ: 約$ModelSize"
Write-Host ""

try {
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $ModelUrl -OutFile $ModelFile -UseBasicParsing
    $ProgressPreference = 'Continue'
} catch {
    Write-Host "❌ ダウンロードに失敗しました: $_" -ForegroundColor Red
    exit 1
}

# Update .env WHISPER_MODEL
if (Test-Path $EnvFile) {
    $envContent = Get-Content $EnvFile -Raw
    if ($envContent -match "^WHISPER_MODEL=") {
        $envContent = $envContent -replace "WHISPER_MODEL=.*", "WHISPER_MODEL=$ModelName"
    } else {
        $envContent += "`nWHISPER_MODEL=$ModelName"
    }
    Set-Content -Path $EnvFile -Value $envContent.TrimEnd() -NoNewline
    Add-Content -Path $EnvFile -Value ""
    Write-Host "📝 .envを更新: WHISPER_MODEL=$ModelName"
}

# Verify download
if (Test-Path $ModelFile) {
    $Size = (Get-Item $ModelFile).Length / 1MB
    $SizeStr = "{0:N1} MB" -f $Size
    Write-Host ""
    Write-Host "✅ インストール完了!" -ForegroundColor Green
    Write-Host "   モデル: $ModelName"
    Write-Host "   ファイル: $ModelFile"
    Write-Host "   サイズ: $SizeStr"
    Write-Host ""
    Write-Host "LM Lightを再起動すると、サイドバーに「文字起こし」が表示されます" -ForegroundColor Cyan
} else {
    Write-Host "❌ ダウンロードに失敗しました" -ForegroundColor Red
    exit 1
}