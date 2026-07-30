class MemorySearchResult {
  final String id;
  final String sourceType;
  final String sourceId;
  final String content;
  final String title;
  final String? preview;
  final double similarity;
  final Map<String, dynamic>? metadata;

  MemorySearchResult({
    required this.id,
    required this.sourceType,
    required this.sourceId,
    required this.content,
    required this.title,
    this.preview,
    required this.similarity,
    this.metadata,
  });
}
