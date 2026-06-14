import 'package:firebase_analytics/firebase_analytics.dart';

class LivriaAnalytics {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Habilitar la recolección de datos
  static Future<void> logEvent(String name, Map<String, Object>? parameters) async {
    await _analytics.logEvent(name: name, parameters: parameters);
  }
}

class AnalyticsContext {
  static bool viaRecommendation = false;

  static void markFromRecommendation() => viaRecommendation = true;
  static void reset() => viaRecommendation = false;
}