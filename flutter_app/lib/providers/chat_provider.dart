import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../services/voice_service.dart';
import '../services/api_service.dart';
import '../services/audio_service.dart';

/// 对话状态
enum ChatState {
  idle,       // 待命
  listening,  // 录音中
  thinking,   // AI 思考中
  speaking,   // 播放回复中
  error,      // 出错
}

/// 对话管理器
class ChatProvider extends ChangeNotifier {
  final VoiceService _voice = VoiceService();
  final ApiService _api = ApiService();
  final AudioService _audio = AudioService();

  ChatState _state = ChatState.idle;
  List<ChatMessage> _messages = [];
  String? _errorMessage;
  String _partialText = '';

  ChatState get state => _state;
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  String? get errorMessage => _errorMessage;
  String get partialText => _partialText;

  /// 初始化
  Future<void> init() async {
    await _voice.initialize();
  }

  /// 开始录音
  Future<void> startRecording() async {
    _errorMessage = null;
    _state = ChatState.listening;
    _partialText = '';
    notifyListeners();

    await _voice.startListening(
      onResult: (text) {
        _partialText = text;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = error;
        _state = ChatState.error;
        notifyListeners();
      },
    );
  }

  /// 停止录音并发送
  Future<void> stopRecording() async {
    await _voice.stopListening();

    final text = _partialText.trim();
    if (text.isEmpty) {
      _state = ChatState.idle;
      notifyListeners();
      return;
    }

    // 添加用户消息
    _messages.add(ChatMessage.fromUser(text));
    _state = ChatState.thinking;
    _partialText = '';
    notifyListeners();

    try {
      // 调用后端
      final response = await _api.sendChat(text);

      // 添加回复消息
      _messages.add(ChatMessage.fromReply(
        response.replyText,
        audioBase64: response.audioBase64,
        durationMs: response.durationMs,
      ));

      _state = ChatState.idle;
      notifyListeners();

      // 自动播放语音
      if (response.audioBase64 != null && response.audioFormat != null) {
        _state = ChatState.speaking;
        notifyListeners();

        await _audio.playBase64Audio(
          response.audioBase64!,
          response.audioFormat!,
        );

        _state = ChatState.idle;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      _state = ChatState.error;
      notifyListeners();
    }
  }

  /// 取消录音
  Future<void> cancelRecording() async {
    await _voice.cancelListening();
    _partialText = '';
    _state = ChatState.idle;
    notifyListeners();
  }

  /// 清除错误
  void clearError() {
    _errorMessage = null;
    _state = ChatState.idle;
    notifyListeners();
  }

  @override
  void dispose() {
    _voice.dispose();
    _audio.dispose();
    super.dispose();
  }
}
