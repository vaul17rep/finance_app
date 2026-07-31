import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  static bool limitAccountNameLength = true;
  static const int maxAccountNameLength = 40;
  static bool autoIndexingEnabled = true;
  static String embeddingModel = 'openai/text-embedding-3-small';
  static int embeddingVersion = 1;
  static bool developerMode = true;

  static const String _keyObsidianVaultPath = 'obsidian_vault_path';
  static const String _keyUseSqliteVec = 'use_sqlite_vec';

  static bool _useSqliteVec = false;

  static bool get useSqliteVec => _useSqliteVec;

  static Future<void> setUseSqliteVec(bool value) async {
    _useSqliteVec = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyUseSqliteVec, value);
  }

  static Future<void> loadUseSqliteVec() async {
    final prefs = await SharedPreferences.getInstance();
    _useSqliteVec = prefs.getBool(_keyUseSqliteVec) ?? false;
  }

  // --- Obsidian Vault ---

  static Future<String?> getObsidianVaultPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyObsidianVaultPath);
  }

  static Future<void> setObsidianVaultPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyObsidianVaultPath, path);
  }

  static Future<void> removeObsidianVaultPath() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyObsidianVaultPath);
  }
}
