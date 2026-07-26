import 'package:finance_app/features/memory/models/embedding_model.dart';
import 'dart:typed_data';

abstract class VectorSearchService {
  /// Поиск по вектору запроса. Возвращает список EmbeddingModel, отсортированный по сходству (убывание).
  Future<List<EmbeddingModel>> search(Uint8List queryVector, {int limit = 10});

  /// Найти эмбеддинг по источнику.
  Future<EmbeddingModel?> findBySource(String sourceType, String sourceId);

  /// Сохранить или обновить эмбеддинг.
  Future<void> save(EmbeddingModel embedding);

  /// Удалить эмбеддинг по источнику.
  Future<void> deleteBySource(String sourceType, String sourceId);

  /// Удалить все эмбеддинги.
  Future<void> deleteAll();
  
/// Получить все эмбеддинги.
/// Используется для обслуживания индекса и отладки.
  Future<List<EmbeddingModel>> findAll();
}
