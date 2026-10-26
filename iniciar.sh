#!/usr/bin/env bash
# Inicia o Transcreve Zap em segundo plano: pelo serviço systemd do usuário
# ou, sem systemd (container, WSL), direto com nohup.
RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if systemctl --user cat transcreve-zap.service >/dev/null 2>&1; then
  systemctl --user start transcreve-zap.service
else
  NODE="$RAIZ/ferramentas/node/bin/node"; [[ -x "$NODE" ]] || NODE=node
  cd "$RAIZ" && nohup "$NODE" "$RAIZ/src/index.js" >/dev/null 2>&1 &
fi
echo "Rodando. Painel: http://localhost:3210"
