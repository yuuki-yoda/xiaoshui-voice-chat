import 'package:flutter/material.dart';
import '../providers/chat_provider.dart';

/// 录音按钮组件
/// 按住说话，松开发送
class RecordButton extends StatefulWidget {
  final ChatProvider provider;

  const RecordButton({super.key, required this.provider});

  @override
  State<RecordButton> createState() => _RecordButtonState();
}

class _RecordButtonState extends State<RecordButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1200),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String get _buttonText {
    switch (widget.provider.state) {
      case ChatState.idle:
        return '按住说话';
      case ChatState.listening:
        return '正在听...';
      case ChatState.thinking:
        return '小水思考中...';
      case ChatState.speaking:
        return '播放中...';
      case ChatState.error:
        return '出错了';
    }
  }

  Color get _buttonColor {
    switch (widget.provider.state) {
      case ChatState.idle:
        return Colors.blue;
      case ChatState.listening:
        return Colors.red;
      case ChatState.thinking:
        return Colors.orange;
      case ChatState.speaking:
        return Colors.green;
      case ChatState.error:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isListening = widget.provider.state == ChatState.listening;

    if (isListening) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }

    return GestureDetector(
      onLongPressStart: (_) => widget.provider.startRecording(),
      onLongPressEnd: (_) => widget.provider.stopRecording(),
      onLongPressCancel: () => widget.provider.cancelRecording(),
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: isListening ? _pulseAnimation.value : 1.0,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _buttonColor,
                boxShadow: [
                  BoxShadow(
                    color: _buttonColor.withValues(alpha: 0.3),
                    blurRadius: isListening ? 30 : 10,
                    spreadRadius: isListening ? 5 : 0,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _buttonText,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// AnimatedBuilder 的简单实现
class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required super.listenable,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}
