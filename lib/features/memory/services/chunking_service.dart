/// Сервис для разбивки текста на чанки (части) для индексации.
/// Использует символьную разбивку с порогом 8000 символов и перекрытием 200.
/// Старается заканчивать чанки на границе предложений для улучшения качества поиска.
library;

import '../models/memory_chunk.dart';

class ChunkingService {
  final int maxChunkChars;
  final int overlapChars;

  ChunkingService({this.maxChunkChars = 8000, this.overlapChars = 200})
    : assert(maxChunkChars > overlapChars);

  /// Разбивает текст на список MemoryChunk.
  Future<List<MemoryChunk>> chunk(String text) async {
    if (text.isEmpty) return [];

    final chunks = <MemoryChunk>[];
    final length = text.length;

    if (length <= maxChunkChars) {
      final chunkText = text.trim();
      if (chunkText.isNotEmpty) {
        chunks.add(
          MemoryChunk(
            id: 'chunk_0_${DateTime.now().millisecondsSinceEpoch}',
            content: chunkText,
            index: 0,
          ),
        );
      }
      return chunks;
    }

    int start = 0;
    int chunkIndex = 0;

    while (start < length) {
      int end = (start + maxChunkChars).clamp(0, length);

      // Если не конец текста, стараемся закончить на границе предложения
      if (end < length) {
        final searchStart = (end - 200).clamp(0, length);
        final segment = text.substring(searchStart, end);
        final punctIndex = _findSentenceBoundary(segment);
        if (punctIndex != -1) {
          end = searchStart + punctIndex + 1;
        }
      }

      final chunkText = text.substring(start, end).trim();
      if (chunkText.isNotEmpty) {
        chunks.add(
          MemoryChunk(
            id: 'chunk_${chunkIndex}_${DateTime.now().millisecondsSinceEpoch}',
            content: chunkText,
            index: chunkIndex,
          ),
        );
        chunkIndex++;
      }

      // Следующий старт с перекрытием
      start = end - overlapChars;
      if (start < 0) start = 0;
      if (start >= end) break;
    }

    return chunks;
  }

  /// Разбивает текст с метаданными источника.
  Future<List<MemoryChunk>> chunkWithSource({
    required String text,
    required String sourceType,
    required String sourceId,
    Map<String, dynamic>? metadata,
  }) async {
    final chunks = await chunk(text);
    return chunks
        .map(
          (chunk) => chunk.copyWith(
            sourceType: sourceType,
            sourceId: sourceId,
            metadata: metadata,
          ),
        )
        .toList();
  }

  int _findSentenceBoundary(String text) {
    final punctuation = ['.', '!', '?'];
    for (int i = text.length - 1; i >= 0; i--) {
      if (punctuation.contains(text[i])) {
        return i;
      }
    }
    return -1;
  }
}
