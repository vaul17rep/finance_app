/// Сервис для создания эмбеддингов через OpenRouter.
/// Отвечает за валидацию текста (минимальная длина 10 символов),
/// повторные попытки при ошибках (retry до 3 раз с exponential backoff),
/// и обработку ошибки 402 (недостаточно средств) без повторных попыток.
library;

import 'dart:typed_data';
import '/data/services/openrouter_service.dart';
import '/features/memory/utils/vector_utils.dart';
import '/core/debug/debug_logger.dart';

class EmbeddingService {
  final OpenRouterService openRouterService;

  EmbeddingService(this.openRouterService);

  /// Получить Uint8List (BLOB) для текста с retry-логикой.
  Future<Uint8List> getEmbeddingBlob(String text, {String? model}) async {
    final trimmedText = text.trim();
    // Валидация: минимальная длина 10 символов
    if (trimmedText.isEmpty) {
      throw Exception('Пустой текст не может быть индексирован');
    }
    if (trimmedText.length < 10) {
      throw Exception(
        'Текст слишком короткий (${trimmedText.length} символов, минимум 10) для создания эмбеддинга',
      );
    }

    DebugLogger().logMemory(
      'Создание embedding: длина текста=${trimmedText.length}, модель=${model ?? "default"}',
      level: LogLevel.debug,
    );

    // Retry-логика: до 3 попыток с экспоненциальной задержкой
    int attempt = 0;
    const maxAttempts = 3;
    int delayMs = 1000; // 1 секунда, затем 2, затем 4

    while (true) {
      try {
        final vector = await openRouterService.getEmbedding(
          trimmedText,
          model: model,
        );
        final blob = vectorToBlob(vector);
        DebugLogger().logMemory(
          'Embedding готов: элементов=${vector.length}, blob=${blob.length} байт',
          level: LogLevel.debug,
        );
        return blob;
      } catch (e) {
        attempt++;
        // Если это ошибка 402 (недостаточно средств), не повторяем
        if (e.toString().contains('402') ||
            e.toString().contains('insufficient_balance')) {
          DebugLogger().logMemory(
            'Ошибка 402: недостаточно средств для API-запроса',
            level: LogLevel.error,
            error: e,
          );
          rethrow;
        }
        // Если это ошибка, которую можно повторить (429, тайм-аут, 5xx)
        if (attempt >= maxAttempts) {
          DebugLogger().logMemory(
            'Превышено число попыток ($maxAttempts) для создания эмбеддинга',
            level: LogLevel.error,
            error: e,
          );
          rethrow;
        }
        DebugLogger().logMemory(
          'Попытка $attempt/$maxAttempts не удалась, повтор через ${delayMs}мс: $e',
          level: LogLevel.warning,
        );
        await Future.delayed(Duration(milliseconds: delayMs));
        delayMs *= 2; // экспоненциальный рост
      }
    }
  }

  /// Получить список double для текста (использует ту же логику).
  Future<List<double>> getEmbeddingVector(String text, {String? model}) async {
    final blob = await getEmbeddingBlob(text, model: model);
    return blobToVector(blob);
  }
}
