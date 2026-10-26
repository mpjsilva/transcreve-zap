// Áudio do WhatsApp (ogg/opus) -> wav 16 kHz -> whisper.cpp -> texto. Tudo local.
import fs from 'node:fs'
import os from 'node:os'
import path from 'node:path'
import { execFile } from 'node:child_process'
import ffmpeg from 'ffmpeg-static'
import { PASTA_TEMP, PASTA_MODELOS, WHISPER_EXE } from './config.js'

// Roda com prioridade baixa: o sistema dá preferência ao que a pessoa estiver usando.
export function prioridadeBaixa (pid) {
  try { os.setPriority(pid, os.constants.priority.PRIORITY_BELOW_NORMAL) } catch {}
}

function rodar (exe, args) {
  return new Promise((resolve, reject) => {
    const filho = execFile(exe, args, { windowsHide: true, maxBuffer: 20 * 1024 * 1024 }, (erro, stdout, stderr) => {
      if (erro) { erro.message += `\n${stderr}`; reject(erro) } else resolve(stdout)
    })
    prioridadeBaixa(filho.pid)
  })
}

export async function transcrever (bufferAudio, config) {
  const base = path.join(PASTA_TEMP, `audio-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`)
  const ogg = base + '.ogg'
  const wav = base + '.wav'
  const txt = base + '.txt'
  try {
    fs.writeFileSync(ogg, bufferAudio)
    await rodar(ffmpeg, ['-y', '-loglevel', 'error', '-i', ogg, '-ar', '16000', '-ac', '1', '-c:a', 'pcm_s16le', wav])
    await rodar(WHISPER_EXE, [
      '-m', path.join(PASTA_MODELOS, config.modelo_whisper),
      '-f', wav,
      '-l', 'pt',
      '-t', String(config.threads),
      '-nt', '-np',
      '-otxt', '-of', base
    ])
    return fs.readFileSync(txt, 'utf8').replace(/\s+/g, ' ').trim()
  } finally {
    for (const f of [ogg, wav, txt]) fs.rmSync(f, { force: true })
  }
}
