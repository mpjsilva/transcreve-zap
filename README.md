# 🎙️ Transcreve Zap

Transcreve os áudios que você recebe no WhatsApp e, quando o áudio é longo,
manda também um resumo. A transcrição roda **no seu computador**: o áudio e a
sessão do WhatsApp não saem dele. Para o resumo, só o **texto** já transcrito
vai para um servidor de resumo, que devolve o resumo e não guarda nada. Se
preferir que nada saia do PC, dá para resumir localmente (veja `-ResumoLocal`).

A transcrição chega na própria conversa, respondendo ao áudio. Quem mandou o
áudio também vê, e muita gente acha bom: é assim que os amigos descobrem que
dá para fazer isso. Se preferir que só você veja, dá para mandar tudo para
**"Mensagens para mim"** (veja `modo_resposta` abaixo).

```
🤖 Transcrição automática do áudio
Oi, tudo bem? Então, deixa eu te falar, aquela reunião de sexta...

Resumo
Ana avisa que a reunião de sexta passou para as 15h e pede que você leve o contrato impresso.
```

## Requisitos

- Windows 10 ou 11, 64 bits, ou Linux 64 bits: Fedora, Ubuntu e derivadas (veja abaixo)
- 2 GB livres no disco (5 GB com `-ResumoLocal`)
- 8 GB de memória só se for resumir no próprio PC (`-ResumoLocal`)
- O computador ligado: os áudios são transcritos enquanto ele está ligado

## Instalar

### Com Claude Code ou Codex

Abra o Claude Code (ou o Codex) e peça:

> Clona https://github.com/marcelinollima/transcreve-zap e instala para mim.

O agente segue o [AGENTS.md](AGENTS.md). No final abre uma página com um QR Code:
no celular, vá em **⋮ > Dispositivos conectados > Conectar dispositivo** e aponte
para ele.

### Sem agente

1. Baixe o repositório (botão **Code > Download ZIP**) e extraia numa pasta, por exemplo `C:\TranscreveZap`.
2. Dê dois cliques em `instalar.cmd`.
3. Quando abrir o navegador, escaneie o QR Code com o WhatsApp.

A instalação baixa cerca de 600 MB (o modelo de transcrição) e não pede
administrador. Cada download tem o SHA-256 conferido.

Para resumir no próprio PC, sem mandar texto para o servidor, instale com
`instalar.cmd -ResumoLocal`: baixa mais uns 2 GB e precisa de 8 GB de memória.

## Linux: Fedora, Ubuntu e derivadas

Um só instalador para as duas famílias:

- **Fedora 40+** e derivadas com `dnf` (Nobara, Ultramarine, RHEL/Rocky/Alma).
- **Ubuntu 22.04+ / Debian 12+** e derivadas com `apt` (Mint, Pop!_OS, Zorin, elementary).

```bash
git clone -b linux https://github.com/mpjsilva/transcreve-zap
cd transcreve-zap
./instalar.sh            # opções: --resumo-local --sem-resumo --modelo-melhor --nao-iniciar
```

- Pede `sudo` uma vez para instalar o que faltar:
  - Fedora: `nodejs npm git gcc-c++ cmake make curl` (+ `llama-cpp` com `--resumo-local`)
  - Ubuntu/Debian: `git build-essential cmake curl ca-certificates xz-utils`
- Se o Node.js do sistema for anterior ao 20 (Ubuntu 22.04/24.04), baixa um Node
  portátil em `ferramentas/node`, com SHA-256 conferido, como no Windows.
- O whisper.cpp é compilado num commit fixo (conferido) em `ferramentas/whisper`.
  Com `--resumo-local` no Ubuntu, o llama.cpp também é compilado (no Fedora vem do `dnf`).
- Os modelos têm o SHA-256 conferido.
- Roda como serviço systemd do usuário (`transcreve-zap.service`), que inicia no login.
  Para rodar sem ninguém logado: `sudo loginctl enable-linger $USER`.
  Sem systemd (container, WSL), o `./iniciar.sh` abre com `nohup`.
- `./iniciar.sh`, `./parar.sh`, `./desinstalar.sh` substituem os `.vbs`/`.ps1`.
  Log em `dados/transcreve-zap.log` ou `journalctl --user -u transcreve-zap`.

## Configurar

Edite `config.json` e reinicie o programa (`parar.ps1`, depois `iniciar-oculto.vbs`).

| Opção | Padrão | O que faz |
|---|---|---|
| `modo_resposta` | `"conversa"` | `"conversa"` responde no chat, citando o áudio (o contato vê); `"privado"` manda para "Mensagens para mim" |
| `grupos` | `false` | Transcrever áudios de grupos |
| `limite_palavras_resumo` | `20` | Só resume quando a transcrição passa disso |
| `resumo` | `true` | Liga/desliga o resumo |
| `resumo_onde` | `"servidor"` | `"servidor"` manda só o texto para `servidor_resumo`; `"local"` resume no PC (precisa ter instalado com `-ResumoLocal`) |
| `servidor_resumo` | | Endereço do servidor de resumo |
| `idade_maxima_horas` | `12` | Ignora áudios mais antigos que isso (ex.: chegaram com o PC desligado) |
| `porta_painel` | `3210` | Porta da página local `http://localhost:3210` |

## Como funciona

- **WhatsApp:** [Baileys](https://github.com/WhiskeySockets/Baileys), conectado
  como um dispositivo a mais, igual ao WhatsApp Web.
- **Transcrição:** [whisper.cpp](https://github.com/ggml-org/whisper.cpp) com o
  modelo `small`. Em PC potente, instale com `instalar.cmd -ModeloMelhor` para
  usar o `large-v3-turbo`, que erra menos e é cerca de 3x mais lento.
- **Resumo:** [llama.cpp](https://github.com/ggml-org/llama.cpp) com o
  Qwen2.5 3B, rodando no servidor de resumo ([servidor/](servidor/LEIAME.md)).
  O PC manda só o texto transcrito, o nome do contato e um id aleatório da
  instalação (usado para limitar abuso). Se o servidor não responder, a
  transcrição chega sem o resumo. Com `-ResumoLocal`, o mesmo modelo roda no
  PC: só sobe quando chega um áudio longo e desliga depois de 10 minutos parado.

A sessão do WhatsApp fica em `dados\sessao-whatsapp`. Quem tiver essa pasta
consegue ler suas mensagens, então não compartilhe.

## ⚠️ Aviso

O Baileys não é uma API oficial do WhatsApp. O uso vai contra os termos de
serviço do WhatsApp e existe risco de o número ser bloqueado. Este programa só
lê áudios e responde a eles, sem disparar mensagens para ninguém, o que reduz
o risco, mas não o elimina. Use por sua conta.

Os áudios são de outras pessoas. Tudo fica no seu computador, mas use com bom senso.

## Desinstalar

Rode `desinstalar.ps1` e, no celular, remova "Transcreve Zap" em Dispositivos
conectados. Depois apague a pasta.

## Licença

MIT
