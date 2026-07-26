import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  static bool limitAccountNameLength = true;
  static const int maxAccountNameLength = 40;
  static bool autoIndexingEnabled = true; // по умолчанию включено
  static String embeddingModel = 'openai/text-embedding-3-small';
  static int embeddingVersion = 1;
  static bool developerMode = true; // НОВОЕ поле, по умолчанию включен

  static const String _keyObsidianVaultPath = 'obsidian_vault_path';

  // Получить сохранённый путь Vault Obsidian
  static Future<String?> getObsidianVaultPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyObsidianVaultPath);
  }

  // Сохранить путь Vault Obsidian
  static Future<void> setObsidianVaultPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyObsidianVaultPath, path);
  }

  // Удалить путь Vault Obsidian
  static Future<void> removeObsidianVaultPath() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyObsidianVaultPath);
  }
}
