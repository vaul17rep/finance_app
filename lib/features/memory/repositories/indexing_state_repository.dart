/// Репозиторий для работы с состоянием индексации в таблице indexing_state.
/// Отвечает за сохранение, загрузку и удаление состояния.
/// Находится в модуле memory, использует MemoryDatabase.
library;

import 'package:finance_app/data/database/memory_database.dart';
import 'package:finance_app/features/memory/models/indexing_state.dart';

class IndexingStateRepository {
  final MemoryDatabase _db;

  IndexingStateRepository(this._db);

  /// Сохранить состояние (вставка или обновление по id)
  Future<void> save(IndexingState state) async {
    final db = await _db.database;
    final existing = await load(state.sourceType);
    if (existing != null) {
      await db.update(
        'indexing_state',
        state.toMap(),
        where: 'id = ?',
        whereArgs: [state.id],
      );
    } else {
      await db.insert('indexing_state', state.toMap());
    }
  }

  /// Загрузить состояние по типу источника (например, 'obsidian')
  Future<IndexingState?> load(String sourceType) async {
    final db = await _db.database;
    final result = await db.query(
      'indexing_state',
      where: 'sourceType = ?',
      whereArgs: [sourceType],
    );
    if (result.isEmpty) return null;
    return IndexingState.fromMap(result.first);
  }

  /// Удалить состояние по типу источника
  Future<void> delete(String sourceType) async {
    final db = await _db.database;
    await db.delete(
      'indexing_state',
      where: 'sourceType = ?',
      whereArgs: [sourceType],
    );
  }

  /// Проверить, существует ли таблица indexing_state
  Future<bool> tableExists() async {
    final db = await _db.database;
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='indexing_state'",
    );
    return result.isNotEmpty;
  }
}
