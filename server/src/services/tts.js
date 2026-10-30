import { execSync } from 'child_process';
import { readFileSync, unlinkSync, mkdirSync } from 'fs';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';
import { v4 as uuid } from 'uuid';
import config from '../config.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const TEMP_DIR = resolve(__dirname, '..', '..', 'tmp');

// 确保临时目录存在
mkdirSync(TEMP_DIR, { recursive: true });

/**
 * 用 edge-tts 将文字转为语音，返回 base64
 * @param {string} text - 要朗读的文字
 * @param {object} options
 * @param {string} options.voice - 音色名（可选）
 * @returns {Promise<{audioBase64: string, format: string, durationMs: number}>}
 */
export async function textToSpeech(text, options = {}) {
  const voice = options.voice || config.tts.voice;
  const outputFile = resolve(TEMP_DIR, `tts-${uuid()}.mp3`);

  try {
    // 调用 edge-tts 命令行
    const cmd = `edge-tts --voice "${voice}" --text "${escapeText(text)}" --write-media "${outputFile}"`;
    execSync(cmd, { timeout: 30000 });

    // 读取生成的音频文件
    const audioBuffer = readFileSync(outputFile);
    const audioBase64 = audioBuffer.toString('base64');

    // 估算时长（MP3: 约 1KB ≈ 0.026 秒）
    const estimatedDurationMs = Math.round((audioBuffer.length / 1024) * 26);

    return {
      audioBase64,
      format: 'mp3',
      durationMs: estimatedDurationMs,
    };
  } finally {
    // 清理临时文件
    try { unlinkSync(outputFile); } catch {}
  }
}

/**
 * 获取可用的中文音色列表
 * @returns {Promise<string[]>}
 */
export async function listVoices() {
  try {
    const output = execSync('edge-tts --list-voices', { timeout: 10000 }).toString();
    return output
      .split('\n')
      .filter(line => line.startsWith('zh-'))
      .map(line => line.trim());
  } catch {
    return ['zh-CN-XiaoxiaoNeural', 'zh-CN-YunxiNeural', 'zh-CN-YunyangNeural'];
  }
}

function escapeText(text) {
  // 转义特殊字符防止 shell 注入
  return text
    .replace(/\\/g, '\\\\')
    .replace(/"/g, '\\"')
    .replace(/`/g, '\\`')
    .replace(/\$/g, '\\$');
}
