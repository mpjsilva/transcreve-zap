#!/usr/bin/env bash
# Inicia o Transcreve Zap em segundo plano (serviço systemd do usuário).
systemctl --user start transcreve-zap.service && echo "Rodando. Painel: http://localhost:3210"
