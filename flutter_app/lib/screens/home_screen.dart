import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/record_button.dart';
import '../widgets/chat_bubble.dart';

/// 主页面
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('💧', style: TextStyle(fontSize: 20)),
            SizedBox(width: 8),
            Text(
              '小水语音',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.grey),
            onPressed: () {
              // 清除对话
              context.read<ChatProvider>().clearError();
            },
            tooltip: '清除',
          ),
        ],
      ),
      body: Consumer<ChatProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // 对话列表
              Expanded(
                child: provider.messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        itemCount: provider.messages.length,
                        itemBuilder: (context, index) {
                          return ChatBubble(
                            message: provider.messages[index],
                          );
                        },
                      ),
              ),

              // 错误提示
              if (provider.errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.red.shade50,
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          provider.errorMessage!,
                          style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => provider.clearError(),
                        child: Icon(Icons.close, color: Colors.red, size: 16),
                      ),
                    ],
                  ),
                ),

              // 底部录音按钮
              _buildBottomBar(provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.mic, size: 64, color: Colors.grey.shade300),
          SizedBox(height: 16),
          Text(
            '按住下方按钮开始说话',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade400,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '松开后自动发送 & 语音回复',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade300,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(ChatProvider provider) {
    final isActive = provider.state != ChatState.idle &&
        provider.state != ChatState.error;

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: 32, // 底部安全区
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 状态文字
          if (isActive)
            Expanded(
              child: Text(
                provider.state == ChatState.listening
                    ? (provider.partialText.isNotEmpty
                        ? provider.partialText
                        : '正在听你说话...')
                    : provider.state == ChatState.thinking
                        ? '小水思考中...'
                        : '播放回复中...',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            )
          else
            Expanded(child: SizedBox()),

          // 录音按钮
          RecordButton(provider: provider),
        ],
      ),
    );
  }
}
