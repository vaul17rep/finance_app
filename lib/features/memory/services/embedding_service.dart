import 'dart:typed_data';
import 'package:finance_app/data/services/openrouter_service.dart';
import 'package:finance_app/features/memory/utils/vector_utils.dart';

class EmbeddingService {
  final OpenRouterService openRouterService;

  EmbeddingService(this.openRouterService);

  /// Получить Uint8List (BLOB) для текста.
  Future<Uint8List> getEmbeddingBlob(String text, {String? model}) async {
    final vector = await openRouterService.getEmbedding(text, model: model);
    return vectorToBlob(vector);
  }

  /// Получить список double для текста.
  Future<List<double>> getEmbeddingVector(String text, {String? model}) async {
    return await openRouterService.getEmbedding(text, model: model);
  }
}
