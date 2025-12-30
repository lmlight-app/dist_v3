# LM Light CLI コマンド (Perpetual License)

`lmlight start` / `lmlight stop` でサービスを操作する方法

## セットアップ

### macOS

```bash
# シンボリックリンクを作成（インストール時に自動実行）
sudo ln -sf ~/.local/lmlight/lmlight /usr/local/bin/lmlight
```

または `.zshrc` に追加:

```bash
echo 'alias lmlight="~/.local/lmlight/lmlight"' >> ~/.zshrc
source ~/.zshrc
```

### Linux

```bash
# シンボリックリンクを作成（インストール時に自動実行）
sudo ln -sf ~/.local/lmlight/lmlight /usr/local/bin/lmlight
```

または `.bashrc` / `.zshrc` に追加:

```bash
echo 'alias lmlight="~/.local/lmlight/lmlight"' >> ~/.bashrc
source ~/.bashrc
```

### Windows

インストール時に `%LOCALAPPDATA%\lmlight\lmlight.bat` が作成され、PATH に追加されます。

手動で設定する場合:

```powershell
# lmlight.bat を作成
@"
@echo off
if "%1"=="start" powershell -ExecutionPolicy Bypass -File "%LOCALAPPDATA%\lmlight\start.ps1"
if "%1"=="stop" powershell -ExecutionPolicy Bypass -File "%LOCALAPPDATA%\lmlight\stop.ps1"
if "%1"=="" echo Usage: lmlight {start^|stop}
"@ | Out-File -Encoding ASCII "$env:LOCALAPPDATA\lmlight\lmlight.bat"

# PATH に追加（新しいターミナルで有効）
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