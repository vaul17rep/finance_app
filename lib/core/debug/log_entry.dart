import 'package:flutter/material.dart'; // Добавляем импорт для Colors
// Или импортируйте ваш файл с AppColors, если хотите использовать их

enum LogLevel { debug, info, warning, error }

extension LogLevelExtension on LogLevel {
  String get label {
    switch (this) {
      case LogLevel.debug:
        return 'DEBUG';
      case LogLevel.info:
        return 'INFO';
      case LogLevel.warning:
        return 'WARNING';
      case LogLevel.error:
        return 'ERROR';
    }
  }

  Color get color {
    switch (this) {
      case LogLevel.debug:
        return Colors.grey; // или AppColors.textSecondary
      case LogLevel.info:
        return Colors.blue; // или AppColors.primary
      case LogLevel.warning:
        return Colors.orange; // или используйте свой цвет
      case LogLevel.error:
        return Colors.red; // или AppColors.expense
    }
  }
}

enum LogTag { system, ai, database, background, finance, memory }

extension LogTagExtension on LogTag {
  String get label {
    switch (this) {
      case LogTag.system:
        return 'SYSTEM';
      case LogTag.ai:
        return 'AI';
      case LogTag.database:
        return 'DATABASE';
      case LogTag.background:
        return 'BACKGROUND';
      case LogTag.finance:
        return 'FINANCE';
      case LogTag.memory:
        return 'MEMORY';
    }
  }
}

@immutable
class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final LogTag tag;
  final String message;
  final Map<String, dynamic>? extra;
  final Object? error;
  final StackTrace? stackTrace;

  const LogEntry({
    required this.timestamp,
    required this.level,
    required this.tag,
    required this.message,
    this.extra,
    this.error,
    this.stackTrace,
  });

  String toFormattedString() {
    final time = timestamp.toString().substring(0, 23);
    final extraStr = extra != null && extra!.isNotEmpty
        ? ' (${extra!.entries.map((e) => '${e.key}: ${e.value}').join(', ')})'
        : '';
    return '[$time] [${level.label}] [${tag.label}] $message$extraStr';
  }

  factory LogEntry.fromString(String line) {
    final regex = RegExp(
      r'^\[(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3})\] \[(DEBUG|INFO|WARNING|ERROR)\] \[(SYSTEM|AI|DATABASE|BACKGROUND|FINANCE|MEMORY)\] (.+?)(?: \((.+)\))?$',
    );
    final match = regex.firstMatch(line);
    if (match == null) {
      return LogEntry(
        timestamp: DateTime.now(),
        level: LogLevel.info,
        tag: LogTag.system,
        message: line,
      );
    }
    final timestamp = DateTime.parse(match.group(1)!);
    final level = LogLevel.values.firstWhere(
      (e) => e.label == match.group(2),
      orElse: () => LogLevel.info,
    );
    final tag = LogTag.values.firstWhere(
      (e) => e.label == match.group(3),
      orElse: () => LogTag.system,
    );
    final message = match.group(4)!;
    final extraStr = match.group(5);
    Map<String, dynamic>? extra;
    if (extraStr != null) {
      final pairs = extraStr.split(', ');
      extra = {};
      for (final pair in pairs) {
        final parts = pair.split(': ');
        if (parts.length == 2) {
          extra[parts[0]] = parts[1];
        }
      }
    }
    return LogEntry(
      timestamp: timestamp,
      level: level,
      tag: tag,
      message: message,
      extra: extra,
    );
  }
}
