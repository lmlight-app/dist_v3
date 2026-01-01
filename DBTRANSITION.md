# DBの移行方法

## 1. エクスポート（移行元）

```bash
pg_dump -U lmlight -d lmlight -F c -f lmlight_backup.dump
```

## 2. ファイルを移行先へコピー

USB、ネットワーク共有、クラウドストレージ等で `lmlight_backup.dump` を移行先へ

## 3. インポート（移行先）

```bash
# DB作成（初回のみ）
psql -U postgres -c "CREATE USER lmlight WITH PASSWORD 'lmlight';"
psql -U postgres -c "CREATE DATABASE lmlight OWNER lmlight;"
psql -U postgres -d lmlight -c "CREATE EXTENSION IF NOT EXISTS vector;"

# リストア
pg_restore -U lmlight -d lmlight lmlight_backup.dump
```

## 既存データがある場合

```bash
# 既存DBを削除してからリストア
psql -U postgres -c "DROP DATABASE lmlight;"
psql -U postgres -c "CREATE DATABASE lmlight OWNER lmlight;"
psql -U postgres -d lmlight -c "CREATE EXTENSION IF NOT EXISTS vector;"
pg_restore -U lmlight -d lmlight lmlight_backup.dump
```
