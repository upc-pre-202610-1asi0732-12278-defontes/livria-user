import '../config/env.dart';

class Constants {
  /// Misma base que el resto de datasources (`Env.apiBase` + `/api/v1`).
  /// Local: `flutter run --dart-define=API_BASE=http://127.0.0.1:5119`
  static String get apiBaseUrl => '${Env.apiBase}/api/v1';
}
