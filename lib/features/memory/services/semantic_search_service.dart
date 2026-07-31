import 'package:sqflite/sqflite.dart';
import '../models/memory_search_result.dart';
import '../repositories/embedding_repository.dart';
import 'embedding_service.dart';
import 'vector_search_service.dart';
import '../utils/vector_utils.dart';
import '../models/embedding_model.dart';
import '/../core/debug/debug_logger.dart';

class SemanticSearchService {
  final EmbeddingService _embeddingService;
  final VectorSearchService _legacyService;
  final EmbeddingRepository _embeddingRepository;
  final Database _database;

  SemanticSearchService({
    required EmbeddingService embeddingService,
    required VectorSearchService legacyService,
    required EmbeddingRepository embeddingRepository,
    required Database database,
  }) : _embeddingService = embeddingService,
       _legacyService = legacyService,
       _embeddingRepository = embeddingRepository,
       _database = database;

  Future<List<MemorySearchResult>> search(
    String query, {
    int limit = 10,
    List<String>? sourceTypes,
    double minSimilarity = 0.0,
  }) async {
    if (query.trim().isEmpty) return [];

    final queryVector = await _embeddingService.getEmbeddingVector(query);
    if (queryVector.isEmpty) return [];

    final queryBlob = vectorToBlob(queryVector);

    DebugLogger().logMemory(
      '🔍 Поиск через старый движок (in-memory): limit=$limit',
      level: LogLevel.debug,
    );

    List<EmbeddingModel> results = [];
    try {
      results = await _legacyService.search(queryBlob, limit: limit);
    } catch (e) {
      DebugLogger().logMemory('❌ Ошибка при поиске: $e', level: LogLevel.error);
      return [];
    }

    // Обогащаем результаты
    final enrichedResults = <MemorySearchResult>[];
    for (final result in results) {
      if (sourceTypes != null && !sourceTypes.contains(result.sourceType)) {
        continue;
      }
      final enriched = await _enrichResult(result);
      if (enriched != null) {
        enrichedResults.add(enriched);
      }
    }

    DebugLogger().logMemory(
      '✅ Найдено результатов: ${enrichedResults.length}',
      level: LogLevel.info,
    );

    return enrichedResults;
  }

  Future<MemorySearchResult?> _enrichResult(EmbeddingModel result) async {
    try {
      String title = '';
      String? preview;

      switch (result.sourceType) {
        case 'receipt':
          final receipt = await _database.query(
            'receipts',
            where: 'id = ?',
            whereArgs: [result.sourceId],
            limit: 1,
          );
          if (receipt.isNotEmpty) {
            title = receipt.first['shop'] as String? ?? 'Чек';
            final amount = receipt.first['amount'] as double? ?? 0;
            preview =
                '${receipt.first['date']} — ${amount.toStringAsFixed(2)} ₽';
          }
          break;

        case 'memory_note':
          final note = await _database.query(
            'memory_notes',
            where: 'id = ?',
            whereArgs: [result.sourceId],
            limit: 1,
          );
          if (note.isNotEmpty) {
            title = note.first['title'] as String? ?? 'Заметка';
            preview = (note.first['content'] as String? ?? '').substring(
              0,
              100,
            );
          }
          break;

        default:
          title = result.sourceType;
          preview = result.content.substring(
            0,
            result.content.length > 100 ? 100 : result.content.length,
          );
      }

      return MemorySearchResult(
        id: result.id,
        sourceType: result.sourceType,
        sourceId: result.sourceId,
        content: result.content,
        title: title,
        preview: preview,
        similarity: 0.0, // Заглушка, реальное сходство хранится отдельно
        metadata: result.metadata,
      );
    } catch (_) {
      return null;
    }
  }
}
