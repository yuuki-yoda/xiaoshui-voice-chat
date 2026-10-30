# 💧 小水语音对话 App

像豆包电话一样，按住说话 → 语音识别 → AI回复 → 自动播放语音。

---

## 一、后端已部署 ✅

| 项目 | 地址 |
|------|------|
| API 接口 | `http://YOUR_HOST/voice-chat/api/chat` |
| 健康检查 | `http://YOUR_HOST/voice-chat/api/health` |
| 后端端口 | 3099 |
| LLM | DeepSeek V4 Flash |
| TTS | Edge TTS (微软晓晓) |
| 守护 | systemd `voice-chat.service` |

### 测试方法
```bash
curl -X POST http://YOUR_HOST/voice-chat/api/chat \
  -H "Content-Type: application/json" \
  -d '{"text": "今天天气怎么样"}'
```

---

## 二、App 使用方法

### 你需要准备
1. **一台电脑**（装 Flutter SDK）
2. **一台 Android 手机**（iOS 需要 Mac 编译）

### 第一步：安装 Flutter SDK

**Windows / macOS / Linux 都可以：**
```bash
# 1. 下载 Flutter SDK
# https://docs.flutter.dev/get-started/install

# 2. 解压后添加 flutter/bin 到 PATH

# 3. 验证安装
flutter doctor
```

> 安卓打包只需要 Flutter SDK + Android Studio（或命令行 Android SDK）
> 你的电脑没有的话，我来帮你生成 APK 发给你也行。

### 第二步：生成项目模板
```bash
cd voice-chat-app
flutter create --project-name voice_chat_app flutter_app_template
```

### 第三步：替换源码
用 `flutter_app/` 目录下的文件覆盖模板的 `lib/` 和 `pubspec.yaml`。

具体来说：
```
# 替换 pubspec.yaml
cp flutter_app/pubspec.yaml flutter_app_template/pubspec.yaml

# 删除模板的 lib/，用我的源码
rm -rf flutter_app_template/lib/
cp -r flutter_app/lib/ flutter_app_template/lib/
```

### 第四步：安装依赖 & 打包
```bash
cd flutter_app_template
flutter pub get
flutter build apk --release
```

APK 生成在 `build/app/outputs/flutter-apk/app-release.apk`，传到手机上安装即可。

### 第五步：如果不想自己编译
告诉我，我可以用 GitHub Actions 或直接在你的电脑上远程编译，把 APK 发给你。

---

## 三、Flutter App 源码结构

```
flutter_app/lib/
├── main.dart                    # 入口
├── config/
│   └── api_config.dart          # API 地址配置
├── models/
│   └── chat_message.dart        # 消息数据模型
├── services/
│   ├── voice_service.dart       # 语音识别
│   ├── api_service.dart         # 后端 API 调用
│   └── audio_service.dart       # 音频播放
├── providers/
│   └── chat_provider.dart       # 对话状态管理
├── screens/
│   └── home_screen.dart         # 主页面
└── widgets/
    ├── record_button.dart        # 录音按钮组件
    └── chat_bubble.dart          # 对话气泡组件
```

---

## 四、后端源码结构

```
server/
├── package.json
├── .env                         # DeepSeek API Key
├── voice-chat.service           # systemd 配置
└── src/
    ├── index.js                 # Express 入口
    ├── config.js                # 配置
    ├── routes/
    │   └── chat.js              # 对话接口
    └── services/
        ├── llm.js               # DeepSeek 调用
        └── tts.js               # Edge TTS 语音合成
```

---

## 五、后续可优化

- [ ] 换火山引擎 TTS（音质更好，中文更自然）
- [ ] 加 WebSocket 支持（实时流式对话）
- [ ] iOS 端支持（需要 Mac 编译）
- [ ] 对话历史持久化
- [ ] 音色切换功能

---

*2026-06-22*
