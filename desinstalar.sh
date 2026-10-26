#!/usr/bin/env bash
# Remove o Transcreve Zap: para o programa, tira da inicialização e apaga a sessão do WhatsApp.
# A pasta do programa fica; apague-a à mão depois, se quiser.
RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$RAIZ/parar.sh"
systemctl --user disable transcreve-zap.service 2>/dev/null
rm -f "$HOME/.config/systemd/user/transcreve-zap.service"
systemctl --user daemon-reload
rm -rf "$RAIZ/dados"
echo 'Desinstalado. No celular, remova "Transcreve Zap" em Dispositivos conectados.'
echo "Para apagar tudo, exclua a pasta $RAIZ"
