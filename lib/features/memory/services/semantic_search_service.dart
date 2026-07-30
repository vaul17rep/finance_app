import 'package:sqflite/sqflite.dart';
import '../models/memory_search_result.dart';
import '../repositories/embedding_repository.dart';
import 'embedding_service.dart';
import 'vector_search_service.dart';
import '../utils/vector_utils.dart';
import '../models/embedding_model.dart';

class SemanticSearchService {
  final EmbeddingService _embeddingService;
  final VectorSearchService _vectorSearchService;
  final EmbeddingRepository _embeddingRepository;
  final Database _database;

  SemanticSearchService({
    required EmbeddingService embeddingService,
    required VectorSearchService vectorSearchService,
    required EmbeddingRepository embeddingRepository,
    required Database database,
  }) : _embeddingService = embeddingService,
       _vectorSearchService = vectorSearchService,
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

    // Преобразуем List<double> в Uint8List через vectorToBlob
    final queryBlob = vectorToBlob(queryVector);

    final results = await _vectorSearchService.search(queryBlob, limit: limit);

    // Обогащаем результаты
    final enrichedResults = <MemorySearchResult>[];
    for (final result in results) {
      // Фильтрация по sourceTypes
      if (sourceTypes != null && !sourceTypes.contains(result.sourceType)) {
        continue;
      }
      // Фильтрация по minSimilarity будет выполняться внутри VectorSearchService
      final enriched = await _enrichResult(result);
      if (enriched != null) {
        enrichedResults.add(enriched);
      }
    }

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

      // Преобразуем EmbeddingModel в MemorySearchResult
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
