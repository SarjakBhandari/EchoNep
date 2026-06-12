import 'dart:io';

class ApiConfig {
  ApiConfig._();

  static String get baseUrl {
    if (Platform.isAndroid) {
      return _isAndroidEmulator
          ? 'http://10.0.2.2:8000'
          : 'http://192.168.137.1:8000';
    }

    if (Platform.isIOS) {
      return 'http://localhost:8000';
    }

    return 'http://192.168.137.1:8000';
  }

  static bool get _isAndroidEmulator {
    final operatingSystemVersion = Platform.operatingSystemVersion
        .toLowerCase();
    return operatingSystemVersion.contains('sdk') ||
        operatingSystemVersion.contains('emulator') ||
        operatingSystemVersion.contains('generic') ||
        operatingSystemVersion.contains('x86') ||
        operatingSystemVersion.contains('goldfish') ||
        operatingSystemVersion.contains('ranchu');
  }

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration asrReceiveTimeout = Duration(seconds: 180);
}
