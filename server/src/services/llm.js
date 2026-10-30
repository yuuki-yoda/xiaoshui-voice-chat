import config from '../config.js';

/**
 * 调用 DeepSeek API 生成回复
 * @param {string} text - 用户输入的文字
 * @param {Array} history - 历史对话（可选）
 * @returns {Promise<string>} - AI 回复文字
 */
export async function getChatReply(text, history = []) {
  if (!config.deepseek.apiKey) {
    throw new Error('DEEPSEEK_API_KEY 未配置');
  }

  const messages = [
    { role: 'system', content: config.systemPrompt },
    ...history.slice(-10), // 最多保留 10 轮历史
    { role: 'user', content: text },
  ];

  const response = await fetch(`${config.deepseek.baseUrl}/v1/chat/completions`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${config.deepseek.apiKey}`,
    },
    body: JSON.stringify({
      model: config.deepseek.model,
      messages,
      temperature: 0.7,
      max_tokens: 300,
      stream: false,
    }),
  });

  if (!response.ok) {
    const errBody = await response.text().catch(() => '');
    throw new Error(`DeepSeek API Error ${response.status}: ${errBody}`);
  }

  const data = await response.json();
  const reply = data.choices?.[0]?.message?.content?.trim();

  if (!reply) {
    throw new Error('DeepSeek 返回空回复');
  }

  return reply;
}
