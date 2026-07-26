import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'log_entry.dart';
export 'log_entry.dart';

class DebugLogger {
  static final DebugLogger _instance = DebugLogger._internal();
  factory DebugLogger() => _instance;
  DebugLogger._internal();

  static const int _maxEntries = 2000;
  static const String _fileName = 'logs.txt';

  final List<LogEntry> _entries = [];
  File? _file;
  bool _initialized = false;

  /// Инициализация: загружаем логи из файла
  Future<void> init() async {
    if (_initialized) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      _file = File('${dir.path}/$_fileName');
      if (await _file!.exists()) {
        final lines = await _file!.readAsLines();
        // Парсим строки, пропускаем некорректные
        for (final line in lines) {
          try {
            final entry = LogEntry.fromString(line);
            _entries.add(entry);
          } catch (e) {
            // Игнорируем плохие строки
          }
        }
        // Ограничиваем количество, если файл слишком большой
        if (_entries.length > _maxEntries) {
          _entries.removeRange(0, _entries.length - _maxEntries);
          await _saveToFile();
        }
      }
      _initialized = true;
    } catch (e) {
      debugPrint('DebugLogger init error: $e');
    }
  }

  /// Добавить запись
  void log({
    required LogLevel level,
    required LogTag tag,
    required String message,
    Map<String, dynamic>? extra,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      tag: tag,
      message: message,
      extra: extra,
    );
    // Добавляем в память
    _entries.add(entry);
    // Если превысили лимит, удаляем старые
    if (_entries.length > _maxEntries) {
      _entries.removeRange(0, _entries.length - _maxEntries);
    }
    // Пишем в файл (асинхронно, не блокируем)
    _appendToFile(entry);
    // Также печатаем в консоль для удобства
    debugPrint(entry.toFormattedString());
    // Если есть ошибка и стек, печатаем стек
    if (error != null) {
      debugPrint('Error: $error');
      if (stackTrace != null) {
        debugPrint('StackTrace: $stackTrace');
      }
    }
  }

  // Вспомогательные методы для удобства
  void debug(
    String message, {
    LogTag tag = LogTag.system,
    Map<String, dynamic>? extra,
  }) {
    log(level: LogLevel.debug, tag: tag, message: message, extra: extra);
  }

  void info(
    String message, {
    LogTag tag = LogTag.system,
    Map<String, dynamic>? extra,
  }) {
    log(level: LogLevel.info, tag: tag, message: message, extra: extra);
  }

  void warning(
    String message, {
    LogTag tag = LogTag.system,
    Map<String, dynamic>? extra,
  }) {
    log(level: LogLevel.warning, tag: tag, message: message, extra: extra);
  }

  void error(
    String message, {
    LogTag tag = LogTag.system,
    Map<String, dynamic>? extra,
    Object? error,
    StackTrace? stackTrace,
  }) {
    log(
      level: LogLevel.error,
      tag: tag,
      message: message,
      extra: extra,
      error: error,
      stackTrace: stackTrace,
    );
  }

  // Специализированные методы по тегам
  void logAi(
    String message, {
    LogLevel level = LogLevel.info,
    Map<String, dynamic>? extra,
    Object? error,
    StackTrace? stackTrace,
  }) {
    log(
      level: level,
      tag: LogTag.ai,
      message: message,
      extra: extra,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void logDatabase(
    String message, {
    LogLevel level = LogLevel.info,
    Map<String, dynamic>? extra,
    Object? error,
    StackTrace? stackTrace,
  }) {
    log(
      level: level,
      tag: LogTag.database,
      message: message,
      extra: extra,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void logBackground(
    String message, {
    LogLevel level = LogLevel.info,
    Map<String, dynamic>? extra,
    Object? error,
    StackTrace? stackTrace,
  }) {
    log(
      level: level,
      tag: LogTag.background,
      message: message,
      extra: extra,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void logFinance(
    String message, {
    LogLevel level = LogLevel.info,
    Map<String, dynamic>? extra,
    Object? error,
    StackTrace? stackTrace,
  }) {
    log(
      level: level,
      tag: LogTag.finance,
      message: message,
      extra: extra,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void logMemory(
    String message, {
    LogLevel level = LogLevel.info,
    Map<String, dynamic>? extra,
    Object? error,
    StackTrace? stackTrace,
  }) {
    log(
      level: level,
      tag: LogTag.memory,
      message: message,
      extra: extra,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Получить все записи (с фильтрацией)
  List<LogEntry> getEntries({LogLevel? level, LogTag? tag}) {
    return _entries.where((e) {
      if (level != null && e.level != level) return false;
      if (tag != null && e.tag != tag) return false;
      return true;
    }).toList();
  }

  /// Получить все записи без фильтра
  List<LogEntry> getAllEntries() => List.unmodifiable(_entries);

  /// Очистить все логи
  Future<void> clear() async {
    _entries.clear();
    if (_file != null && await _file!.exists()) {
      await _file!.writeAsString('');
    }
  }

  /// Сохранить текущие записи в файл (полная перезапись)
  Future<void> _saveToFile() async {
    if (_file == null) return;
    final content = _entries.map((e) => e.toFormattedString()).join('\n');
    await _file!.writeAsString(content);
  }

  /// Добавить одну запись в файл (дописать в конец)
  Future<void> _appendToFile(LogEntry entry) async {
    if (_file == null) return;
    try {
      final line = entry.toFormattedString() + '\n';
      await _file!.writeAsString(line, mode: FileMode.append);
    } catch (e) {
      debugPrint('Failed to append log to file: $e');
    }
  }

  /// Получить полный текст всех логов для копирования
  String getFullLogsText() {
    return _entries.map((e) => e.toFormattedString()).join('\n');
  }

  /// Получить путь к файлу логов для шаринга
  Future<String> getLogFilePath() async {
    if (_file == null) {
      final dir = await getApplicationDocumentsDirectory();
      _file = File('${dir.path}/$_fileName');
    }
    return _file!.path;
  }
}
