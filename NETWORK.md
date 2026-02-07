# LM Light ネットワーク接続ガイド

Ubuntu mini PC やワークステーションを LM Light サーバーとして使用し、他のデバイスから接続する方法を説明します。

## 🚀 クイックスタート

**最も簡単な方法:**

1. サーバー側で LM Light を起動
   ```bash
   lmlight start
   ```

2. 表示された IP アドレスをメモ
   ```
   🌐 LAN access: http://192.168.1.100:3000
   ```

3. クライアント PC・スマホで上記 URL にアクセス

**ポート番号なしでアクセスしたい場合:**

→ [ポート番号なしでアクセス](#3-ポート番号なしでアクセス推奨) を参照

---

## 📋 目次

1. [直接 LAN 接続](#1-直接-lan-接続)
2. [社内 LAN 経由接続](#2-社内-lan-経由接続)
3. [名前でアクセスする方法](#3-名前でアクセスする方法)

---

## 1. 直接 LAN 接続

### 概要

Ubuntu mini PC をサーバーとして、有線 LAN や Wi-Fi で他の PC・スマホ・タブレットから直接アクセスします。

### 構成図

```
┌─────────────────┐      有線LAN/Wi-Fi      ┌──────────────────┐
│  クライアント PC  │◄────────────────────────►│  LM Light サーバー │
│  (192.168.1.50) │                         │  (192.168.1.100)  │
└─────────────────┘                         └──────────────────┘
                                             (Ubuntu mini PC)
```

### 設定手順

#### **サーバー側 (Ubuntu mini PC)**

1. **LM Light をインストール**

   ```bash
   curl -fsSL https://raw.githubusercontent.com/lmlight-app/dist_v3/main/scripts/install-linux.sh | bash
   ```

2. **ネットワーク設定を確認**

   `.env` ファイルを確認（デフォルトで LAN アクセス可能）:

   ```bash
   # ~/.local/lmlight/.env

   API_HOST=0.0.0.0
   WEB_HOST=0.0.0.0
   ```

3. **ファイアウォールを開放**

   ```bash
   sudo ufw allow 3000/tcp comment "LM Light Web"
   sudo ufw allow 8000/tcp comment "LM Light API"
   sudo ufw reload
   ```

4. **LM Light を起動**

   ```bash
   lmlight start
   ```

   起動時に LAN IP アドレスが表示されます：

   ```
   ✅ Started - API: http://localhost:8000 | Web: http://localhost:3000

   🌐 LAN access (from other PCs):
      API: http://192.168.1.100:8000
      Web: http://192.168.1.100:3000

   Press Ctrl+C to stop
   ```

5. **IP アドレスを確認**

   起動時に表示されない場合、手動で確認：

   ```bash
   ip addr show | grep "inet " | grep -v 127.0.0.1
   ```

#### **クライアント側 (PC・スマホ・タブレット)**

1. **同じネットワークに接続**

   サーバーと同じ LAN（有線 LAN または Wi-Fi）に接続します。

2. **ブラウザでアクセス**

   サーバーの IP アドレスを使用：

   ```
   http://192.168.1.100:3000
   ```

3. **ログイン**

   デフォルトログイン: `admin@local` / `admin123`

### トラブルシューティング

| 問題 | 原因 | 解決方法 |
|-----|------|---------|
| 接続できない | ファイアウォール | ポート 3000, 8000 を開放 |
| タイムアウト | 別のネットワーク | 同じ LAN に接続しているか確認 |
| IP が変わる | DHCP | サーバーに固定 IP を割り当て |

---

## 2. 社内 LAN 経由接続

### 概要

社内ネットワーク（企業 LAN）内で、サーバー室や部署内の PC に LM Light を設置し、社内の他の PC からアクセスします。

### 構成図

```
┌──────────────┐     社内LAN      ┌──────────────┐
│ 営業部の PC  │◄─────────────────►│              │
│ (10.0.1.50)  │                  │              │
└──────────────┘                  │              │
                                  │  社内スイッチ  │
┌──────────────┐                  │              │
│ 開発部の PC  │◄─────────────────►│              │
│ (10.0.2.30)  │                  │              │
└──────────────┘                  └──────┬───────┘
                                        │
                                 ┌──────┴──────────┐
                                 │ LM Light サーバー │
                                 │  (10.0.0.100)   │
                                 └─────────────────┘
                                 (Ubuntu mini PC)
```

### 設定手順

#### **1. 固定 IP アドレスを設定**

DHCP で IP が変わると接続できなくなるため、固定 IP を設定します。

**Ubuntu (netplan):**

```bash
sudo nano /etc/netplan/01-netcfg.yaml
```

```yaml
network:
  version: 2
  ethernets:
    enp0s3:  # インターフェース名（ip a で確認）
      dhcp4: no
      addresses:
        - 10.0.0.100/24
      routes:
        - to: default
          via: 10.0.0.1
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
```

適用：

```bash
sudo netplan apply
```

#### **2. LM Light をインストール・起動**

[直接 LAN 接続](#1-直接-lan-接続) の手順と同じ

#### **3. ポート番号なしでアクセス（推奨）**

**`:3000` を付けずに `http://lmlight` だけでアクセスしたい場合**、Nginx リバースプロキシを使用します。

##### **Nginx のセットアップ**

**1. インストール:**

```bash
sudo apt install nginx
```

**2. 設定ファイルを作成:**

```bash
sudo nano /etc/nginx/sites-available/lmlight
```

```nginx
server {
    listen 80;
    server_name lmlight lmlight.local lmlight.company.local 10.0.0.100;

    # Web UI (ポート番号なしでアクセス)
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $server_name;
        proxy_cache_bypass $http_upgrade;

        # Next.js App Router ストリーミング対応
        proxy_buffering off;
        proxy_set_header X-Accel-Buffering no;
    }

    # API (ポート番号なしでアクセス)
    location /api {
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

**3. 有効化:**

```bash
sudo ln -s /etc/nginx/sites-available/lmlight /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx

# ポート80を開放
sudo ufw allow 80/tcp
```

**4. アクセス:**

```
http://lmlight            # ポート番号なし！
http://10.0.0.100         # IP でもポート番号なし
```

##### **HTTPS でアクセス（`https://lmlight`）**

社内で HTTPS を使う場合、自己署名証明書を作成します。

**1. SSL 証明書を作成:**

```bash
sudo mkdir -p /etc/nginx/ssl
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/nginx/ssl/lmlight.key \
  -out /etc/nginx/ssl/lmlight.crt \
  -subj "/CN=lmlight"
```

**2. Nginx 設定を更新:**

```bash
sudo nano /etc/nginx/sites-available/lmlight
```

```nginx
# HTTP を HTTPS にリダイレクト
server {
    listen 80;
    server_name lmlight lmlight.local lmlight.company.local;
    return 301 https://$server_name$request_uri;
}

# HTTPS サーバー
server {
    listen 443 ssl;
    server_name lmlight lmlight.local lmlight.company.local;

    ssl_certificate /etc/nginx/ssl/lmlight.crt;
    ssl_certificate_key /etc/nginx/ssl/lmlight.key;

    # SSL 設定
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers HIGH:!aNULL:!MD5;

    # Web UI
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $server_name;
        proxy_cache_bypass $http_upgrade;

        # Next.js App Router ストリーミング対応
        proxy_buffering off;
        proxy_set_header X-Accel-Buffering no;
    }

    # API
    location /api {
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

**3. 適用:**

```bash
sudo nginx -t
sudo systemctl reload nginx
sudo ufw allow 443/tcp
```

**4. アクセス:**

```
https://lmlight           # HTTPS！
```

**注意:** 自己署名証明書は、ブラウザで「安全ではない」という警告が出ます。社内利用であれば、証明書を信頼するよう設定してください。

---

## 3. 名前でアクセスする方法

IP アドレス（例: `http://192.168.1.100:3000`）の代わりに、名前（例: `http://lmlight:3000`）でアクセスできるようにします。

### 方法 1: クライアント側の hosts ファイル（簡単）

各クライアント PC の hosts ファイルを編集します。

#### **Linux / macOS の場合**

```bash
sudo nano /etc/hosts
```

以下を追加：

```
192.168.1.100  lmlight
```

保存して閉じます。これで `http://lmlight:3000` でアクセス可能になります。

#### **Windows の場合**

1. メモ帳を**管理者として実行**
2. `C:\Windows\System32\drivers\etc\hosts` を開く
3. 以下を追加：

   ```
   192.168.1.100  lmlight
   ```

4. 保存

これで `http://lmlight:3000` でアクセス可能になります。

#### **Android / iOS の場合**

スマホやタブレットの hosts ファイルは編集が困難です。方法 2（社内 DNS）を使用してください。

### 方法 2: 社内 DNS サーバー（推奨）

社内に DNS サーバーがある場合、以下のレコードを追加：

```
lmlight.company.local → 192.168.1.100
```

これにより、社内のすべての PC・スマホ・タブレットから `http://lmlight.company.local:3000` でアクセス可能になります。

#### **一般的な DNS サーバーでの設定例**

**Windows Server (Active Directory):**

1. DNS マネージャーを開く
2. 「前方参照ゾーン」→ 「company.local」を右クリック → 「新しいホスト (A)」
3. 名前: `lmlight`、IP: `192.168.1.100`

**dnsmasq (Linux):**

```bash
sudo nano /etc/dnsmasq.conf
```

以下を追加：

```
address=/lmlight.local/192.168.1.100
```

再起動：

```bash
sudo systemctl restart dnsmasq
```

### 方法 3: mDNS / Avahi（ゼロコンフィグ）

Ubuntu サーバーで Avahi をインストールすると、`http://ubuntu-minipc.local:3000` のような名前でアクセス可能になります。

**サーバー側:**

```bash
# Avahi と NSS mDNS モジュールをインストール
sudo apt update
sudo apt install -y avahi-daemon avahi-utils libnss-mdns

# Avahi を有効化・起動
sudo systemctl enable avahi-daemon
sudo systemctl start avahi-daemon

# ファイアウォールで mDNS ポートを開放
sudo ufw allow 5353/udp comment "mDNS"
```

**ホスト名解決の設定:**

```bash
# /etc/nsswitch.conf を編集
sudo nano /etc/nsswitch.conf
```

`hosts:` の行を以下のように変更（`mdns_minimal [NOTFOUND=return]` を `resolve` と `dns` の前に追加）:

```
hosts:          files mdns_minimal [NOTFOUND=return] resolve [!UNAVAIL=return] dns
```

これで、同じ LAN 内のクライアントから `http://<ホスト名>.local:3000` でアクセス可能になります。

**ホスト名を変更する場合:**

```bash
sudo hostnamectl set-hostname lmlight
sudo systemctl restart avahi-daemon
```

これで `http://lmlight.local:3000` でアクセス可能になります。

**動作確認:**

```bash
# ホスト名を確認
hostname

# mDNS 解決をテスト
avahi-resolve -n $(hostname).local
```

**注意:**
- Windows では mDNS のサポートが限定的です。iTunes や Bonjour Print Services がインストールされている場合のみ動作します。
- mDNS は UDP ポート 5353 とマルチキャストアドレス 224.0.0.251 を使用します。

---

## セキュリティ

### localhost のみアクセス可能にする

外部アクセスが不要な場合、`.env` で localhost に限定：

```bash
API_HOST=127.0.0.1
WEB_HOST=127.0.0.1
```

### ファイアウォールで IP 制限

特定の IP のみ許可：

```bash
# デフォルトで拒否
sudo ufw default deny incoming

# 特定の IP のみ許可
sudo ufw allow from 192.168.1.50 to any port 3000 proto tcp
sudo ufw allow from 192.168.1.50 to any port 8000 proto tcp

sudo ufw enable
```

### パスワード変更

初回ログイン後、すぐにパスワードを変更：

```
デフォルト: admin@local / admin123
変更後: 強力なパスワードに変更
```

---

## まとめ

### 推奨構成

| 用途 | 推奨方法 | アクセス方法 | ポート番号 |
|-----|---------|------------|----------|
| **個人利用（簡易）** | 直接 LAN 接続 | `http://192.168.1.100:3000` | あり |
| **個人利用（快適）** | Nginx + mDNS | `http://lmlight.local` | **なし** |
| **社内利用（簡易）** | hosts ファイル | `http://lmlight:3000` | あり |
| **社内利用（推奨）** | Nginx + 社内 DNS | `http://lmlight` | **なし** |
| **セキュア** | Nginx + HTTPS | `https://lmlight` | **なし** |

### 次のステップ

1. ✅ [直接 LAN 接続](#1-直接-lan-接続) で動作確認
2. ✅ [名前でアクセス](#3-名前でアクセスする方法) を設定（hosts または mDNS）
3. ✅ 必要に応じて [社内 LAN 展開](#2-社内-lan-経由接続) を検討

### サポート

問題が発生した場合：
- **トラブルシューティング**: [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- **Issue 報告**: https://github.com/lmlight-app/dist_v3/issues