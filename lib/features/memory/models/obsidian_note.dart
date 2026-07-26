import 'package:equatable/equatable.dart';

class ObsidianNote extends Equatable {
  final String id; // уникальный идентификатор (можно сгенерировать)
  final String path; // полный путь к файлу
  final String title; // название заметки
  final String content; // очищенный текст
  final DateTime modifiedAt; // дата изменения файла

  const ObsidianNote({
    required this.id,
    required this.path,
    required this.title,
    required this.content,
    required this.modifiedAt,
  });

  @override
  List<Object?> get props => [id, path, modifiedAt];

  /// Создание из данных файла
  factory ObsidianNote.fromFile({
    required String path,
    required String rawContent,
    required DateTime modifiedAt,
  }) {
    // Очистка YAML-frontmatter
    final cleanedContent = _removeFrontmatter(rawContent);
    // Заголовок: первый заголовок # после frontmatter или имя файла
    final title = _extractTitle(cleanedContent, path);
    // ID на основе пути (детерминированный)
    final id = Uri.encodeComponent(path);
    return ObsidianNote(
      id: id,
      path: path,
      title: title,
      content: cleanedContent.trim(),
      modifiedAt: modifiedAt,
    );
  }

  /// Удаляет YAML frontmatter между ---
  static String _removeFrontmatter(String markdown) {
    if (markdown.startsWith('---')) {
      final endIndex = markdown.indexOf('---', 3);
      if (endIndex != -1) {
        return markdown.substring(endIndex + 3);
      }
    }
    return markdown;
  }

  /// Извлекает заголовок: первый # Заголовок или имя файла без расширения
  static String _extractTitle(String content, String filePath) {
    final lines = content.trimLeft().split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('# ')) {
        return trimmed.substring(2).trim();
      }
    }
    // fallback: имя файла без .md
    final fileName = filePath.split('/').last.split('\\').last;
    if (fileName.endsWith('.md')) {
      return fileName.substring(0, fileName.length - 3);
    }
    return fileName;
  }
}
