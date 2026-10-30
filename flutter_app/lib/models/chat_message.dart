/// 对话消息模型
class ChatMessage {
  final String text;        // 文字内容
  final bool isUser;        // true=用户, false=小水
  final String? audioBase64; // 音频数据（仅小水回复有）
  final int? durationMs;    // 音频时长
  final DateTime time;      // 发送时间

  ChatMessage({
    required this.text,
    required this.isUser,
    this.audioBase64,
    this.durationMs,
    DateTime? time,
  }) : time = time ?? DateTime.now();

  /// 从服务器回复构造
  factory ChatMessage.fromReply(String replyText, {String? audioBase64, int? durationMs}) {
    return ChatMessage(
      text: replyText,
      isUser: false,
      audioBase64: audioBase64,
      durationMs: durationMs,
    );
  }

  /// 从用户输入构造
  factory ChatMessage.fromUser(String userText) {
    return ChatMessage(
      text: userText,
      isUser: true,
    );
  }
}
