import { Router } from 'express';
import { getChatReply } from '../services/llm.js';
import { textToSpeech } from '../services/tts.js';

const router = Router();

// 对话历史存储（内存，重启丢失）
const sessions = new Map();
const MAX_SESSION_AGE = 30 * 60 * 1000; // 30 分钟

// 定时清理过期会话
setInterval(() => {
  const now = Date.now();
  for (const [sid, session] of sessions) {
    if (now - session.lastActive > MAX_SESSION_AGE) {
      sessions.delete(sid);
    }
  }
}, 5 * 60 * 1000);

/**
 * POST /api/chat
 * 核心对话接口：文字输入 → LLM 回复 → TTS 语音
 */
router.post('/chat', async (req, res) => {
  const startTime = Date.now();

  try {
    const { text, session_id, voice } = req.body;

    // 参数校验
    if (!text || typeof text !== 'string' || text.trim().length === 0) {
      return res.status(400).json({
        code: 400,
        message: '请输入文字内容',
      });
    }

    if (text.length > 500) {
      return res.status(400).json({
        code: 400,
        message: '文字太长啦，控制在 500 字以内吧～',
      });
    }

    // 获取或创建会话
    const sid = session_id || `session_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;
    if (!sessions.has(sid)) {
      sessions.set(sid, { history: [], lastActive: Date.now() });
    }
    const session = sessions.get(sid);
    session.lastActive = Date.now();

    // 1. 调用 LLM 获取回复
    let reply;
    try {
      reply = await getChatReply(text.trim(), session.history);
    } catch (llmError) {
      console.error('[chat] LLM error:', llmError.message);
      return res.status(502).json({
        code: 502,
        message: '哎呀，脑子卡了一下，再试一次吧～',
        error: llmError.message,
      });
    }

    // 更新历史
    session.history.push(
      { role: 'user', content: text.trim() },
      { role: 'assistant', content: reply }
    );

    // 2. 调用 TTS 生成语音
    let audioData = null;
    try {
      audioData = await textToSpeech(reply, { voice });
    } catch (ttsError) {
      console.warn('[chat] TTS error, returning text only:', ttsError.message);
    }

    const elapsed = Date.now() - startTime;

    // 3. 返回结果
    const response = {
      code: 0,
      data: {
        reply_text: reply,
        session_id: sid,
        elapsed_ms: elapsed,
      },
    };

    if (audioData) {
      response.data.audio_base64 = audioData.audioBase64;
      response.data.audio_format = audioData.format;
      response.data.duration_ms = audioData.durationMs;
    }

    res.json(response);
  } catch (err) {
    console.error('[chat] Unexpected error:', err);
    res.status(500).json({
      code: 500,
      message: '服务器出了点小问题，稍后再试试～',
    });
  }
});

/**
 * POST /api/chat/text
 * 纯文字对话（不走 TTS，调试用）
 */
router.post('/chat/text', async (req, res) => {
  try {
    const { text } = req.body;
    if (!text) {
      return res.status(400).json({ code: 400, message: '请输入文字' });
    }

    const reply = await getChatReply(text);
    res.json({ code: 0, data: { reply_text: reply } });
  } catch (err) {
    res.status(500).json({ code: 500, message: err.message });
  }
});

export default router;
