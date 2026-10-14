import 'dart:io';

class AppConfig {
  static const String appName = 'SecondLife Seller';

  /// Default API Origin (can be overridden with --dart-define=API_BASE_URL=...)
  static String get baseUrl {
    const definedUrl = String.fromEnvironment('API_BASE_URL');
    if (definedUrl.isNotEmpty) {
      return definedUrl;
    }

    // Default based on platform for local development
    if (Platform.isAndroid) {
      // 10.0.2.2 is the special alias to host localhost in Android Emulator
      return 'http://10.0.2.2:8080';
    } else if (Platform.isIOS || Platform.isMacOS) {
      return 'http://localhost:8080';
    }
    // Web / Windows / other
    return 'http://localhost:8080';
  }

  /// WebSocket URL for STOMP over SockJS
  static String get wsUrl => '$baseUrl/ws';

  /// Connection timeout settings
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);
}
