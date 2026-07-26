import 'dart:typed_data';
import 'package:finance_app/data/services/openrouter_service.dart';
import 'package:finance_app/features/memory/utils/vector_utils.dart';
import 'package:finance_app/core/debug/debug_logger.dart';

class EmbeddingService {
  final OpenRouterService openRouterService;

  EmbeddingService(this.openRouterService);

  /// Получить Uint8List (BLOB) для текста.
  Future<Uint8List> getEmbeddingBlob(String text, {String? model}) async {
    DebugLogger().logBackground(
      'Создание embedding: длина текста=${text.length}, модель=${model ?? "default"}',
      level: LogLevel.debug,
    );

    final vector = await openRouterService.getEmbedding(text, model: model);

    final blob = vectorToBlob(vector);

    DebugLogger().logBackground(
      'Embedding готов: элементов=${vector.length}, blob=${blob.length} байт',
      level: LogLevel.debug,
    );

    return blob;
  }

  /// Получить список double для текста.
  Future<List<double>> getEmbeddingVector(String text, {String? model}) async {
    return await openRouterService.getEmbedding(text, model: model);
  }
}
