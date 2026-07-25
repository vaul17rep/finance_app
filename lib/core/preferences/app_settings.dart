class AppSettings {
  static bool limitAccountNameLength = true;
  static const int maxAccountNameLength = 40;
  static bool autoIndexingEnabled = true; // по умолчанию включено
  static String embeddingModel = 'openai/text-embedding-3-small';
  static int embeddingVersion = 1;

  // Методы для сохранения/загрузки из SharedPreferences можно добавить позже
}
