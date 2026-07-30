import 'package:package_info_plus/package_info_plus.dart';

class DiagnosticVersion {
  static const String version = '1.0.0';
  static const String date = '2026-07-30';

  static Future<String> getAppVersion() async {
    // Используем package_info_plus
    // Если пакет ещё не добавлен, вернём 'unknown'
    try {
      final info = await PackageInfo.fromPlatform();
      return '${info.appName} ${info.version} (build ${info.buildNumber})';
    } catch (_) {
      return 'LifeOS unknown';
    }
  }

  static const String embeddingModel = 'openai/text-embedding-3-small';
  static const int dbSchemaVersion = 1;
}
