import '../models/memory_chunk.dart';
import '../models/memory_search_result.dart';

class VectorSimilarityService {
  const VectorSimilarityService();

  double cosineSimilarity(List<double> vectorA, List<double> vectorB) {
    throw UnimplementedError();
  }

  double euclideanDistance(List<double> vectorA, List<double> vectorB) {
    throw UnimplementedError();
  }

  List<MemorySearchResult> rank(
    List<double> queryEmbedding,
    List<MemoryChunk> chunks,
  ) {
    throw UnimplementedError();
  }

  Future<List<MemorySearchResult>> findTopK(
    List<double> queryEmbedding,
    List<MemoryChunk> chunks, {
    int limit = 10,
  }) {
    throw UnimplementedError();
  }
}
