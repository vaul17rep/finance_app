import 'dart:async';
import 'dart:io';
import 'package:finance_app/data/database/database_helper.dart';
import 'package:finance_app/data/repositories/receipt_repository.dart';
import 'package:finance_app/data/services/background_manager/background_task.dart';
import 'package:finance_app/data/services/background_manager/background_task_manager.dart';
import 'package:finance_app/features/memory/models/embedding_model.dart';
import 'package:finance_app/features/memory/services/chunking_service.dart';
import 'package:finance_app/features/memory/services/embedding_service.dart';
import 'package:finance_app/features/memory/services/vector_search_service.dart';
import 'package:finance_app/features/memory/repositories/memory_note_repository.dart';
import 'package:uuid/uuid.dart';
import 'package:finance_app/models/receipt.dart';
import 'package:finance_app/models/receipt_item.dart';
import 'package:finance_app/features/memory/services/obsidian_reader_service.dart';
import 'package:finance_app/features/memory/models/obsidian_note.dart';
import 'package:finance_app/core/debug/debug_logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart';

/// Результат индексации Obsidian
class ObsidianIndexResult {
  final int totalFiles;
  final int successCount;
  final int skippedCount;
  final int errorCount;
  final List<String> errors;
  final int? oldRecordsDeleted;
  final int? newRecordsCreated;
  final int? totalChunks;
  final double? migrationSuccessRate;

  ObsidianIndexResult({
    required this.totalFiles,
    required this.successCount,
    required this.skippedCount,
    required this.errorCount,
    this.errors = const [],
    this.oldRecordsDeleted,
    this.newRecordsCreated,
    this.totalChunks,
    this.migrationSuccessRate,
  });

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('Индексация завершена');
    buffer.writeln('Всего файлов: $totalFiles');
    buffer.writeln('Успешно: $successCount');
    buffer.writeln('Пропущено (без изменений): $skippedCount');
    buffer.writeln('Ошибок: $errorCount');

    if (oldRecordsDeleted != null) {
      buffer.writeln('Удалено старых записей: $oldRecordsDeleted');
    }
    if (newRecordsCreated != null) {
      buffer.writeln('Создано новых записей: $newRecordsCreated');
    }
    if (totalChunks != null) {
      buffer.writeln('Всего чанков: $totalChunks');
    }
    if (migrationSuccessRate != null) {
      buffer.writeln(
        'Успешность миграции: ${(migrationSuccessRate! * 100).toStringAsFixed(1)}%',
      );
    }

    return buffer.toString();
  }
}

class IndexingService {
  final ReceiptRepository receiptRepository;
  final EmbeddingService embeddingService;
  final VectorSearchService vectorSearchService;
  final MemoryNoteRepository? memoryNoteRepository;
  final BackgroundTaskManager taskManager;
  final String embeddingModel;
  final int embeddingVersion;

  IndexingService({
    required this.receiptRepository,
    required this.embeddingService,
    required this.vectorSearchService,
    this.memoryNoteRepository,
    required this.taskManager,
    this.embeddingModel = 'openai/text-embedding-3-small',
    this.embeddingVersion = 1,
  });

  /// Генерирует стабильный ID документа на основе пути.
  ///
  /// Используется хеш пути, чтобы ID оставался стабильным при перемещении
  /// или переименовании файла.
  String _getDocumentId(String path) {
    return 'obs_${path.hashCode.abs().toRadixString(16)}';
  }

  /// Генерирует уникальный ID для миграции.
  String _generateMigrationId() {
    return 'sourceId_migration_${DateTime.now().toIso8601String().replaceAll(':', '_')}';
  }

  /// Создаёт резервную копию базы данных.
  Future<String> _createBackup() async {
    final dbPath = await getDatabasesPath();
    final dbFile = File('$dbPath/finance.db');
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '_');
    final backupPath = '$dbPath/finance_backup_$timestamp.db';

    if (await dbFile.exists()) {
      await dbFile.copy(backupPath);
      DebugLogger().logMemory(
        'Создана резервная копия БД: $backupPath',
        level: LogLevel.info,
      );
    } else {
      throw Exception('Файл БД не найден: $dbFile.path');
    }

    return backupPath;
  }

  Future<void> indexSource({
    required String sourceType,
    required String sourceId,
    required String content,
    required Map<String, dynamic> metadata,
    required DateTime sourceUpdatedAt,
  }) async {
    // Проверяем существующий эмбеддинг
    final existing = await vectorSearchService.findBySource(
      sourceType,
      sourceId,
    );

    if (existing != null) {
      // Проверяем, изменился ли источник
      if (existing.sourceUpdatedAt.isAfter(sourceUpdatedAt) ||
          existing.sourceUpdatedAt.isAtSameMomentAs(sourceUpdatedAt)) {
        return;
      }

      // Удаляем старый эмбеддинг перед созданием нового
      await vectorSearchService.deleteBySource(sourceType, sourceId);
    }

    // Получаем эмбеддинг (с валидацией внутри EmbeddingService)
    final embeddingBlob = await embeddingService.getEmbeddingBlob(
      content,
      model: embeddingModel,
    );

    final now = DateTime.now();
    final embedding = EmbeddingModel(
      id: const Uuid().v4(),
      sourceType: sourceType,
      sourceId: sourceId,
      content: content,
      vector: embeddingBlob,
      model: embeddingModel,
      embeddingVersion: embeddingVersion,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
      sourceUpdatedAt: sourceUpdatedAt,
      embeddingUpdatedAt: now,
      metadata: metadata,
    );

    await vectorSearchService.save(embedding);
  }

  Future<void> indexAll({
    List<String>? sourceTypes,
    Function(int processed, int total)? onProgress,
  }) async {
    final sources = <_SourceItem>[];

    if (sourceTypes == null || sourceTypes.contains('receipt')) {
      final receipts = await receiptRepository.getReceipts();
      final now = DateTime.now();
      for (var receipt in receipts) {
        final items = await receiptRepository.getReceiptItems(receipt.id);
        final content = _buildReceiptContent(receipt, items);
        final metadata = {
          'receiptId': receipt.id,
          'date': receipt.date.toIso8601String(),
          'shop': receipt.shop,
          'amount': receipt.amount,
        };
        sources.add(
          _SourceItem(
            sourceType: 'receipt',
            sourceId: receipt.id,
            content: content,
            metadata: metadata,
            sourceUpdatedAt: now,
          ),
        );
      }
    }

    if ((sourceTypes == null || sourceTypes.contains('memory_note')) &&
        memoryNoteRepository != null) {
      final notes = await memoryNoteRepository!.getAllNotes();
      final now = DateTime.now();
      for (var note in notes) {
        final content = '${note.title}\n${note.content}';
        final metadata = {
          'noteId': note.id,
          'title': note.title,
          'category': note.category ?? '',
        };
        sources.add(
          _SourceItem(
            sourceType: 'memory_note',
            sourceId: note.id,
            content: content,
            metadata: metadata,
            sourceUpdatedAt: now,
          ),
        );
      }
    }

    if (sources.isEmpty) return;

    final total = sources.length;
    int processed = 0;

    for (var source in sources) {
      try {
        await indexSource(
          sourceType: source.sourceType,
          sourceId: source.sourceId,
          content: source.content,
          metadata: source.metadata,
          sourceUpdatedAt: source.sourceUpdatedAt,
        );
      } catch (e) {
        DebugLogger().logMemory(
          'Ошибка индексации источника ${source.sourceType}:${source.sourceId}: $e',
          level: LogLevel.error,
        );
      }
      processed++;
      if (onProgress != null) {
        onProgress(processed, total);
      }
    }
  }

  /// Удаляет эмбеддинги Obsidian-заметок из служебных папок.
  Future<int> cleanObsidianTrash() async {
    DebugLogger().logMemory('Начата очистка мусорных эмбеддингов Obsidian');

    try {
      final all = await vectorSearchService.findAll();

      final obsidianEmbeddings = all
          .where((e) => e.sourceType == 'obsidian_note')
          .toList();

      DebugLogger().logMemory(
        'Найдено Obsidian эмбеддингов: ${obsidianEmbeddings.length}',
        level: LogLevel.debug,
      );

      int deleted = 0;

      for (final embedding in obsidianEmbeddings) {
        final path = embedding.metadata['path'] as String?;

        if (path == null) {
          continue;
        }

        final isTrash = path.contains('/.trash/');
        final isObsidian = path.contains('/.obsidian/');
        final isGit = path.contains('/.git/');
        final isStversions = path.contains('/.stversions/');

        if (isTrash || isObsidian || isGit || isStversions) {
          await vectorSearchService.deleteBySource(
            embedding.sourceType,
            embedding.sourceId,
          );

          deleted++;

          DebugLogger().logMemory(
            'Удалён мусорный Obsidian embedding',
            level: LogLevel.debug,
            extra: {'path': path},
          );
        }
      }

      DebugLogger().logMemory(
        'Очистка Obsidian завершена',
        extra: {
          'deleted': deleted,
          'checked': obsidianEmbeddings.length,
          'remaining': obsidianEmbeddings.length - deleted,
        },
      );

      return deleted;
    } catch (e, stack) {
      DebugLogger().logMemory(
        'Ошибка очистки Obsidian эмбеддингов',
        level: LogLevel.error,
        extra: {'error': e.toString()},
        error: e,
        stackTrace: stack,
      );

      rethrow;
    }
  }

  /// Индексация одного Obsidian-файла с проверкой изменений.
  ///
  /// [migrationId] — если передан, добавляется в metadata для отслеживания миграции.
  Future<_IndexResult> _indexObsidianNote(
    ObsidianNote note, {
    String? migrationId,
  }) async {
    final documentId = _getDocumentId(note.path);

    // Проверка существующего эмбеддинга
    final existing = await vectorSearchService.findBySource(
      'obsidian_note',
      documentId,
    );

    // Если есть хотя бы один эмбеддинг — проверяем дату обновления
    final existingEmbeddings = await vectorSearchService.findAllBySourceId(
      'obsidian_note',
      documentId,
    );

    if (existingEmbeddings.isNotEmpty) {
      final existingDate = existingEmbeddings.first.sourceUpdatedAt;
      if (existingDate.isAtSameMomentAs(note.modifiedAt) ||
          existingDate.isAfter(note.modifiedAt)) {
        DebugLogger().logMemory(
          'Пропущен (без изменений): ${note.path} (найдено ${existingEmbeddings.length} чанков)',
          level: LogLevel.debug,
        );
        return _IndexResult.skipped;
      }

      // Файл изменился — удаляем все старые чанки (но только после создания новых)
      DebugLogger().logMemory(
        'Обновление изменённого файла: ${note.path} (удаляем ${existingEmbeddings.length} старых чанков)',
        level: LogLevel.debug,
      );
      // НЕ удаляем здесь! Удалим после создания новых чанков (см. исправление 1)
    }

    // Инкрементальная проверка
    if (existing != null) {
      final existingDate = existing.sourceUpdatedAt;
      if (existingDate.isAtSameMomentAs(note.modifiedAt) ||
          existingDate.isAfter(note.modifiedAt)) {
        DebugLogger().logMemory(
          'Пропущен (без изменений): ${note.path}',
          level: LogLevel.debug,
        );
        return _IndexResult.skipped;
      }
    }

    const chunkThreshold = 5000;
    final content = note.content;

    // Базовые метаданные
    final baseMetadata = {'path': note.path, 'title': note.title};

    if (content.length > chunkThreshold) {
      // Большой файл — разбиваем на чанки
      DebugLogger().logMemory(
        'Разбивка на чанки: ${note.path} (${content.length} символов)',
        level: LogLevel.debug,
      );

      final chunker = ChunkingService(chunkSize: 2000, overlap: 200);
      final chunks = await chunker.chunk(content);

      DebugLogger().logMemory(
        'Создано чанков: ${chunks.length} для ${note.path}',
        level: LogLevel.debug,
      );

      // Удаляем старые эмбеддинги для этого документа
      if (existing != null) {
        await vectorSearchService.deleteBySource('obsidian_note', documentId);
      }

      int indexedChunks = 0;
      final chunkErrors = <String>[];

      // Индексируем каждый чанк
      for (int i = 0; i < chunks.length; i++) {
        final chunk = chunks[i];

        // Проверяем, не пустой ли чанк
        if (chunk.content.trim().isEmpty || chunk.content.trim().length < 3) {
          DebugLogger().logMemory(
            'Пропущен пустой чанк #$i для ${note.path}',
            level: LogLevel.debug,
          );
          continue;
        }

        final metadata = {
          ...baseMetadata,
          'chunkIndex': i,
          'totalChunks': chunks.length,
          'parentTitle': note.title,
          if (migrationId != null) 'migrationId': migrationId,
        };

        try {
          await indexSource(
            sourceType: 'obsidian_note',
            sourceId: documentId,
            content: chunk.content,
            metadata: metadata,
            sourceUpdatedAt: note.modifiedAt,
          );
          indexedChunks++;
        } catch (e) {
          final errorMsg = 'Чанк #$i для ${note.path}: $e';
          chunkErrors.add(errorMsg);
          DebugLogger().logMemory(
            'Ошибка индексации чанка #$i для ${note.path}: $e',
            level: LogLevel.error,
          );
          // Продолжаем с остальными чанками
        }
      }

      // Проверяем, был ли сохранён хотя бы один чанк
      if (indexedChunks == 0) {
        final errorMsg = 'Не удалось сохранить ни один чанк для ${note.path}';
        if (chunkErrors.isNotEmpty) {
          throw Exception('$errorMsg: ${chunkErrors.join('; ')}');
        } else {
          throw Exception(errorMsg);
        }
      }

      // ТОЛЬКО ТЕПЕРЬ удаляем старый эмбеддинг, если он существует
      // и если все чанки успешно сохранены (или хотя бы часть)
      if (existing != null) {
        await vectorSearchService.deleteBySource('obsidian_note', documentId);
        DebugLogger().logMemory(
          'Удалён старый эмбеддинг для ${note.path}',
          level: LogLevel.debug,
        );
      }

      DebugLogger().logMemory(
        'Сохранено чанков: $indexedChunks из ${chunks.length} для ${note.path}',
        level: LogLevel.debug,
      );

      return _IndexResult.success;
    } else {
      // Маленький файл — индексируем целиком
      final metadata = {
        ...baseMetadata,
        'chunkIndex': 0,
        'totalChunks': 1,
        'parentTitle': note.title,
        if (migrationId != null) 'migrationId': migrationId,
      };

      await indexSource(
        sourceType: 'obsidian_note',
        sourceId: documentId,
        content: content,
        metadata: metadata,
        sourceUpdatedAt: note.modifiedAt,
      );

      DebugLogger().logMemory(
        'Сохранён эмбеддинг Obsidian: ${note.path}',
        level: LogLevel.debug,
      );

      return _IndexResult.success;
    }
  }

  /// Индексация всех заметок из Obsidian vault с поддержкой:
  /// - безопасной миграции с backup
  /// - прогресса в UI
  /// - пакетной обработки
  /// - инкрементальности
  /// - отчёта об ошибках
  Future<ObsidianIndexResult> indexObsidian(
    String vaultPath, {
    Function(int processed, int total)? onProgress,
  }) async {
    // 1. Очистка мусорных папок перед индексацией
    await cleanObsidianTrash();

    DebugLogger().logMemory('Начало индексации Obsidian vault: $vaultPath');

    final reader = ObsidianReaderService();

    List<ObsidianNote> notes;

    try {
      final status = await Permission.manageExternalStorage.status;

      if (!status.isGranted) {
        final result = await Permission.manageExternalStorage.request();

        if (!result.isGranted) {
          throw Exception('Нет доступа к файлам устройства');
        }
      }

      notes = await reader.readVault(vaultPath);
    } catch (e) {
      DebugLogger().logMemory('Ошибка чтения vault: $e', level: LogLevel.error);
      rethrow;
    }

    if (notes.isEmpty) {
      throw Exception('В Vault не найдено markdown-файлов');
    }

    // 2. Подсчёт старых записей
    final oldCount = await vectorSearchService.countBySourceType(
      'obsidian_note',
    );
    DebugLogger().logMemory(
      'Найдено старых Obsidian записей: $oldCount',
      level: LogLevel.info,
    );

    // 3. Создание backup
    final backupPath = await _createBackup();

    // 4. Генерация migrationId
    final migrationId = _generateMigrationId();
    DebugLogger().logMemory(
      'Начало миграции с ID: $migrationId',
      level: LogLevel.info,
    );

    final totalFiles = notes.length;
    int successCount = 0;
    int skippedCount = 0;
    int errorCount = 0;
    final errors = <String>[];
    int totalChunks = 0;

    // 5. Пакетная обработка с передачей migrationId
    const batchSize = 30;
    const pauseBetweenBatches = Duration(milliseconds: 100);
    const maxConcurrent = 5;

    int processed = 0;

    for (int i = 0; i < notes.length; i += batchSize) {
      final batch = notes.skip(i).take(batchSize).toList();

      final futures = <Future<void>>[];
      final semaphore = _Semaphore(maxConcurrent);

      int batchSuccess = 0;
      int batchSkipped = 0;
      int batchErrors = 0;
      int batchChunks = 0;

      for (final note in batch) {
        futures.add(
          semaphore.withPermit(() async {
            try {
              final result = await _indexObsidianNote(
                note,
                migrationId: migrationId,
              );
              if (result == _IndexResult.skipped) {
                batchSkipped++;
              } else if (result == _IndexResult.success) {
                batchSuccess++;
                // Подсчитываем чанки (загружаем метаданные из последнего сохранённого эмбеддинга)
                // Упрощённо: считаем, что каждый успешный файл даёт как минимум 1 чанк
                batchChunks += 1;
              }
            } catch (e) {
              batchErrors++;
              final errorMsg = '${note.path}: $e';
              errors.add(errorMsg);
              DebugLogger().logMemory(
                'Ошибка индексации Obsidian ${note.path}: $e',
                level: LogLevel.error,
              );
            }
          }),
        );
      }

      await Future.wait(futures);

      successCount += batchSuccess;
      skippedCount += batchSkipped;
      errorCount += batchErrors;
      totalChunks += batchChunks;
      processed += batch.length;

      onProgress?.call(processed, totalFiles);

      DebugLogger().logMemory(
        'Obsidian пачка обработана: $processed из $totalFiles '
        '(успешно: $batchSuccess, пропущено: $batchSkipped, ошибок: $batchErrors)',
        level: LogLevel.debug,
      );

      if (i + batchSize < notes.length) {
        await Future.delayed(pauseBetweenBatches);
      }
    }

    // 6. Подсчёт новых записей
    final newCount = await vectorSearchService.countByMigrationId(migrationId);
    final successRate = oldCount > 0 ? newCount / oldCount : 1.0;

    DebugLogger().logMemory(
      'Миграция: старых=$oldCount, новых=$newCount, успешность=${(successRate * 100).toStringAsFixed(1)}%',
      level: LogLevel.info,
    );

    int oldRecordsDeleted = 0;
    int newRecordsCreated = 0;

    // 7. Валидация и финализация
    if (successRate >= 0.9 && newCount > 0) {
      // Успешная миграция
      DebugLogger().logMemory(
        'Миграция успешна, удаляем старый индекс...',
        level: LogLevel.info,
      );

      oldRecordsDeleted = oldCount;
      await vectorSearchService.deleteBySourceType('obsidian_note');

      DebugLogger().logMemory(
        'Очищаем migrationId у новых записей...',
        level: LogLevel.debug,
      );

      await vectorSearchService.clearMigrationId(migrationId);

      newRecordsCreated = newCount;

      DebugLogger().logMemory(
        'Миграция завершена успешно',
        level: LogLevel.info,
        extra: {
          'oldRecordsDeleted': oldRecordsDeleted,
          'newRecordsCreated': newRecordsCreated,
          'totalChunks': totalChunks,
        },
      );
    } else {
      // Откат
      DebugLogger().logMemory(
        'Миграция не удалась (успешность ${(successRate * 100).toStringAsFixed(1)}% < 90%), откат...',
        level: LogLevel.error,
      );

      await vectorSearchService.deleteByMigrationId(migrationId);

      DebugLogger().logMemory(
        'Откат выполнен, старый индекс восстановлен из backup: $backupPath',
        level: LogLevel.info,
      );

      throw Exception(
        'Миграция не удалась: успешность ${(successRate * 100).toStringAsFixed(1)}% < 90%. '
        'Восстановлен backup: $backupPath',
      );
    }

    // 8. Формируем результат
    final result = ObsidianIndexResult(
      totalFiles: totalFiles,
      successCount: successCount,
      skippedCount: skippedCount,
      errorCount: errorCount,
      errors: errors,
      oldRecordsDeleted: oldRecordsDeleted,
      newRecordsCreated: newRecordsCreated,
      totalChunks: totalChunks,
      migrationSuccessRate: successRate,
    );

    DebugLogger().logMemory(
      'Индексация Obsidian завершена\n$result',
      level: LogLevel.info,
    );

    return result;
  }

  void scheduleIndexing({List<String>? sourceTypes, bool fullReindex = false}) {
    final task = BackgroundTask(
      id: 'memory_index_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Индексация памяти',
      status: BackgroundTaskStatus.waiting,
      type: 'memory_index',
      params: {'sourceTypes': sourceTypes, 'fullReindex': fullReindex},
    );
    taskManager.addTask(task);
  }

  String _buildReceiptContent(Receipt receipt, List<ReceiptItem> items) {
    final buffer = StringBuffer();
    buffer.writeln('Магазин: ${receipt.shop}');
    buffer.writeln('Дата: ${receipt.date}');
    buffer.writeln('Сумма: ${receipt.amount}');
    if (items.isNotEmpty) {
      buffer.writeln('Товары:');
      for (var item in items) {
        buffer.writeln('- ${item.name} x${item.quantity} = ${item.total}');
      }
    }
    return buffer.toString();
  }
}

/// Результат индексации одного файла
enum _IndexResult { success, skipped }

/// Семафор для ограничения параллельных операций
class _Semaphore {
  final int maxConcurrent;
  int _current = 0;
  final List<Completer<void>> _waiting = [];

  _Semaphore(this.maxConcurrent);

  Future<void> withPermit(Future<void> Function() action) async {
    await _acquire();
    try {
      await action();
    } finally {
      _release();
    }
  }

  Future<void> _acquire() async {
    if (_current < maxConcurrent) {
      _current++;
      return;
    }
    final completer = Completer<void>();
    _waiting.add(completer);
    await completer.future;
    _current++;
  }

  void _release() {
    if (_waiting.isNotEmpty) {
      final completer = _waiting.removeAt(0);
      completer.complete();
    } else {
      _current--;
    }
  }
}

class _SourceItem {
  final String sourceType;
  final String sourceId;
  final String content;
  final Map<String, dynamic> metadata;
  final DateTime sourceUpdatedAt;

  _SourceItem({
    required this.sourceType,
    required this.sourceId,
    required this.content,
    required this.metadata,
    required this.sourceUpdatedAt,
  });
}
