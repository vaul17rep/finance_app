class ObsidianNote {
  final String id;
  final String path;
  final String title;
  final String content;
  final DateTime modifiedAt;

  ObsidianNote({
    required this.id,
    required this.path,
    required this.title,
    required this.content,
    required this.modifiedAt,
  });
}
