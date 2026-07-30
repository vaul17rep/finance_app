class MemoryChunk {
  final String id;
  final String content;
  final int index;
  final String? sourceType;
  final String? sourceId;
  final Map<String, dynamic>? metadata;

  MemoryChunk({
    required this.id,
    required this.content,
    required this.index,
    this.sourceType,
    this.sourceId,
    this.metadata,
  });

  MemoryChunk copyWith({
    String? id,
    String? content,
    int? index,
    String? sourceType,
    String? sourceId,
    Map<String, dynamic>? metadata,
  }) {
    return MemoryChunk(
      id: id ?? this.id,
      content: content ?? this.content,
      index: index ?? this.index,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      metadata: metadata ?? this.metadata,
    );
  }
}
