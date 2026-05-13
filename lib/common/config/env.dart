/// Host del API (sin `/api/v1` y sin barra final).
///
/// Producción (Azure): valor por defecto abajo.
/// Local: `flutter run --dart-define=API_BASE=http://127.0.0.1:5119`
/// Red LAN: `flutter run --dart-define=API_BASE=http://192.168.x.x:5119`
class Env {
  static const String _apiBaseRaw = String.fromEnvironment(
    'API_BASE',
    defaultValue:
        'https://livriabackend-g5afdubmcxfacjbe.chilecentral-01.azurewebsites.net',
  );

  /// Quita espacios y barras finales para no generar `...net//api/v1` si alguien pone barra final.
  static String get apiBase {
    var s = _apiBaseRaw.trim();
    while (s.endsWith('/')) {
      s = s.substring(0, s.length - 1);
    }
    return s.isEmpty
        ? 'https://livriabackend-g5afdubmcxfacjbe.chilecentral-01.azurewebsites.net'
        : s;
  }
}
