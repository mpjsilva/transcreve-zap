# Instruções para o agente (Claude Code, Codex etc.)

Se a pessoa pediu para **instalar** o Transcreve Zap, siga exatamente estes passos.
Não improvise outra forma de instalar e não altere o código.

1. Confira o sistema. Em **Linux com `dnf` ou `apt`** (Fedora, Ubuntu, Debian e derivadas), rode `./instalar.sh`
   (mesmas opções: `--resumo-local`, `--modelo-melhor`, `--sem-resumo`), em segundo
   plano, uma vez só. Se faltarem pacotes e não houver terminal, ele para com
   `ERRO:` e o comando `sudo dnf/apt-get install ...`: peça à pessoa para rodá-lo
   (com `!` na frente) e rode o instalador de novo. Acompanhe
   `dados/instalacao.txt` como abaixo; reinicie com `./parar.sh` e `./iniciar.sh`.
   Em Windows 10/11 64 bits, siga os passos abaixo. Em outro sistema, avise e pare.
2. Na pasta deste repositório, rode o instalador **uma vez só**, em segundo plano:

   ```powershell
   Start-Process powershell -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','.\instalar.ps1' -WorkingDirectory (Get-Location)
   ```

   Ele baixa cerca de 600 MB (modelo de transcrição) e leva alguns minutos.
   O resumo é feito no servidor de resumo, recebendo só o texto transcrito.
   Se a pessoa pedir que nada saia do PC, acrescente `-ResumoLocal` (baixa mais
   ~2 GB e precisa de 8 GB de RAM; com menos, o script volta para o servidor). Não espere o comando terminar e **nunca rode o instalador de novo
   enquanto o primeiro estiver em andamento**: duas instalações juntas corrompem
   as bibliotecas (o script recusa a segunda, mas não tente).
   O script não pede administrador e confere o SHA-256 de cada download.
3. Acompanhe pelo arquivo `dados\instalacao.txt`, lendo de 30 em 30 segundos:
   - `EM ANDAMENTO: ...` mostra a etapa atual. Durante um download, o arquivo
     `.parcial` indicado cresce até o tamanho final.
   - `PRONTO: ...` significa que terminou e o painel já respondeu.
   - `ERRO: ...` traz o motivo. Mostre à pessoa; não tente consertar mudando o código.
   - O padrão é o Whisper `small`. Se o PC for recente e potente (8 núcleos
     ou mais) e a pessoa quiser mais precisão, acrescente `-ModeloMelhor`.
4. No final o script abre `http://localhost:3210` no navegador. Diga à pessoa:
   "Abra o WhatsApp no celular, vá em ⋮ > Dispositivos conectados > Conectar
   dispositivo e aponte para o QR Code que abriu no navegador."
5. Confirme a conexão consultando `http://localhost:3210/estado` até `status`
   virar `conectado` (espere até 2 minutos).
6. Explique em poucas linhas:
   - Os áudios recebidos são transcritos neste PC e a transcrição chega na
     própria conversa, respondendo ao áudio. O contato também vê.
   - Para áudios longos, só o texto vai para o servidor de resumo, que devolve
     o resumo sem guardar nada. O áudio não sai do PC.
   - Para que só a pessoa veja, mude `modo_resposta` para `"privado"` em
     `config.json` (vai para "Mensagens para mim") e reinicie (`parar.ps1` e
     depois `iniciar-oculto.vbs`).
   - O PC precisa estar ligado. O programa inicia junto com o Windows.

## Problemas comuns

- Log em `dados\transcreve-zap.log`.
- Abra o programa sempre pelo `iniciar-oculto.vbs`, nunca rodando o `node.exe`
  direto: assim ele fica sem janela, e fechar a janela não desliga o programa.
- "já está rodando": o programa já está aberto; use o painel em `http://localhost:3210`.
- Para reconectar do zero: `parar.ps1`, apague `dados\sessao-whatsapp`, rode `iniciar-oculto.vbs`.
- Para remover: `desinstalar.ps1`.

## Para quem for mexer no código

- Node.js (ESM), entrada em `src/index.js`. WhatsApp via Baileys, transcrição com
  whisper.cpp (`src/transcrever.js`), resumo com llama.cpp (`src/resumir.js`).
- O áudio e a sessão do WhatsApp nunca saem do computador. A única chamada
  externa (além do WhatsApp) é o texto transcrito indo para o servidor de resumo
  (`servidor/`), e `resumo_onde: "local"` desliga até isso. Não adicione outras
  chamadas externas sem deixar desligado por padrão e documentado.
