import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/obsidian_note.dart';
import '../../../core/debug/debug_logger.dart';

class ObsidianReaderService {
  final _logger = DebugLogger();

  /// Получить список всех .md файлов в vault и создать ObsidianNote
  Future<List<ObsidianNote>> readVault(String vaultPath) async {
    final directory = Directory(vaultPath);
    debugPrint('VAULT EXISTS: ${await directory.exists()}');
    debugPrint('VAULT PATH: $vaultPath');

    if (await directory.exists()) {
      final list = directory.listSync();
      debugPrint('FILES IN ROOT: ${list.length}');
      for (final item in list.take(10)) {
        debugPrint(item.path);
      }
    }
    if (!await directory.exists()) {
      throw Exception('Obsidian vault directory does not exist: $vaultPath');
    }

    final files = await _findMarkdownFiles(directory);
    final notes = <ObsidianNote>[];

    for (final file in files) {
      try {
        final rawContent = await file.readAsString();
        final modifiedAt = await file.lastModified();
        final note = ObsidianNote.fromFile(
          path: file.path,
          rawContent: rawContent,
          modifiedAt: modifiedAt,
        );
        notes.add(note);
      } catch (e) {
        debugPrint('Error reading Obsidian file ${file.path}: $e');
        // Пропускаем повреждённые файлы, логируем
      }
    }

    return notes;
  }

  void checkStoragePermission() {
    if (Platform.isAndroid) {
      final result = Directory('/storage/emulated/0').existsSync();

      debugPrint("ROOT ACCESS: $result");
    }
  }

  /// Рекурсивно ищет все .md файлы,
  /// исключая служебные папки Obsidian/Git и конфликтные файлы.
  Future<List<File>> _findMarkdownFiles(Directory directory) async {
    final files = <File>[];

    final excludedDirNames = {'.trash', '.obsidian', '.git'};

    final excludedFilePattern = RegExp(r'\.sync-conflict-');

    _logger.logMemory(
      'Начало сканирования Obsidian vault',
      extra: {'path': directory.path},
    );

    Future<void> scanDirectory(Directory dir) async {
      try {
        await for (final entity in dir.list(followLinks: false)) {
          if (entity is Directory) {
            final dirName = entity.path.split(Platform.pathSeparator).last;

            if (excludedDirNames.contains(dirName)) {
              _logger.logMemory(
                'Пропущена служебная директория',
                extra: {'path': entity.path},
              );
              continue;
            }

            await scanDirectory(entity);
          } else if (entity is File) {
            final fileName = entity.path.split(Platform.pathSeparator).last;

            if (excludedFilePattern.hasMatch(fileName)) {
              _logger.logMemory(
                'Пропущен конфликтный файл',
                extra: {'path': entity.path},
              );
              continue;
            }

            if (fileName.toLowerCase().endsWith('.md')) {
              files.add(entity);
            }
          }
        }
      } catch (e, stack) {
        _logger.logMemory(
          'Ошибка при сканировании директории',
          level: LogLevel.error,
          extra: {'path': dir.path, 'error': e.toString()},
          error: e,
          stackTrace: stack,
        );
      }
    }

    await scanDirectory(directory);

    _logger.logMemory(
      'Сканирование Obsidian завершено',
      extra: {'markdownFilesFound': files.length},
    );

    return files;
  }
}
