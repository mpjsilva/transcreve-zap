#!/usr/bin/env bash
# Instalador do Transcreve Zap para Fedora e derivadas (RHEL, Rocky, Alma, Nobara, Bazzite...).
# Pacotes do sistema vêm do dnf; o resto fica dentro desta pasta.
# Uso: ./instalar.sh [--resumo-local] [--sem-resumo] [--modelo-melhor] [--nao-iniciar]
set -euo pipefail

RESUMO_LOCAL=0; SEM_RESUMO=0; MODELO_MELHOR=0; NAO_INICIAR=0
for a in "$@"; do
  case "$a" in
    --resumo-local)  RESUMO_LOCAL=1 ;;   # resume no próprio PC (baixa mais ~2 GB, precisa de 8 GB de memória)
    --sem-resumo)    SEM_RESUMO=1 ;;     # só transcreve
    --modelo-melhor) MODELO_MELHOR=1 ;;  # Whisper large-v3-turbo: erra menos, ~3x mais lento
    --nao-iniciar)   NAO_INICIAR=1 ;;    # só instala
    *) echo "Opção desconhecida: $a"; exit 1 ;;
  esac
done

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$RAIZ"
DADOS="$RAIZ/dados"; mkdir -p "$DADOS"
TRAVA="$DADOS/instalando.lock"
PROGRESSO="$DADOS/instalacao.txt"

# Trava: só uma instalação por vez. Rodar duas juntas corrompe as bibliotecas.
if [[ -f "$TRAVA" ]]; then
  outro="$(cat "$TRAVA" 2>/dev/null || true)"
  if [[ -n "$outro" ]] && kill -0 "$outro" 2>/dev/null; then
    echo "Já existe uma instalação em andamento (processo $outro)."
    echo "Acompanhe em $PROGRESSO. Não rode o instalador de novo enquanto ela não terminar."
    exit 2
  fi
fi
echo $$ > "$TRAVA"

progresso() { printf '%s\n(atualizado em %s)\n' "$1" "$(date '+%d/%m/%Y %H:%M:%S')" > "$PROGRESSO"; }
passo() { printf '\n\033[36m==> %s\033[0m\n' "$1"; progresso "EM ANDAMENTO: $1"; }
falhar() { progresso "ERRO: $1"; echo "ERRO: $1" >&2; rm -f "$TRAVA"; exit 1; }
trap 'falhar "comando falhou na linha $LINENO"' ERR
trap 'rm -f "$TRAVA"' EXIT

# Versões fixas, conferidas pelo SHA-256 / commit. Atualizar aqui quando mudar.
WHISPER_REPO='https://github.com/ggml-org/whisper.cpp'
WHISPER_TAG='v1.8.7'; WHISPER_COMMIT='48f628a84833905ee4a0658ee6d4a5c915ce1997'
HF='https://huggingface.co'
SMALL_URL="$HF/ggerganov/whisper.cpp/resolve/main/ggml-small.bin"
SMALL_SHA='1be3a9b2063867b937e64e2ec7483364a79917e157fa98c5d94b5c1fffea987b'
TURBO_URL="$HF/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo-q5_0.bin"
TURBO_SHA='394221709cd5ad1f40c46e6031ca61bce88931e6e088c188294c6d5a55ffa7e2'
QWEN_ARQ='qwen2.5-3b-instruct-q4_k_m.gguf'
QWEN_URL="$HF/Qwen/Qwen2.5-3B-Instruct-GGUF/resolve/main/$QWEN_ARQ"
QWEN_SHA='626b4a6678b86442240e33df819e00132d3ba7dddfe1cdc4fbb18e0a9615c62d'

baixar() { # url sha destino
  local url="$1" sha="$2" dest="$3"
  if [[ -f "$dest" ]]; then
    if [[ "$(sha256sum "$dest" | cut -d' ' -f1)" == "$sha" ]]; then echo "    já baixado"; return; fi
    rm -f "$dest"
  fi
  echo "    baixando $url"
  progresso "EM ANDAMENTO: baixando $(basename "$dest") (o arquivo parcial cresce em $dest.parcial)"
  curl -L --fail --retry 3 --progress-bar -o "$dest.parcial" "$url" || falhar "Falha ao baixar $url"
  local h; h="$(sha256sum "$dest.parcial" | cut -d' ' -f1)"
  if [[ "$h" != "$sha" ]]; then
    rm -f "$dest.parcial"
    falhar "O arquivo baixado de $url não confere (SHA-256 $h). Instalação interrompida por segurança."
  fi
  mv -f "$dest.parcial" "$dest"
}

passo 'Conferindo o computador'
[[ "$(uname -m)" == "x86_64" || "$(uname -m)" == "aarch64" ]] || falhar 'O Transcreve Zap precisa de um sistema de 64 bits.'
command -v dnf >/dev/null || falhar 'Este instalador é para Fedora e derivadas (precisa do dnf).'
ram_gb=$(( $(awk '/MemTotal/{print $2}' /proc/meminfo) / 1024 / 1024 ))
livre_gb=$(( $(df -Pk "$RAIZ" | awk 'NR==2{print $4}') / 1024 / 1024 ))
echo "    memória: $ram_gb GB | espaço livre: $livre_gb GB"
minimo=2; [[ $RESUMO_LOCAL == 1 ]] && minimo=5
(( livre_gb >= minimo )) || falhar "São necessários pelo menos $minimo GB livres no disco."
if [[ $RESUMO_LOCAL == 1 && $ram_gb -lt 7 ]]; then  # 8 GB aparecem como 7 em MemTotal
  echo '    Menos de 8 GB de memória: o resumo vai ser feito no servidor, não no PC.'
  RESUMO_LOCAL=0
fi
[[ $SEM_RESUMO == 1 ]] && RESUMO_LOCAL=0

passo 'Pacotes do sistema (dnf)'
pacotes=(nodejs npm git gcc-c++ cmake make curl)
[[ $RESUMO_LOCAL == 1 ]] && pacotes+=(llama-cpp)
faltando=()
for p in "${pacotes[@]}"; do rpm -q --whatprovides "$p" >/dev/null 2>&1 || faltando+=("$p"); done
if (( ${#faltando[@]} )); then
  echo "    faltando: ${faltando[*]}"
  if [[ -t 0 ]] && command -v sudo >/dev/null; then
    sudo dnf install -y "${faltando[@]}" || falhar "Falha ao instalar: ${faltando[*]}"
  else
    falhar "Instale antes e rode de novo: sudo dnf install -y ${faltando[*]}"
  fi
fi
node_maior=$(node -p 'process.versions.node.split(".")[0]')
(( node_maior >= 20 )) || falhar "Precisa do Node.js 20 ou mais novo (tem $(node -v))."

passo 'Bibliotecas do programa'
"$RAIZ/parar.sh" >/dev/null 2>&1 || true
npm ci --omit=dev --no-audit --no-fund || falhar 'Falha ao instalar as bibliotecas (npm ci).'

passo 'Whisper (transcrição local, compilando)'
WHISPER_BIN="$RAIZ/ferramentas/whisper/whisper-cli"
if [[ -x "$WHISPER_BIN" ]]; then
  echo "    já compilado"
else
  fonte="$RAIZ/ferramentas/whisper-src"
  rm -rf "$fonte"
  git -c advice.detachedHead=false clone -q --depth 1 --branch "$WHISPER_TAG" "$WHISPER_REPO" "$fonte"
  [[ "$(git -C "$fonte" rev-parse HEAD)" == "$WHISPER_COMMIT" ]] || falhar "O código do whisper.cpp não confere com o commit esperado."
  cmake -S "$fonte" -B "$fonte/build" -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF \
    -DWHISPER_BUILD_TESTS=OFF -DWHISPER_BUILD_SERVER=OFF -DWHISPER_SDL2=OFF
  cmake --build "$fonte/build" --target whisper-cli -j "$(nproc)"
  mkdir -p "$(dirname "$WHISPER_BIN")"
  cp "$fonte/build/bin/whisper-cli" "$WHISPER_BIN"
  rm -rf "$fonte"
fi

MODELOS="$RAIZ/modelos"; mkdir -p "$MODELOS"
if [[ $MODELO_MELHOR == 1 ]]; then MW_ARQ='ggml-large-v3-turbo-q5_0.bin'; MW_URL=$TURBO_URL; MW_SHA=$TURBO_SHA
else MW_ARQ='ggml-small.bin'; MW_URL=$SMALL_URL; MW_SHA=$SMALL_SHA; fi
echo "    modelo: $MW_ARQ"
baixar "$MW_URL" "$MW_SHA" "$MODELOS/$MW_ARQ"

if [[ $RESUMO_LOCAL == 1 ]]; then
  passo 'Modelo de resumo (local, ~2 GB)'
  command -v llama-server >/dev/null || falhar 'llama-server não encontrado (pacote llama-cpp).'
  baixar "$QWEN_URL" "$QWEN_SHA" "$MODELOS/$QWEN_ARQ"
fi

passo 'Configuração'
# Mesma lógica do instalar.ps1: mescla com o exemplo e decide onde resumir.
RESUMO_LOCAL=$RESUMO_LOCAL SEM_RESUMO=$SEM_RESUMO MW_ARQ=$MW_ARQ QWEN_ARQ=$QWEN_ARQ node --input-type=module -e '
import fs from "node:fs"
const e = process.env
const exemplo = JSON.parse(fs.readFileSync("config.exemplo.json", "utf8").replace(/^﻿/, ""))
let cfg
if (fs.existsSync("config.json")) {
  cfg = JSON.parse(fs.readFileSync("config.json", "utf8").replace(/^﻿/, ""))
  for (const [k, v] of Object.entries(exemplo)) if (k !== "resumo_onde" && !(k in cfg)) cfg[k] = v
} else { cfg = { ...exemplo }; delete cfg.resumo_onde }
cfg.modelo_whisper = e.MW_ARQ
cfg.resumo = e.SEM_RESUMO !== "1"
cfg.resumo_onde = e.RESUMO_LOCAL === "1" ? "local"
  : cfg.resumo_onde ?? (fs.existsSync("modelos/" + e.QWEN_ARQ) ? "local" : "servidor")
fs.writeFileSync("config.json", JSON.stringify(cfg, null, 2) + "\n")
console.log("    resumo: " + (cfg.resumo ? cfg.resumo_onde : "desligado"))
'
PORTA=$(node -p 'require("./config.json").porta_painel')

passo 'Iniciar junto com o sistema (systemd do usuário)'
UNIDADE="$HOME/.config/systemd/user/transcreve-zap.service"
mkdir -p "$(dirname "$UNIDADE")"
cat > "$UNIDADE" <<UNIT
[Unit]
Description=Transcreve Zap (transcrição de áudios do WhatsApp)
After=network-online.target

[Service]
WorkingDirectory=$RAIZ
ExecStart=$(command -v node) $RAIZ/src/index.js
Restart=on-failure
RestartSec=10
Nice=10

[Install]
WantedBy=default.target
UNIT
systemctl --user daemon-reload
systemctl --user enable transcreve-zap.service >/dev/null
echo "    $UNIDADE"
echo "    (para rodar mesmo sem login: sudo loginctl enable-linger $USER)"

painel="http://localhost:$PORTA"
if [[ $NAO_INICIAR == 1 ]]; then
  progresso 'PRONTO: instalado, mas não iniciado (--nao-iniciar). Para abrir: ./iniciar.sh'
  echo -e "\nInstalado. Para abrir: ./iniciar.sh"
  exit 0
fi

passo 'Abrindo o programa'
systemctl --user restart transcreve-zap.service
estado=''
for _ in $(seq 60); do
  sleep 1
  estado=$(curl -fs --max-time 2 "http://127.0.0.1:$PORTA/estado" || true)
  [[ -n "$estado" ]] && break
done
if [[ -z "$estado" ]]; then
  fim=$(tail -n 15 "$DADOS/transcreve-zap.log" 2>/dev/null || journalctl --user -u transcreve-zap -n 15 --no-pager)
  falhar "O programa não abriu. Últimas linhas do log:
$fim"
fi
command -v xdg-open >/dev/null && xdg-open "$painel" >/dev/null 2>&1 &
progresso "PRONTO: programa rodando. Painel em $painel ($estado)"
echo -e "\n\033[32mPronto! Abra $painel e escaneie o QR Code com o WhatsApp do celular.\033[0m"
