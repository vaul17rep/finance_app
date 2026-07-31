import 'dart:typed_data';
import 'dart:math';
import 'package:finance_app/features/memory/models/embedding_model.dart';
import 'package:finance_app/features/memory/repositories/embedding_repository.dart';
import 'package:finance_app/features/memory/utils/vector_utils.dart';
import 'vector_search_service.dart';
import 'package:finance_app/core/debug/debug_logger.dart';

/// Реализация VectorSearchService с использованием sqlite-vec.
/// Поиск выполняется на стороне БД через vec_distance_cosine.
class SqliteVecSearchService implements VectorSearchService {
  final EmbeddingRepository embeddingRepository;
  bool _initialized = false;
  bool _vecAvailable = false;

  SqliteVecSearchService(this.embeddingRepository) {
    _init();
  }

  Future<void> _init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final db = await embeddingRepository.db.database;
      // Проверяем доступность функции vec_distance_cosine
      await db.rawQuery('SELECT vec_distance_cosine(X"0000", X"0000") LIMIT 1');
      _vecAvailable = true;
      DebugLogger().logMemory(
        '✅ sqlite-vec доступен, используем новый движок поиска',
        level: LogLevel.info,
      );
    } catch (e) {
      _vecAvailable = false;
      DebugLogger().logMemory(
        '⚠️ sqlite-vec недоступен: $e. Будет использован fallback.',
        level: LogLevel.warning,
      );
    }
  }

  bool get isVecAvailable => _vecAvailable;

  @override
  Future<EmbeddingModel?> findBySource(
    String sourceType,
    String sourceId,
  ) async {
    return await embeddingRepository.db.getEmbeddingVecBySource(
      sourceType,
      sourceId,
    );
  }

  @override
  Future<List<EmbeddingModel>> findAllBySourceId(
    String sourceType,
    String sourceId,
  ) async {
    final all = await embeddingRepository.db.getAllEmbeddingsVec();
    return all
        .where((e) => e.sourceType == sourceType && e.sourceId == sourceId)
        .toList();
  }

  @override
  Future<List<EmbeddingModel>> search(
    Uint8List queryVector, {
    int limit = 10,
  }) async {
    if (!_vecAvailable) {
      DebugLogger().logMemory(
        '⚠️ sqlite-vec недоступен, поиск не выполняется',
        level: LogLevel.warning,
      );
      return [];
    }

    DebugLogger().logMemory(
      '🔍 Поиск через sqlite-vec: limit=$limit',
      level: LogLevel.debug,
    );

    try {
      final results = await embeddingRepository.db.searchVec(
        queryVector,
        limit: limit,
      );
      DebugLogger().logMemory(
        '✅ Найдено результатов: ${results.length}',
        level: LogLevel.info,
      );
      return results;
    } catch (e, stack) {
      DebugLogger().logMemory(
        '❌ Ошибка при поиске через sqlite-vec: $e',
        level: LogLevel.error,
        error: e,
        stackTrace: stack,
      );
      return [];
    }
  }

  @override
  Future<void> save(EmbeddingModel embedding) async {
    await embeddingRepository.db.insertEmbeddingVec(embedding);
  }

  @override
  Future<void> deleteBySource(String sourceType, String sourceId) async {
    await embeddingRepository.db.deleteEmbeddingsVecBySource(
      sourceType,
      sourceId,
    );
  }

  @override
  Future<void> deleteAll() async {
    final db = await embeddingRepository.db.database;
    await db.delete('embeddings_vec');
  }

  @override
  Future<List<EmbeddingModel>> findAll() async {
    return await embeddingRepository.db.getAllEmbeddingsVec();
  }

  // --- Методы для поддержки миграции ---

  @override
  Future<int> countBySourceType(String sourceType) async {
    final all = await embeddingRepository.db.getAllEmbeddingsVec();
    return all.where((e) => e.sourceType == sourceType).length;
  }

  @override
  Future<int> countByMigrationId(String migrationId) async {
    final all = await embeddingRepository.db.getAllEmbeddingsVec();
    return all.where((e) => e.metadata['migrationId'] == migrationId).length;
  }

  @override
  Future<void> deleteByMigrationId(String migrationId) async {
    final all = await embeddingRepository.db.getAllEmbeddingsVec();
    final toDelete = all
        .where((e) => e.metadata['migrationId'] == migrationId)
        .toList();
    for (final emb in toDelete) {
      await embeddingRepository.db.deleteEmbeddingsVecBySource(
        emb.sourceType,
        emb.sourceId,
      );
    }
    DebugLogger().logMemory(
      'Удалено ${toDelete.length} записей с migrationId=$migrationId из новой таблицы',
      level: LogLevel.info,
    );
  }

  @override
  Future<void> clearMigrationId(String migrationId) async {
    final all = await embeddingRepository.db.getAllEmbeddingsVec();
    final toUpdate = all
        .where((e) => e.metadata['migrationId'] == migrationId)
        .toList();

    for (final emb in toUpdate) {
      final newMetadata = Map<String, dynamic>.from(emb.metadata);
      newMetadata.remove('migrationId');
      final updated = emb.copyWith(
        metadata: newMetadata,
        updatedAt: DateTime.now(),
      );
      await embeddingRepository.db.updateEmbeddingVec(updated);
    }

    DebugLogger().logMemory(
      'Очищено поле migrationId у ${toUpdate.length} записей в новой таблице',
      level: LogLevel.info,
    );
  }

  @override
  Future<void> deleteBySourceType(String sourceType) async {
    final all = await embeddingRepository.db.getAllEmbeddingsVec();
    final toDelete = all.where((e) => e.sourceType == sourceType).toList();
    for (final emb in toDelete) {
      await embeddingRepository.db.deleteEmbeddingsVecBySource(
        emb.sourceType,
        emb.sourceId,
      );
    }
    DebugLogger().logMemory(
      'Удалено ${toDelete.length} записей с sourceType=$sourceType из новой таблицы',
      level: LogLevel.info,
    );
  }
}
