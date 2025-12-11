# LM Light Database Setup for Windows
# Usage: irm https://raw.githubusercontent.com/lmlight-app/dist_v2/main/scripts/db_setup.ps1 | iex

$ErrorActionPreference = "Stop"

# Database settings
$DB_USER = if ($env:DB_USER) { $env:DB_USER } else { "lmlight" }
$DB_PASSWORD = if ($env:DB_PASSWORD) { $env:DB_PASSWORD } else { "lmlight" }
$DB_NAME = if ($env:DB_NAME) { $env:DB_NAME } else { "lmlight" }

Write-Host "Setting up LM Light database..." -ForegroundColor Blue

# Check psql
if (-not (Get-Command psql -ErrorAction SilentlyContinue)) {
    Write-Host "psql not found. Please install PostgreSQL first." -ForegroundColor Red
    exit 1
}

# PostgreSQL service startup
$pgService = Get-Service -Name "postgresql*" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($pgService -and $pgService.Status -ne "Running") {
    Write-Host "Starting PostgreSQL service..."
    Start-Service $pgService.Name
    Start-Sleep -Seconds 3
}

# Create user and database
Write-Host "Creating user and database..."
$env:PGPASSWORD = "postgres"
psql -U postgres -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';" 2>$null
psql -U postgres -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;" 2>$null
psql -U postgres -c "ALTER USER $DB_USER CREATEDB;" 2>$null
psql -U postgres -d $DB_NAME -c "CREATE EXTENSION IF NOT EXISTS vector;" 2>$null

# Run migrations
Write-Host "Creating tables..."

$SQL_MIGRATION = @"
-- Enums
DO `$`$ BEGIN CREATE TYPE "UserRole" AS ENUM ('ADMIN', 'USER'); EXCEPTION WHEN duplicate_object THEN null; END `$`$;
DO `$`$ BEGIN CREATE TYPE "UserStatus" AS ENUM ('ACTIVE', 'INACTIVE'); EXCEPTION WHEN duplicate_object THEN null; END `$`$;
DO `$`$ BEGIN CREATE TYPE "MessageRole" AS ENUM ('USER', 'ASSISTANT', 'SYSTEM'); EXCEPTION WHEN duplicate_object THEN null; END `$`$;
DO `$`$ BEGIN CREATE TYPE "ShareType" AS ENUM ('PRIVATE', 'TAG'); EXCEPTION WHEN duplicate_object THEN null; END `$`$;

-- Tables
CREATE TABLE IF NOT EXISTS "User" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "name" TEXT,
    "email" TEXT NOT NULL UNIQUE,
    "emailVerified" TIMESTAMP(3),
    "image" TEXT,
    "hashedPassword" TEXT,
    "role" "UserRole" NOT NULL DEFAULT 'USER',
    "status" "UserStatus" NOT NULL DEFAULT 'ACTIVE',
    "lastLoginAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS "UserSettings" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "userId" TEXT NOT NULL UNIQUE,
    "historyLimit" INTEGER NOT NULL DEFAULT 2,
    "temperature" DOUBLE PRECISION NOT NULL DEFAULT 0.7,
    "maxTokens" INTEGER NOT NULL DEFAULT 2048,
    "numCtx" INTEGER NOT NULL DEFAULT 8192,
    "topP" DOUBLE PRECISION NOT NULL DEFAULT 0.9,
    "topK" INTEGER NOT NULL DEFAULT 40,
    "repeatPenalty" DOUBLE PRECISION NOT NULL DEFAULT 1.1,
    "reasoningMode" TEXT NOT NULL DEFAULT 'normal',
    "ragTopK" INTEGER NOT NULL DEFAULT 5,
    "ragMinSimilarity" DOUBLE PRECISION NOT NULL DEFAULT 0.45,
    "embeddingModel" TEXT NOT NULL DEFAULT 'nomic-embed-text:latest',
    "chunkSize" INTEGER NOT NULL DEFAULT 600,
    "chunkOverlap" INTEGER NOT NULL DEFAULT 100,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS "Tag" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "name" TEXT NOT NULL UNIQUE,
    "description" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS "UserTag" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "userId" TEXT NOT NULL,
    "tagId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE ("userId", "tagId")
);

CREATE TABLE IF NOT EXISTS "Bot" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "userId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "shareType" "ShareType" NOT NULL DEFAULT 'PRIVATE',
    "shareTagId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS "Chat" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "userId" TEXT NOT NULL,
    "model" TEXT NOT NULL,
    "sessionId" TEXT NOT NULL,
    "botId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS "Message" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "chatId" TEXT NOT NULL,
    "role" "MessageRole" NOT NULL,
    "content" TEXT NOT NULL,
    "metadata" JSONB,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- pgvector schema
CREATE SCHEMA IF NOT EXISTS pgvector;
CREATE TABLE IF NOT EXISTS pgvector.embeddings (
    id SERIAL PRIMARY KEY,
    bot_id VARCHAR(255) NOT NULL,
    user_id VARCHAR(255) NOT NULL,
    document_id VARCHAR(255) NOT NULL,
    chunk_id INTEGER NOT NULL,
    content TEXT NOT NULL,
    embedding vector(768),
    metadata JSONB,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS "UserTag_userId_idx" ON "UserTag"("userId");
CREATE INDEX IF NOT EXISTS "UserTag_tagId_idx" ON "UserTag"("tagId");
CREATE INDEX IF NOT EXISTS "Bot_userId_idx" ON "Bot"("userId");
CREATE INDEX IF NOT EXISTS "Bot_shareTagId_idx" ON "Bot"("shareTagId");
CREATE INDEX IF NOT EXISTS "Chat_sessionId_idx" ON "Chat"("sessionId");
CREATE INDEX IF NOT EXISTS "Chat_userId_model_idx" ON "Chat"("userId", "model");
CREATE INDEX IF NOT EXISTS "Chat_userId_idx" ON "Chat"("userId");
CREATE INDEX IF NOT EXISTS "Chat_botId_idx" ON "Chat"("botId");
CREATE INDEX IF NOT EXISTS "Message_chatId_createdAt_idx" ON "Message"("chatId", "createdAt");
CREATE INDEX IF NOT EXISTS idx_bot_user ON pgvector.embeddings (bot_id, user_id);
CREATE INDEX IF NOT EXISTS idx_document ON pgvector.embeddings (document_id);

-- Admin user (admin@local / admin123)
INSERT INTO "User" ("id", "email", "name", "hashedPassword", "role", "status", "updatedAt")
VALUES (
    'admin-user-id',
    'admin@local',
    'Admin',
    '`$2a`$12`$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/X4.V4ferGqaJe.rHe',
    'ADMIN',
    'ACTIVE',
    CURRENT_TIMESTAMP
) ON CONFLICT ("id") DO NOTHING;

-- Grant privileges
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $DB_USER;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO $DB_USER;
GRANT ALL PRIVILEGES ON SCHEMA pgvector TO $DB_USER;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA pgvector TO $DB_USER;
"@

$SQL_MIGRATION | psql -q -U postgres -d $DB_NAME 2>$null

Write-Host "Database setup complete" -ForegroundColor Green
Write-Host "  User: $DB_USER"
Write-Host "  Database: $DB_NAME"
Write-Host "  Admin login: admin@local / admin123"