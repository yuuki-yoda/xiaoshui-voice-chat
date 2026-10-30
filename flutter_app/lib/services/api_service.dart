import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// API 响应结构
class ChatResponse {
  final String replyText;
  final String? audioBase64;
  final String? audioFormat;
  final int? durationMs;
  final String? sessionId;
  final int? elapsedMs;

  ChatResponse({
    required this.replyText,
    this.audioBase64,
    this.audioFormat,
    this.durationMs,
    this.sessionId,
    this.elapsedMs,
  });
}

/// 后端 API 服务
class ApiService {
  String? _sessionId;
  final Duration _timeout = Duration(milliseconds: ApiConfig.timeoutMs);

  /// 发送聊天消息
  Future<ChatResponse> sendChat(String text) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.chatPath}');

    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'text': text,
            if (_sessionId != null) 'session_id': _sessionId,
          }),
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? '服务器错误 (${response.statusCode})');
    }

    final body = jsonDecode(response.body);
    final data = body['data'];

    // 保存会话 ID
    if (data['session_id'] != null) {
      _sessionId = data['session_id'];
    }

    return ChatResponse(
      replyText: data['reply_text'] ?? '',
      audioBase64: data['audio_base64'],
      audioFormat: data['audio_format'],
      durationMs: data['duration_ms'],
      sessionId: data['session_id'],
      elapsedMs: data['elapsed_ms'],
    );
  }

  /// 健康检查
  Future<bool> checkHealth() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.healthPath}');
      final response = await http.get(url).timeout(Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
