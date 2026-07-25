class MemoryChunk {
  final String id;
  final String noteId;
  final String text;
  final int chunkIndex;
  final List<double>? embedding;

  const MemoryChunk({
    required this.id,
    required this.noteId,
    required this.text,
    required this.chunkIndex,
    this.embedding,
  });
}
