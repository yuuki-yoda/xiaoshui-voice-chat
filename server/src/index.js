import express from 'express';
import cors from 'cors';
import config from './config.js';
import chatRouter from './routes/chat.js';

const app = express();

// 中间件
app.use(cors());
app.use(express.json({ limit: '1mb' }));

// 请求日志
app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    const ms = Date.now() - start;
    console.log(`[${new Date().toISOString()}] ${req.method} ${req.path} → ${res.statusCode} (${ms}ms)`);
  });
  next();
});

// 路由
app.use('/api', chatRouter);

// 健康检查
app.get('/api/health', (req, res) => {
  res.json({
    status: 'ok',
    time: new Date().toISOString(),
    tts: 'edge-tts',
    llm: config.deepseek.apiKey ? 'deepseek' : 'unavailable',
  });
});

// 404
app.use((req, res) => {
  res.status(404).json({ code: 404, message: '接口不存在' });
});

// 全局错误处理
app.use((err, req, res, next) => {
  console.error('[server] Unhandled error:', err);
  res.status(500).json({ code: 500, message: '服务器内部错误' });
});

// 启动
app.listen(config.port, '0.0.0.0', () => {
  console.log(`
╔════════════════════════════════════╗
║     小水语音对话服务 v1.0          ║
║                                    ║
║  端口: ${String(config.port).padEnd(29)}║
║  LLM:  ${(config.deepseek.apiKey ? 'DeepSeek ✅' : '未配置 ❌').padEnd(27)}║
║  TTS:  edge-tts ✅                 ║
╚════════════════════════════════════╝
  `);
});
