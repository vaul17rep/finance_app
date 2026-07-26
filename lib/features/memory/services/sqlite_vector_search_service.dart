import 'dart:typed_data';
import 'dart:math';
import 'package:finance_app/features/memory/models/embedding_model.dart';
import 'package:finance_app/features/memory/repositories/embedding_repository.dart';
import 'package:finance_app/features/memory/utils/vector_utils.dart';
import 'vector_search_service.dart';
import 'package:finance_app/core/debug/debug_logger.dart';

class SqliteVectorSearchService implements VectorSearchService {
  final EmbeddingRepository embeddingRepository;

  SqliteVectorSearchService(this.embeddingRepository);

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
          'Пропущен битый embedding: '
          'id=${emb.id}, '
          'размер=$size байт',
          level: LogLevel.warning,
        );
        continue;
      }

      try {
        final vector = blobToVector(emb.vector);

        final similarity = cosineSimilarity(query, vector);
        DebugLogger().logMemory(
          'Сходство ${emb.sourceId}: $similarity',
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

    final top = scored.take(limit).map((s) => s.embedding).toList();

    DebugLogger().logMemory(
      'Vector поиск завершён: возвращено ${top.length}',
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

  // Косинусное сходство двух векторов
  double cosineSimilarity(List<double> a, List<double> b) {
    if (a.isEmpty || b.isEmpty || a.length != b.length) return 0.0;
    double dot = 0.0, normA = 0.0, normB = 0.0;
    for (int i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    if (normA == 0.0 || normB == 0.0) return 0.0;
    // Исправлено: sqrt(normA) вместо normA.sqrt()
    return dot / (sqrt(normA) * sqrt(normB));
  }
}

class _ScoredEmbedding {
  final EmbeddingModel embedding;
  final double similarity;

  _ScoredEmbedding(this.embedding, this.similarity);
}
