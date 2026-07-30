import '../models/memory_chunk.dart';

class ChunkingService {
  final int chunkSize;
  final int overlap;

  ChunkingService({this.chunkSize = 512, this.overlap = 64})
    : assert(chunkSize > overlap, 'chunkSize должен быть больше overlap');

  /// Разбивает текст на список MemoryChunk
  Future<List<MemoryChunk>> chunk(String text) async {
    if (text.isEmpty) return [];

    final chunks = <MemoryChunk>[];
    final words = text.split(' ');
    final totalWords = words.length;

    if (totalWords <= chunkSize) {
      chunks.add(MemoryChunk(id: 'chunk_0', content: text, index: 0));
      return chunks;
    }

    int start = 0;
    int chunkIndex = 0;

    while (start < totalWords) {
      int end = (start + chunkSize).clamp(0, totalWords);

      // Если это не последний чанк, стараемся закончить на границе предложения
      if (end < totalWords) {
        // Ищем точку, вопросительный или восклицательный знак в пределах последних 50 слов
        final searchStart = (end - 50).clamp(0, totalWords);
        final segment = words.sublist(searchStart, end).join(' ');
        final punctIndex = _findSentenceBoundary(segment);

        if (punctIndex != -1) {
          final wordsInSegment = segment
              .substring(0, punctIndex + 1)
              .split(' ')
              .length;
          end = searchStart + wordsInSegment;
        }
      }

      final chunkText = words.sublist(start, end).join(' ');
      if (chunkText.trim().isNotEmpty) {
        chunks.add(
          MemoryChunk(
            id: 'chunk_${chunkIndex}_${DateTime.now().millisecondsSinceEpoch}',
            content: chunkText.trim(),
            index: chunkIndex,
          ),
        );
        chunkIndex++;
      }

      // Следующий старт с учётом overlap
      start = end - overlap;
      if (start < 0) start = 0;

      // Защита от бесконечного цикла
      if (start >= end) break;
    }

    return chunks;
  }

  /// Разбивает текст на чанки с метаданными источника
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
