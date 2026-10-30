import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';

/// 语音识别服务
/// 使用手机本地语音识别引擎（Android: Google Speech, iOS: Siri）
class VoiceService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _initialized = false;
  bool _isListening = false;

  bool get isListening => _isListening;
  bool get isAvailable => _initialized;

  /// 初始化语音识别
  Future<bool> initialize() async {
    if (_initialized) return true;

    _initialized = await _speech.initialize(
      onStatus: (status) {
        print('[VoiceService] Status: $status');
        if (status == 'done' || status == 'notListening') {
          _isListening = false;
        }
      },
      onError: (error) {
        print('[VoiceService] Error: $error');
        _isListening = false;
      },
      debugLogging: false,
    );

    return _initialized;
  }

  /// 开始监听语音
  Future<void> startListening({
    required Function(String text) onResult,
    required Function(String error) onError,
    String localeId = 'zh_CN',
  }) async {
    if (!_initialized) {
      final ok = await initialize();
      if (!ok) {
        onError('语音识别初始化失败，请检查麦克风权限');
        return;
      }
    }

    _isListening = true;

    await _speech.listen(
      onResult: (stt.SpeechRecognitionResult result) {
        if (result.finalResult) {
          onResult(result.recognizedWords);
        }
      },
      localeId: localeId,
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.confirmation,
        cancelOnError: true,
        partialResults: true,
      ),
    );
  }

  /// 停止监听
  Future<void> stopListening() async {
    _isListening = false;
    await _speech.stop();
  }

  /// 取消监听
  Future<void> cancelListening() async {
    _isListening = false;
    await _speech.cancel();
  }

  void dispose() {
    _speech.stop();
  }
}
