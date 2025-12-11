# LM Light Windows Installer

このディレクトリには、LM Light の Windows インストーラーを作成するための Inno Setup スクリプトが含まれています。

## 必要なもの

- [Inno Setup 6.0以上](https://jrsoftware.org/isinfo.php)
- リリース済みのバイナリ（lmlight-api-windows-amd64.exe、lmlight-web.tar.gz）

## ビルド方法

### 自動（GitHub Actions）

タグをプッシュすると自動的にインストーラーがビルドされ、リリースに追加されます：

```bash
git tag v1.0.0
git push origin v1.0.0
```

### 手動

1. 必要なファイルを配置：

```
dist_v2/
├── releases/
│   ├── lmlight-api-windows-amd64.exe
│   └── frontend/  (lmlight-web.tar.gz を展開)
├── installer/
│   └── lmlight.iss
├── scripts/
│   ├── start.ps1
│   ├── stop.ps1
│   ├── toggle.ps1
│   └── check-dependencies.ps1
├── templates/
│   └── .env.example
├── assets/
│   └── lmlight.ico
└── LICENSE
```

2. Inno Setup でビルド：

```powershell
& "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" installer/lmlight.iss
```

3. `dist/` ディレクトリに `LMLight-Setup-*.exe` が生成されます

## インストーラーの機能

- バックエンド（lmlight-api.exe）のインストール
- フロントエンド（Next.js standalone）のインストール
- スタートメニューへのショートカット作成
- デスクトップアイコンの作成（オプション）
- 依存関係のチェックと案内
- .env ファイルの自動生成

## 依存関係

インストーラーは以下のソフトウェアをチェックし、不足している場合はインストール方法を案内します：

- Node.js
- PostgreSQL
- Ollama
- Tesseract OCR

## アイコンファイル

`assets/lmlight.ico` が必要です。以下の方法で作成できます：

### macOS で .icns から .ico を作成

```bash
# ImageMagick を使用
brew install imagemagick
convert assets/LMLight.icns -resize 256x256 assets/lmlight.ico

# または sips を使用
sips -s format ico assets/LMLight.icns --out assets/lmlight.ico
```

### オンラインツール

- https://convertio.co/ja/icns-ico/
- https://cloudconvert.com/icns-to-ico

## トラブルシューティング

### ビルドエラー

- ファイルパスが正しいか確認
- releases/ ディレクトリにバイナリが存在するか確認
- Inno Setup が正しくインストールされているか確認

### 依存関係エラー

インストール後、`check-dependencies.ps1` を実行して不足している依存関係を確認してください。