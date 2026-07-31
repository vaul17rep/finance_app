import 'package:finance_app/features/memory/models/embedding_model.dart';
import 'package:finance_app/features/memory/repositories/embedding_repository.dart';
import 'package:finance_app/core/debug/debug_logger.dart';

/// Сервис для миграции данных из старой таблицы embeddings в новую embeddings_vec.
class MemoryMigrationService {
  final EmbeddingRepository embeddingRepository;

  MemoryMigrationService(this.embeddingRepository);

  /// Выполняет миграцию данных.
  /// Возвращает количество скопированных записей.
  Future<int> migrate() async {
    DebugLogger().logMemory('Начало миграции данных в новую таблицу');

    // Проверяем, есть ли уже данные в новой таблице
    final existingCount = await embeddingRepository.db.countEmbeddingsVec();
    if (existingCount > 0) {
      DebugLogger().logMemory(
        'В новой таблице уже есть $existingCount записей, пропускаем миграцию',
      );
      return 0;
    }

    // Загружаем все старые эмбеддинги
    final oldEmbeddings = await embeddingRepository.db.getAllEmbeddings();
    DebugLogger().logMemory('Найдено старых записей: ${oldEmbeddings.length}');

    if (oldEmbeddings.isEmpty) return 0;

    // Используем пакетную вставку с синхронизацией индекса
    await embeddingRepository.db.insertEmbeddingVecBatch(oldEmbeddings);

    DebugLogger().logMemory(
      'Миграция завершена: скопировано ${oldEmbeddings.length} записей',
    );
    return oldEmbeddings.length;
  }
}
