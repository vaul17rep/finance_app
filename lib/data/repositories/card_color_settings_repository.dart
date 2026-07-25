// lib/data/repositories/card_color_settings_repository.dart
import '../../models/card_color_settings.dart';
import '../database/database_helper.dart';

class CardColorSettingsRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<CardColorSettings> getSettings() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'card_color_settings',
      where: 'id = ?',
      whereArgs: ['default'],
    );
    if (maps.isNotEmpty) {
      return CardColorSettings.fromMap(maps.first);
    } else {
      // Создаём запись с дефолтными значениями
      final defaultSettings = CardColorSettings.defaultSettings();
      await db.insert('card_color_settings', defaultSettings.toMap());
      return defaultSettings;
    }
  }

  Future<void> saveSettings(CardColorSettings settings) async {
    final db = await _dbHelper.database;
    await db.update(
      'card_color_settings',
      settings.toMap(),
      where: 'id = ?',
      whereArgs: ['default'],
    );
  }
}
