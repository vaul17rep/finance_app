import 'memory_chunk.dart';

class MemorySearchResult {
  final MemoryChunk chunk;
  final double score;

  const MemorySearchResult({required this.chunk, required this.score});
}
