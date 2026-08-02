import 'dart:typed_data';
import 'dart:math';
import '/features/memory/models/embedding_model.dart';
import '/features/memory/repositories/embedding_repository.dart';
import '/features/memory/utils/vector_utils.dart';
import 'vector_search_service.dart';
import '/core/debug/debug_logger.dart';
import 'dart:async';

class SqliteVectorSearchService implements VectorSearchService {
  final EmbeddingRepository embeddingRepository;
  bool _initialized = false;

  SqliteVectorSearchService(this.embeddingRepository) {
    _init();
  }

  Future<void> _init() async {
    if (_initialized) return;
    _initialized = true;
    await _cleanCorruptVectors();
  }

  /// Очищает битые BLOB-векторы из базы данных.
  ///
  /// Векторы считаются битыми, если их размер в байтах не кратен 4
  /// (требование Float32Array для правильного выравнивания).
  Future<void> _cleanCorruptVectors() async {
    DebugLogger().logMemory('Начало очистки битых BLOB-векторов');

    try {
      final embeddings = await embeddingRepository.findAll();
      int deletedCount = 0;

      for (final emb in embeddings) {
        final size = emb.vector.lengthInBytes;
        if (size % 4 != 0) {
          DebugLogger().logMemory(
            'Удалён битый embedding: id=${emb.id}, source=${emb.sourceType}:${emb.sourceId}, размер=$size байт',
            level: LogLevel.warning,
          );
          await embeddingRepository.deleteBySource(
            emb.sourceType,
            emb.sourceId,
          );
          deletedCount++;
        }
      }

      if (deletedCount > 0) {
        DebugLogger().logMemory(
          'Очистка завершена: удалено $deletedCount битых записей',
          level: LogLevel.info,
        );
      } else {
        DebugLogger().logMemory(
          'Очистка завершена: битых записей не найдено',
          level: LogLevel.debug,
        );
      }
    } catch (e, stack) {
      DebugLogger().logMemory(
        'Ошибка при очистке битых BLOB-векторов',
        level: LogLevel.error,
        error: e,
        stackTrace: stack,
      );
    }
  }

  @override
  Future<EmbeddingModel?> findBySource(
    String sourceType,
    String sourceId,
  ) async {
    return await embeddingRepository.findBySource(sourceType, sourceId);
  }

  @override
  Future<List<EmbeddingModel>> search(
    Uint8List queryVector, {
    int limit = 10,
  }) async {
    DebugLogger().logMemory(
      'Vector поиск начат: limit=$limit',
      level: LogLevel.debug,
    );

    final embeddings = await embeddingRepository.findAllForSearch();

    DebugLogger().logMemory(
      'В памяти найдено эмбеддингов: ${embeddings.length}',
      level: LogLevel.debug,
    );

    final query = blobToVector(queryVector);

    final scored = <_ScoredEmbedding>[];

    for (var emb in embeddings) {
      final size = emb.vector.lengthInBytes;

      DebugLogger().logMemory(
        'Проверка embedding: '
        'id=${emb.id}, '
        'source=${emb.sourceType}:${emb.sourceId}, '
        'размер=$size',
        level: LogLevel.debug,
      );

      if (size % 4 != 0) {
        DebugLogger().logMemory(
          'Обнаружен и удалён битый embedding: '
          'id=${emb.id}, '
          'размер=$size байт',
          level: LogLevel.warning,
        );
        // Асинхронно удаляем битую запись (не блокируем текущий поиск)
        unawaited(
          embeddingRepository
              .deleteBySource(emb.sourceType, emb.sourceId)
              .then(
                (_) => DebugLogger().logMemory(
                  'Битый embedding удалён: id=${emb.id}',
                  level: LogLevel.debug,
                ),
              )
              .catchError(
                (e) => DebugLogger().logMemory(
                  'Ошибка удаления битого embedding: $e',
                  level: LogLevel.error,
                ),
              ),
        );
        continue;
      }

      try {
        final vector = blobToVector(emb.vector);

        final similarity = cosineSimilarity(query, vector);
        DebugLogger().logMemory(
          'Сходство ${emb.sourceId} (${emb.metadata['chunkIndex'] ?? 0}): $similarity',
          level: LogLevel.debug,
        );

        scored.add(_ScoredEmbedding(emb, similarity));
      } catch (e, stack) {
        DebugLogger().logMemory(
          'Ошибка обработки embedding: '
          'id=${emb.id}, '
          'source=${emb.sourceType}:${emb.sourceId}, '
          'размер=${emb.vector.lengthInBytes}, '
          'ошибка=$e',
          level: LogLevel.error,
          error: e,
          stackTrace: stack,
        );
      }
    }

    scored.sort((a, b) => b.similarity.compareTo(a.similarity));

    // Группировка результатов по sourceId (документу)
    // Для каждого документа выбираем чанк с максимальной схожестью
    final groupedBySourceId = <String, _ScoredEmbedding>{};
    for (final scoredItem in scored) {
      final sourceId = scoredItem.embedding.sourceId;
      if (!groupedBySourceId.containsKey(sourceId)) {
        groupedBySourceId[sourceId] = scoredItem;
      } else if (scoredItem.similarity >
          groupedBySourceId[sourceId]!.similarity) {
        groupedBySourceId[sourceId] = scoredItem;
      }
    }

    final groupedResults = groupedBySourceId.values.toList();
    groupedResults.sort((a, b) => b.similarity.compareTo(a.similarity));

    final top = groupedResults.take(limit).map((s) => s.embedding).toList();

    DebugLogger().logMemory(
      'Vector поиск завершён: найдено ${scored.length} кандидатов, '
      'сгруппировано в ${groupedResults.length} документов, '
      'возвращено ${top.length}',
      level: LogLevel.info,
    );

    return top;
  }

  @override
  Future<void> save(EmbeddingModel embedding) async {
    await embeddingRepository.save(embedding);
  }

  @override
  Future<void> deleteBySource(String sourceType, String sourceId) async {
    await embeddingRepository.deleteBySource(sourceType, sourceId);
  }

  @override
  Future<void> deleteAll() async {
    await embeddingRepository.deleteAll();
  }

  @override
  Future<List<EmbeddingModel>> findAll() async {
    return await embeddingRepository.findAll();
  }

  // ===== Новые методы для поддержки миграции =====

  @override
  Future<int> countBySourceType(String sourceType) async {
    final all = await embeddingRepository.findAll();
    return all.where((e) => e.sourceType == sourceType).length;
  }

  @override
  Future<int> countByMigrationId(String migrationId) async {
    final all = await embeddingRepository.findAll();
    return all.where((e) => e.metadata['migrationId'] == migrationId).length;
  }

  @override
  Future<void> deleteByMigrationId(String migrationId) async {
    final all = await embeddingRepository.findAll();
    final toDelete = all
        .where((e) => e.metadata['migrationId'] == migrationId)
        .toList();
    for (final emb in toDelete) {
      await embeddingRepository.deleteBySource(emb.sourceType, emb.sourceId);
    }
    DebugLogger().logMemory(
      'Удалено ${toDelete.length} записей с migrationId=$migrationId',
      level: LogLevel.info,
    );
  }

  @override
  Future<void> clearMigrationId(String migrationId) async {
    // Получаем все записи с этим migrationId
    final all = await embeddingRepository.findAll();
    final toUpdate = all
        .where((e) => e.metadata['migrationId'] == migrationId)
        .toList();

    for (final emb in toUpdate) {
      // Создаём копию metadata без migrationId
      final newMetadata = Map<String, dynamic>.from(emb.metadata);
      newMetadata.remove('migrationId');

      // Обновляем запись
      final updated = emb.copyWith(
        metadata: newMetadata,
        updatedAt: DateTime.now(),
      );
      await embeddingRepository.save(updated);
    }

    DebugLogger().logMemory(
      'Очищено поле migrationId у ${toUpdate.length} записей',
      level: LogLevel.info,
    );
  }

  @override
  Future<void> deleteBySourceType(String sourceType) async {
    final all = await embeddingRepository.findAll();
    final toDelete = all.where((e) => e.sourceType == sourceType).toList();
    for (final emb in toDelete) {
      await embeddingRepository.deleteBySource(emb.sourceType, emb.sourceId);
    }
    DebugLogger().logMemory(
      'Удалено ${toDelete.length} записей с sourceType=$sourceType',
      level: LogLevel.info,
    );
  }

  @override
  Future<List<EmbeddingModel>> findAllBySourceId(
    String sourceType,
    String sourceId,
  ) async {
    final all = await embeddingRepository.findAll();
    return all
        .where((e) => e.sourceType == sourceType && e.sourceId == sourceId)
        .toList();
  }

  // ===== Вспомогательные методы =====

  double cosineSimilarity(List<double> a, List<double> b) {
    if (a.isEmpty || b.isEmpty || a.length != b.length) return 0.0;
    double dot = 0.0, normA = 0.0, normB = 0.0;
    for (int i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    if (normA == 0.0 || normB == 0.0) return 0.0;
    return dot / (sqrt(normA) * sqrt(normB));
  }
}

class _ScoredEmbedding {
  final EmbeddingModel embedding;
  final double similarity;

  _ScoredEmbedding(this.embedding, this.similarity);
}
