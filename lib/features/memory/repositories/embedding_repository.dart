import 'package:finance_app/data/database/memory_database.dart';
import 'package:finance_app/features/memory/models/embedding_model.dart';

class EmbeddingRepository {
  final MemoryDatabase db;

  EmbeddingRepository(this.db);

  Future<void> save(EmbeddingModel embedding) async {
    final existing = await db.getEmbeddingBySource(
      embedding.sourceType,
      embedding.sourceId,
    );
    if (existing != null) {
      // Если изменился sourceUpdatedAt, обновляем
      if (embedding.sourceUpdatedAt.isAfter(existing.sourceUpdatedAt) ||
          embedding.embeddingUpdatedAt.isAfter(existing.embeddingUpdatedAt)) {
        await db.updateEmbedding(embedding);
      }
    } else {
      await db.insertEmbedding(embedding);
    }
  }

  Future<void> deleteBySource(String sourceType, String sourceId) async {
    await db.deleteEmbeddingsBySource(sourceType, sourceId);
  }

  Future<List<EmbeddingModel>> findAll() async {
    return await db.getAllEmbeddings();
  }

  Future<EmbeddingModel?> findBySource(
    String sourceType,
    String sourceId,
  ) async {
    return await db.getEmbeddingBySource(sourceType, sourceId);
  }

  Future<int> countIndexedSources() async {
    return await db.countIndexedSources();
  }

  // Получить все эмбеддинги для поиска (можно оптимизировать, если таблица большая)
  // Для поиска загружаем все векторы в память.
  Future<List<EmbeddingModel>> findAllForSearch() async {
    return await db.getAllEmbeddings();
  }

  // Удалить все записи (для полной переиндексации)
  Future<void> deleteAll() async {
    final db = await MemoryDatabase.instance.database;
    await db.delete('embeddings');
  }
}
