// Caminhos e configuração. Tudo fica dentro da pasta do programa.
import fs from 'node:fs'
import path from 'node:path'
import os from 'node:os'
import { fileURLToPath } from 'node:url'

export const RAIZ = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
export const DADOS = path.join(RAIZ, 'dados')
export const PASTA_SESSAO = path.join(DADOS, 'sessao-whatsapp')
export const PASTA_TEMP = path.join(DADOS, 'temp')
export const ARQ_LOG = path.join(DADOS, 'transcreve-zap.log')
export const ARQ_CONFIG = path.join(RAIZ, 'config.json')
export const ARQ_ID_INSTALACAO = path.join(DADOS, 'id-instalacao.txt')

// No Windows os executáveis vêm prontos em ferramentas\. No Linux (Fedora) o
// whisper-cli é compilado pelo instalar.sh e o llama-server vem do pacote
// llama-cpp do sistema, a não ser que exista um em ferramentas/llama.
const EXT = process.platform === 'win32' ? '.exe' : ''
export const WHISPER_EXE = path.join(RAIZ, 'ferramentas', 'whisper', 'whisper-cli' + EXT)
const LLAMA_LOCAL = path.join(RAIZ, 'ferramentas', 'llama', 'llama-server' + EXT)
export const LLAMA_EXE = process.platform === 'win32' || fs.existsSync(LLAMA_LOCAL) ? LLAMA_LOCAL : 'llama-server'
export const PASTA_MODELOS = path.join(RAIZ, 'modelos')

const PADRAO = {
  // "conversa": responde na própria conversa, citando o áudio (o contato vê).
  // "privado": manda a transcrição só para você, em "Mensagens para mim".
  modo_resposta: 'conversa',
  // Transcrever áudios recebidos em grupos.
  grupos: false,
  // Só gera resumo quando a transcrição passa deste número de palavras.
  limite_palavras_resumo: 20,
  // Liga/desliga o resumo (a transcrição continua).
  resumo: true,
  // "servidor": manda só o texto transcrito para o servidor de resumo.
  // "local": resume no próprio PC (precisa do modelo, instalar com -ResumoLocal).
  resumo_onde: 'servidor',
  servidor_resumo: 'https://resumo.nanx.com.br',
  modelo_whisper: 'ggml-small.bin',
  modelo_resumo: 'qwen2.5-3b-instruct-q4_k_m.gguf',
  // Áudios mais velhos que isso (ex.: chegaram com o PC desligado) são ignorados.
  idade_maxima_horas: 12,
  porta_painel: 3210,
  // Metade dos processadores lógicos (≈ núcleos físicos); mais que isso não acelera o Whisper.
  threads: Math.max(2, Math.min(8, Math.floor(os.cpus().length / 2)))
}

export function carregarConfig () {
  let doArquivo = {}
  if (fs.existsSync(ARQ_CONFIG)) {
    doArquivo = JSON.parse(fs.readFileSync(ARQ_CONFIG, 'utf8').replace(/^﻿/, ''))
  }
  // Instalação antiga, de antes do resumo no servidor: se o modelo local
  // existe, continua resumindo no PC em vez de passar a mandar texto para fora.
  if (doArquivo.resumo_onde === undefined) {
    const modelo = path.join(PASTA_MODELOS, doArquivo.modelo_resumo || PADRAO.modelo_resumo)
    if (fs.existsSync(modelo)) doArquivo.resumo_onde = 'local'
  }
  return { ...PADRAO, ...doArquivo }
}

for (const p of [DADOS, PASTA_TEMP]) fs.mkdirSync(p, { recursive: true })

export function log (...partes) {
  const linha = `[${new Date().toLocaleString('pt-BR')}] ${partes.join(' ')}`
  console.log(linha)
  try { fs.appendFileSync(ARQ_LOG, linha + '\n') } catch {}
}
