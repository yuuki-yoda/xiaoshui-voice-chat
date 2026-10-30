/// 后端 API 配置
class ApiConfig {
  // 你的服务器地址，改成实际的 IP 或域名
  // Android 模拟器用 10.0.2.2 访问宿主机
  // Android 真机用服务器公网 IP
  static const String baseUrl = 'http://127.0.0.1:3099';

  // API 路径
  static const String chatPath = '/api/chat';
  static const String chatTextPath = '/api/chat/text';
  static const String healthPath = '/api/health';

  // 请求超时（毫秒）
  static const int timeoutMs = 30000;
}
