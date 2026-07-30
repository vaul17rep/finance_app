import 'dart:typed_data';
import '../models/embedding_model.dart';

/// Абстракция для векторного поиска
abstract class VectorSearchService {
  /// Поиск похожих векторов
  Future<List<EmbeddingModel>> search(Uint8List queryVector, {int limit = 10});

  /// Сохранение эмбеддинга
  Future<void> save(EmbeddingModel embedding);

  /// Найти эмбеддинг по источнику
  /// Найти эмбеддинг по источнику
  Future<EmbeddingModel?> findBySource(String sourceType, String sourceId);

  /// Найти все эмбеддинги по источнику (для документов с чанками)
  Future<List<EmbeddingModel>> findAllBySourceId(
    String sourceType,
    String sourceId,
  );

  /// Удалить все эмбеддинги источника
  Future<void> deleteBySource(String sourceType, String sourceId);

  /// Удалить все эмбеддинги
  Future<void> deleteAll();

  /// Получить все эмбеддинги
  Future<List<EmbeddingModel>> findAll();

  // ===== Новые методы для поддержки миграции =====

  /// Подсчёт записей по типу источника
  Future<int> countBySourceType(String sourceType);

  /// Подсчёт записей с указанным migrationId
  Future<int> countByMigrationId(String migrationId);

  /// Удаление записей с указанным migrationId
  Future<void> deleteByMigrationId(String migrationId);

  /// Очистка поля migrationId у записей
  Future<void> clearMigrationId(String migrationId);

  /// Удаление всех записей по типу источника
  Future<void> deleteBySourceType(String sourceType);
}
