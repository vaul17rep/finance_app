class MemoryNote {
  final String id;
  final String filePath;
  final String title;
  final String content;
  final DateTime? createdAt;
  final DateTime? modifiedAt;

  const MemoryNote({
    required this.id,
    required this.filePath,
    required this.title,
    required this.content,
    this.createdAt,
    this.modifiedAt,
  });
}
