class DataNormalizerService {
  // ============================================
  // Нормализация названия магазина
  // ============================================

  static String normalizeStore(String value) {
    if (value.trim().isEmpty) {
      return "";
    }

    var clean = _cleanText(value);

    // Убираем адрес после запятой
    clean = clean.split(',').first.trim();

    final lower = clean.toLowerCase();

    // ==========================
    // Известные магазины
    // ==========================

    if (lower.contains("ярче") || lower.contains("камелот")) {
      return "Ярче!";
    }

    if (lower.contains("пятер")) {
      return "Пятёрочка";
    }

    if (lower.contains("магнит")) {
      return "Магнит";
    }

    if (lower.contains("лента")) {
      return "Лента";
    }

    if (lower.contains("розница к-1")) {
      return "Мария-Ра";
    }

    // Если магазин неизвестный,
    // возвращаем очищенный вариант

    return clean;
  }

  // ============================================
  // Нормализация товара
  // ============================================

  static String normalizeProduct(String value) {
    if (value.trim().isEmpty) {
      return "";
    }

    var clean = _cleanText(value);

    // Проверяем полностью ли капсом

    if (clean == clean.toUpperCase()) {
      clean = clean.toLowerCase();

      return _capitalizeWords(clean);
    }

    return clean;
  }

  // ============================================
  // Общая очистка текста
  // ============================================

  static String _cleanText(String value) {
    var text = value.trim();

    // Убираем двойные пробелы

    text = text.replaceAll(RegExp(r'\s+'), ' ');

    return text;
  }

  // ============================================
  // Первые буквы слов заглавные
  // ============================================

  static String _capitalizeWords(String value) {
    return value
        .split(' ')
        .map((word) {
          if (word.isEmpty) {
            return word;
          }

          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }
}
