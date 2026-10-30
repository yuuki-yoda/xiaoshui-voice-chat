import 'package:flutter/material.dart';
import '../models/chat_message.dart';

/// 对话气泡组件
class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: message.isUser ? 60 : 16,
        right: message.isUser ? 16 : 60,
        top: 4,
        bottom: 4,
      ),
      child: Column(
        crossAxisAlignment:
            message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: message.isUser
                  ? Colors.blue.shade100
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft:
                    message.isUser ? Radius.circular(16) : Radius.circular(4),
                bottomRight:
                    message.isUser ? Radius.circular(4) : Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.isUser ? '你' : '小水 💧',
                  style: TextStyle(
                    fontSize: 12,
                    color: message.isUser ? Colors.blue.shade700 : Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  message.text,
                  style: TextStyle(fontSize: 16),
                ),
                if (message.audioBase64 != null) ...[
                  SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.volume_up, size: 14, color: Colors.green.shade600),
                      SizedBox(width: 4),
                      Text(
                        '🔊 ${(message.durationMs ?? 0) ~/ 1000}.${((message.durationMs ?? 0) % 1000) ~/ 100}秒',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: 2),
          Text(
            _formatTime(message.time),
            style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
