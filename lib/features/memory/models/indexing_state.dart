/// Модель состояния индексации для возобновления после перезапуска.
/// Хранит прогресс обработки Obsidian Vault: сколько файлов обработано,
/// сколько пропущено, сколько с ошибками, и список оставшихся файлов.
/// Ответственность: представление данных для таблицы indexing_state.
library;

import 'dart:convert';

class IndexingState {
  /// Идентификатор состояния (например, 'obsidian_index')
  final String id;

  /// Тип источника (например, 'obsidian')
  final String sourceType;

  /// Общее количество файлов
  final int totalFiles;

  /// Успешно обработано
  final int processedFiles;

  /// Пропущено (без изменений)
  final int skippedFiles;

  /// С ошибками
  final int errorFiles;

  /// Путь к текущему обрабатываемому файлу (для отображения)
  final String? currentFilePath;

  /// Статус: idle, indexing, paused, completed, failed
  final String status;

  /// Время начала индексации
  final DateTime startedAt;

  /// Время последнего обновления
  final DateTime updatedAt;

  /// JSON-сериализованный список путей файлов, которые ещё не обработаны
  final String resumeToken;

  const IndexingState({
    required this.id,
    required this.sourceType,
    required this.totalFiles,
    required this.processedFiles,
    required this.skippedFiles,
    required this.errorFiles,
    this.currentFilePath,
    required this.status,
    required this.startedAt,
    required this.updatedAt,
    required this.resumeToken,
  });

  factory IndexingState.initial({
    required String sourceType,
    required int totalFiles,
    required List<String> remainingPaths,
  }) {
    return IndexingState(
      id: '${sourceType}_index',
      sourceType: sourceType,
      totalFiles: totalFiles,
      processedFiles: 0,
      skippedFiles: 0,
      errorFiles: 0,
      currentFilePath: null,
      status: 'idle',
      startedAt: DateTime.now(),
      updatedAt: DateTime.now(),
      resumeToken: jsonEncode(remainingPaths),
    );
  }

  IndexingState copyWith({
    String? id,
    String? sourceType,
    int? totalFiles,
    int? processedFiles,
    int? skippedFiles,
    int? errorFiles,
    String? currentFilePath,
    String? status,
    DateTime? startedAt,
    DateTime? updatedAt,
    String? resumeToken,
  }) {
    return IndexingState(
      id: id ?? this.id,
      sourceType: sourceType ?? this.sourceType,
      totalFiles: totalFiles ?? this.totalFiles,
      processedFiles: processedFiles ?? this.processedFiles,
      skippedFiles: skippedFiles ?? this.skippedFiles,
      errorFiles: errorFiles ?? this.errorFiles,
      currentFilePath: currentFilePath ?? this.currentFilePath,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resumeToken: resumeToken ?? this.resumeToken,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sourceType': sourceType,
      'totalFiles': totalFiles,
      'processedFiles': processedFiles,
      'skippedFiles': skippedFiles,
      'errorFiles': errorFiles,
      'currentFilePath': currentFilePath,
      'status': status,
      'startedAt': startedAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'resumeToken': resumeToken,
    };
  }

  factory IndexingState.fromMap(Map<String, dynamic> map) {
    return IndexingState(
      id: map['id'] as String,
      sourceType: map['sourceType'] as String,
      totalFiles: map['totalFiles'] as int,
      processedFiles: map['processedFiles'] as int,
      skippedFiles: map['skippedFiles'] as int,
      errorFiles: map['errorFiles'] as int,
      currentFilePath: map['currentFilePath'] as String?,
      status: map['status'] as String,
      startedAt: DateTime.parse(map['startedAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      resumeToken: map['resumeToken'] as String,
    );
  }

  /// Получить список оставшихся путей из resumeToken
  List<String> get remainingPaths {
    if (resumeToken.isEmpty) return [];
    try {
      final decoded = jsonDecode(resumeToken) as List<dynamic>;
      return decoded.cast<String>();
    } catch (_) {
      return [];
    }
  }

  /// Создать новый resumeToken из списка путей
  static String encodeRemainingPaths(List<String> paths) {
    return jsonEncode(paths);
  }
}
