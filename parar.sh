#!/usr/bin/env bash
# Para o Transcreve Zap (e o modelo de resumo, se estiver rodando).
RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
systemctl --user stop transcreve-zap.service 2>/dev/null
# Se foi aberto à mão (node src/index.js), mata pelo caminho.
pkill -f "node $RAIZ/src/index.js" && echo "Parado: node"
pkill -f "llama-server .*--port 3211" && echo "Parado: llama-server"
exit 0
