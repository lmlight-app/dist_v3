# LM Light CLI コマンド (Perpetual License)

`lmlight start` / `lmlight stop` でサービスを操作する方法

## セットアップ

### macOS / Linux

```bash
# シンボリックリンクを作成
sudo ln -sf ~/.local/lmlight/lmlight /usr/local/bin/lmlight
```

または `.bashrc` / `.zshrc` に追加:

```bash
alias lmlight='~/.local/lmlight/lmlight'
```

### Windows

PowerShell プロファイルに追加:

```powershell
# プロファイルを開く
notepad $PROFILE

# 以下を追加
function lmlight {
    param([string]$cmd)
    switch ($cmd) {
        "start" { & "$env:LOCALAPPDATA\lmlight\start.ps1" }
        "stop"  { & "$env:LOCALAPPDATA\lmlight\stop.ps1" }
        default { Write-Host "Usage: lmlight {start|stop}" }
    }
}
```

または PATH に追加:

```powershell
# バッチファイルを作成
@"
@echo off
if "%1"=="start" powershell -ExecutionPolicy Bypass -File "%LOCALAPPDATA%\lmlight\start.ps1"
if "%1"=="stop" powershell -ExecutionPolicy Bypass -File "%LOCALAPPDATA%\lmlight\stop.ps1"
if "%1"=="" echo Usage: lmlight {start^|stop}
"@ | Out-File -Encoding ASCII "$env:LOCALAPPDATA\lmlight\lmlight.bat"

# PATH に追加
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";$env:LOCALAPPDATA\lmlight", "User")
```

## 使い方

```bash
# 起動
lmlight start

# 停止
lmlight stop
```

## 直接実行 (セットアップなし)

### macOS / Linux

```bash
# 起動
~/.local/lmlight/start.sh

# 停止
~/.local/lmlight/stop.sh
```

### Windows

```powershell
# 起動
powershell -ExecutionPolicy Bypass -File "$env:LOCALAPPDATA\lmlight\start.ps1"

# 停止
powershell -ExecutionPolicy Bypass -File "$env:LOCALAPPDATA\lmlight\stop.ps1"
```

## lmlight スクリプト (参考)

macOS/Linux 用の `/usr/local/bin/lmlight` または `~/.local/lmlight/lmlight`:

```bash
#!/bin/bash
LMLIGHT_HOME="${LMLIGHT_HOME:-$HOME/.local/lmlight}"

case "$1" in
    start)
        "$LMLIGHT_HOME/start.sh"
        ;;
    stop)
        "$LMLIGHT_HOME/stop.sh"
        ;;
    *)
        echo "Usage: lmlight {start|stop}"
        exit 1
        ;;
esac
```

インストール:

```bash
# スクリプトを作成
cat > ~/.local/lmlight/lmlight << 'EOF'
#!/bin/bash
LMLIGHT_HOME="${LMLIGHT_HOME:-$HOME/.local/lmlight}"
case "$1" in
    start) "$LMLIGHT_HOME/start.sh" ;;
    stop)  "$LMLIGHT_HOME/stop.sh" ;;
    *)     echo "Usage: lmlight {start|stop}"; exit 1 ;;
esac
EOF

# 実行権限付与
chmod +x ~/.local/lmlight/lmlight

# シンボリックリンク作成
sudo ln -sf ~/.local/lmlight/lmlight /usr/local/bin/lmlight
```