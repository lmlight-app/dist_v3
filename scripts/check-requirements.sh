#!/bin/bash
# AI Server Requirements Check
command -v node &>/dev/null && echo "OK: Node.js" || echo "NG: Node.js"
command -v psql &>/dev/null && echo "OK: PostgreSQL" || echo "NG: PostgreSQL"
command -v ollama &>/dev/null && echo "OK: Ollama" || echo "NG: Ollama"
