# 语音对话 App — 技术方案

> 类似豆包电话功能：按住说话 → 语音识别 → AI对话 → 语音回复 → 自动播放

---

## 一、整体架构

```
┌─────────────────────┐     HTTP/WebSocket      ┌──────────────────────┐
│   Flutter App        │ ◄──────────────────────► │   Node.js Backend    │
│   (Android / iOS)    │     JSON + 音频base64    │   (阿里云 139...)    │
│                      │                          │                      │
│  ┌─────────────────┐ │                          │  ┌────────────────┐  │
│  │ speech_to_text   │ │  录音 → .wav/mp3        │  │ DeepSeek API   │  │
│  │ (本地语音识别)     │ │─────────────────────────►│  (LLM 对话)      │  │
│  └─────────────────┘ │                          │  └────────────────┘  │
│       ↓ 识别文字      │                          │       ↓ 回复文字     │
│  ┌─────────────────┐ │                          │  ┌────────────────┐  │
│  │ 调用后端API      │ │ ◄─────────────────────────┤  │ TTS Service    │  │
│  └─────────────────┘ │  音频base64 + 回复文字     │  │ (火山引擎/Edge) │  │
│       ↓              │                          │  └────────────────┘  │
│  ┌─────────────────┐ │                          └──────────────────────┘
│  │ 自动播放音频 🔊   │ │
│  └─────────────────┘ │
└─────────────────────┘
```

## 二、功能流程

### 一次对话周期

```
用户按住按钮
  → Flutter speech_to_text 实时语音识别
  → 松开时得到完整文字
  → POST /api/chat { text: "..." }
  → 后端：
       ① 调 DeepSeek 生成回复
       ② 调 TTS 将回复转为音频
  → 返回 { reply_text, audio_base64, audio_format }
  → App 自动播放音频
  → 同时显示文字回复（可语音/文字双模）
```

## 三、后端服务（Node.js）

### 3.1 技术栈
- **框架**: Express.js
- **运行**: 阿里云服务器 YOUR_HOST，systemd 守护
- **端口**: 3xxx（不冲突）
- **日志**: winston 写入文件

### 3.2 API 接口

#### `POST /api/chat`
核心接口：接收文字，返回回复文本 + 语音音频

**请求体：**
```json
{
  "text": "今天天气怎么样",
  "voice": "zh_female"        // 可选，音色偏好
}
```

**响应：**
```json
{
  "code": 0,
  "data": {
    "reply_text": "今天天气不错，适合出去走走～",
    "audio_base64": "//uQxAAAAA...",
    "audio_format": "mp3",
    "duration_ms": 3200
  }
}
```

#### `GET /api/health`
健康检查

#### `POST /api/toggle-model`
切换模型（开发用）

### 3.3 LLM 调用
- **模型**: DeepSeek V4 Flash（deepseek/deepseek-v4-flash）
- **API 地址**: https://api.deepseek.com/v1/chat/completions
- **API Key**: 从环境变量读取（DEEPSEEK_API_KEY）
- **system prompt**: 用小水的人设（SOUL.md 风格）

### 3.4 TTS 方案（选其一）

| 方案 | 效果 | 费用 | 网络要求 | 推荐度 |
|------|------|------|---------|--------|
| **火山引擎TTS** | ⭐⭐⭐⭐⭐ 抖音同款 | 新用户送100万字符 | 国内直连 ✅ | ⭐ 首选 |
| **Edge TTS** (edge-tts) | ⭐⭐⭐⭐ 微软语音 | 完全免费 | 国内直连 ✅ | ⭐ 备选 |
| **ElevenLabs** | ⭐⭐⭐⭐⭐ 最自然 | 有免费额度 | 需SOCKS5代理 | 备选 |

**实现方式：** 后端调用 TTS HTTP API（火山引擎）或 `edge-tts` 命令行/Python库，生成音频后 base64 返回。

## 四、Flutter App

### 4.1 技术栈
- **框架**: Flutter 3.x
- **语音识别**: `speech_to_text` 插件（本地识别，无需网络）
- **音频播放**: `audioplayers` 或 `just_audio` 插件
- **网络请求**: `dio` + `http`
- **状态管理**: Provider 或 Riverpod

### 4.2 界面设计

#### 主页面
```
┌─────────────────────┐
│    小水语音         │ ← 标题栏
│                     │
│    ┌─────────┐      │
│    │         │      │
│    │  按住   │      │ ← 大圆形按钮
│    │  说话   │      │   普通状态: 浅蓝色
│    │         │      │   录音中: 红色脉冲动画
│    └─────────┘      │
│                     │
│  对话记录:          │
│  ┌─────────────┐    │
│  │ ❄️ 今天天气...│    │ ← 历史对话卡片
│  │ 🔊 3.2秒    │    │
│  ├─────────────┤    │
│  │ ☀️ 挺好的... │    │
│  │ 🔊 2.8秒    │    │
│  └─────────────┘    │
└─────────────────────┘
```

#### 录音状态
- **待命**: 按钮显示"按住说话"，淡蓝色
- **录音中**: 按钮放大 + 呼吸灯动画，显示"正在听..."
- **处理中**: 显示加载动画，"小水正在思考..."
- **回复**: 自动播放语音，按钮恢复待命

### 4.3 核心组件

```
lib/
├── main.dart              # 入口
├── config/
│   └── api_config.dart    # 后端地址配置
├── models/
│   └── chat_message.dart  # 对话消息模型
├── services/
│   ├── voice_service.dart # 语音识别 + 录音
│   ├── api_service.dart   # HTTP 调用后端
│   └── audio_service.dart # 音频播放管理
├── providers/
│   └── chat_provider.dart # 对话状态管理
├── screens/
│   └── home_screen.dart   # 主页面
└── widgets/
    ├── record_button.dart # 录音按钮组件
    └── chat_bubble.dart   # 对话气泡组件
```

### 4.4 语音识别配置

```dart
// speech_to_text 插件
final SpeechToText speech = SpeechToText();

// 初始化
await speech.initialize(
  onStatus: (status) => print(status),
  onError: (error) => print(error),
  debugLogging: false,
);

// 开始监听
speech.listen(
  onResult: (result) {
    setState(() => _text = result.recognizedWords);
  },
  localeId: 'zh_CN',  // 中文识别
);
```

## 五、部署方案

### 5.1 后端部署
```
服务器: YOUR_HOST
目录: /opt/voice-chat-server/
进程管理: systemd → voice-chat.service
域名: voicechat.YOUR_HOST 或 nginx 反代到子路径
nginx: /voice-chat/ → localhost:3xxx
```

### 5.2 Flutter 打包
```bash
# Android APK
flutter build apk --release

# iOS IPA (需要Mac)
flutter build ios --release
```

## 六、开发计划

| 阶段 | 内容 | 预计 |
|------|------|------|
| ① 后端写代码 | Node.js Express + TTS集成 | 今天 |
| ② 后端部署 | systemd + nginx + 测试 | 今天 |
| ③ Flutter写代码 | 完整App代码 | 今天~明天 |
| ④ 你本地编译 | Android APK打包 | 需要你装Flutter |
| ⑤ 联调测试 | 端到端体验优化 | 一起 |

## 七、TTS 实现细节

### 方案A：火山引擎TTS（推荐）

```
API: https://openspeech.bytedance.com/api/v1/tts
Method: POST
Headers:
  Authorization: Bearer {access_token}
  Content-Type: application/json
Body:
{
  "app": { "appid": "xxx" },
  "user": { "uid": "xiaoshui" },
  "request": {
    "reqid": "uuid",
    "text": "回复文本",
    "text_type": "plain",
    "operation": "query",
    "speaker": "zh_female_2",   // 中文女声
    "audio_type": "mp3"
  }
}
```

### 方案B：Edge TTS（免费备选）
```python
# 用 edge-tts 命令行
edge-tts --voice zh-CN-XiaoxiaoNeural --text "回复" --write-media output.mp3
```

### 方案C：直接调用 ElevenLabs
```
API: https://api.elevenlabs.io/v1/text-to-speech/{voice_id}
Headers: xi-api-key: {key}
Body: { "text": "...", "model_id": "eleven_multilingual_v2" }
```
需走 SOCKS5 代理。

---

## 八、关键设计决策

1. **语音识别在Flutter端做** → 不消耗服务器资源，离线可用，响应快
2. **TTS在服务端做** → 统一音色，更换TTS服务不需要更新App
3. **音频返回base64** → 减少App端处理，一次请求完成全部
4. **超时处理** → 后端15秒超时兜底，前端显示"小水正在思考"loading

---

*方案版本: v1.0*
*2026-06-22*
