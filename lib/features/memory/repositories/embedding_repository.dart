import 'package:finance_app/data/database/memory_database.dart';
import 'package:finance_app/features/memory/models/embedding_model.dart';

class EmbeddingRepository {
  final MemoryDatabase db;

  EmbeddingRepository(this.db);

  // --- Старая таблица embeddings ---

  Future<void> save(EmbeddingModel embedding) async {
    final existing = await db.getEmbeddingBySource(
      embedding.sourceType,
      embedding.sourceId,
    );
    if (existing != null) {
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

  Future<List<EmbeddingModel>> findAllForSearch() async {
    return await db.getAllEmbeddings();
  }

  Future<void> deleteAll() async {
    final db = await MemoryDatabase.instance.database;
    await db.delete('embeddings');
  }

  // --- Новая таблица embeddings_vec ---

  Future<void> saveVec(EmbeddingModel embedding) async {
    final existing = await db.getEmbeddingVecBySource(
      embedding.sourceType,
      embedding.sourceId,
    );
    if (existing != null) {
      if (embedding.sourceUpdatedAt.isAfter(existing.sourceUpdatedAt) ||
          embedding.embeddingUpdatedAt.isAfter(existing.embeddingUpdatedAt)) {
        await db.updateEmbeddingVec(embedding);
      }
    } else {
      await db.insertEmbeddingVec(embedding);
    }
  }

  Future<void> deleteVecBySource(String sourceType, String sourceId) async {
    await db.deleteEmbeddingsVecBySource(sourceType, sourceId);
  }

  Future<List<EmbeddingModel>> findAllVec() async {
    return await db.getAllEmbeddingsVec();
  }

  Future<EmbeddingModel?> findBySourceVec(
    String sourceType,
    String sourceId,
  ) async {
    return await db.getEmbeddingVecBySource(sourceType, sourceId);
  }

  Future<List<EmbeddingModel>> findAllVecForSearch() async {
    return await db.getAllEmbeddingsVec();
  }

  Future<int> countVec() async {
    return await db.countEmbeddingsVec();
  }

  Future<void> deleteAllVec() async {
    final db = await MemoryDatabase.instance.database;
    await db.delete('embeddings_vec');
  }
}
