import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';

/// 音频播放服务
class AudioService {
  final AudioPlayer _player = AudioPlayer();

  /// 播放 base64 编码的音频
  Future<void> playBase64Audio(String base64Data, String format) async {
    try {
      // 将 base64 解码为字节
      final bytes = base64Decode(base64Data);

      // 写入临时文件
      final tempDir = Directory.systemTemp;
      final tempFile = File(
        '${tempDir.path}/voice_reply_${DateTime.now().millisecondsSinceEpoch}.$format',
      );
      await tempFile.writeAsBytes(bytes);

      // 播放临时文件
      await _player.play(DeviceFileSource(tempFile.path));

      // 播放完成后清理
      _player.onPlayerComplete.listen((_) {
        tempFile.delete().catchError((_) {});
      });
    } catch (e) {
      print('[AudioService] 播放失败: $e');
      rethrow;
    }
  }

  /// 停止播放
  Future<void> stop() async {
    await _player.stop();
  }

  void dispose() {
    _player.dispose();
  }
}
