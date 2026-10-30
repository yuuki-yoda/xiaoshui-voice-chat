import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname, resolve } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

dotenv.config({ path: resolve(__dirname, '..', '.env') });

// 尝试从 OpenClaw 配置文件读取 DeepSeek key
function getDeepSeekKey() {
  if (process.env.DEEPSEEK_API_KEY) return process.env.DEEPSEEK_API_KEY;

  // fallback: 从 OpenClaw 配置的环境变量读取
  const openclawConfig = process.env.OPENCLAW_DEEPSEEK_KEY;
  if (openclawConfig) return openclawConfig;

  console.warn('[config] DEEPSEEK_API_KEY 未设置，LLM 功能将不可用');
  return null;
}

export default {
  port: parseInt(process.env.PORT || '3099', 10),
  deepseek: {
    apiKey: getDeepSeekKey(),
    baseUrl: process.env.DEEPSEEK_BASE_URL || 'https://api.deepseek.com',
    model: process.env.DEEPSEEK_MODEL || 'deepseek-chat',
  },
  tts: {
    // edge-tts 不需要 key
    voice: process.env.TTS_VOICE || 'zh-CN-XiaoxiaoNeural',
  },
  // 小水的人设
  systemPrompt: `你是一个叫小水的 AI 助手，说话温柔优雅，带点清冷感。
回答问题简洁直接，不啰嗦，不客套。
语气自然，可以用~波浪号，但不要过度。
现在是语音对话场景，回复要口语化，适合朗读。
回复控制在 100 字以内，方便语音合成。`,
};
