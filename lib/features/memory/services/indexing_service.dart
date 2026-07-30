import 'dart:async';
import 'package:finance_app/data/repositories/receipt_repository.dart';
import 'package:finance_app/data/services/background_manager/background_task.dart';
import 'package:finance_app/data/services/background_manager/background_task_manager.dart';
import 'package:finance_app/features/memory/models/embedding_model.dart';
import 'package:finance_app/features/memory/services/embedding_service.dart';
import 'package:finance_app/features/memory/services/vector_search_service.dart';
import 'package:finance_app/features/memory/repositories/memory_note_repository.dart';
import 'package:uuid/uuid.dart';
import 'package:finance_app/models/receipt.dart';
import 'package:finance_app/models/receipt_item.dart';
import 'package:finance_app/features/memory/services/obsidian_reader_service.dart';
import 'package:finance_app/features/memory/models/obsidian_note.dart';
import 'package:finance_app/core/debug/debug_logger.dart';
import 'package:permission_handler/permission_handler.dart';

/// Результат индексации Obsidian
class ObsidianIndexResult {
  final int totalFiles;
  final int successCount;
  final int skippedCount;
  final int errorCount;
  final List<String> errors;

  ObsidianIndexResult({
    required this.totalFiles,
    required this.successCount,
    required this.skippedCount,
    required this.errorCount,
    this.errors = const [],
  });

  @override
  String toString() {
    return 'Индексация завершена\n'
        'Всего файлов: $totalFiles\n'
        'Успешно: $successCount\n'
        'Пропущено (без изменений): $skippedCount\n'
        'Ошибок: $errorCount';
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

  Future<void> indexSource({
    required String sourceType,
    required String sourceId,
    required String content,
    required Map<String, dynamic> metadata,
    required DateTime sourceUpdatedAt,
  }) async {
    final existing = await vectorSearchService.findBySource(
      sourceType,
      sourceId,
    );
    if (existing != null) {
      if (existing.sourceUpdatedAt.isAfter(sourceUpdatedAt) ||
          existing.sourceUpdatedAt.isAtSameMomentAs(sourceUpdatedAt)) {
        return;
      }
    }

    final embeddingBlob = await embeddingService.getEmbeddingBlob(
      content,
      model: embeddingModel,
    );

    final now = DateTime.now();
    final embedding = EmbeddingModel(
      id: existing?.id ?? const Uuid().v4(),
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
  ///
  /// Удаляются записи, которые были созданы из:
  /// .trash, .obsidian, .git, .stversions
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

  /// Индексация всех заметок из Obsidian vault с поддержкой:
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

    final totalFiles = notes.length;
    int successCount = 0;
    int skippedCount = 0;
    int errorCount = 0;
    final errors = <String>[];

    DebugLogger().logMemory(
      'Найдено файлов для индексации: $totalFiles',
      level: LogLevel.info,
    );

    // 2. Пакетная обработка
    const batchSize = 30;
    const pauseBetweenBatches = Duration(milliseconds: 100);
    const maxConcurrent = 5;

    int processed = 0;

    for (int i = 0; i < notes.length; i += batchSize) {
      final batch = notes.skip(i).take(batchSize).toList();

      // Параллельная обработка внутри пачки с ограничением параллелизма
      final futures = <Future<void>>[];
      final semaphore = _Semaphore(maxConcurrent);

      // Собираем статистику по пачке
      int batchSuccess = 0;
      int batchSkipped = 0;
      int batchErrors = 0;

      for (final note in batch) {
        futures.add(
          semaphore.withPermit(() async {
            try {
              final result = await _indexObsidianNote(note);
              if (result == _IndexResult.skipped) {
                batchSkipped++;
              } else if (result == _IndexResult.success) {
                batchSuccess++;
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

      // Обновляем общую статистику
      successCount += batchSuccess;
      skippedCount += batchSkipped;
      errorCount += batchErrors;
      processed += batch.length;

      // Отчёт о прогрессе
      onProgress?.call(processed, totalFiles);

      DebugLogger().logMemory(
        'Obsidian пачка обработана: $processed из $totalFiles '
        '(успешно: $batchSuccess, пропущено: $batchSkipped, ошибок: $batchErrors)',
        level: LogLevel.debug,
      );

      // Пауза между пачками (кроме последней)
      if (i + batchSize < notes.length) {
        await Future.delayed(pauseBetweenBatches);
      }
    }

    final result = ObsidianIndexResult(
      totalFiles: totalFiles,
      successCount: successCount,
      skippedCount: skippedCount,
      errorCount: errorCount,
      errors: errors,
    );

    DebugLogger().logMemory(
      'Индексация Obsidian завершена\n$result',
      level: LogLevel.info,
    );

    return result;
  }

  /// Индексация одного Obsidian-файла с проверкой изменений
  Future<_IndexResult> _indexObsidianNote(ObsidianNote note) async {
    // 1. Проверка существующего эмбеддинга
    final existing = await vectorSearchService.findBySource(
      'obsidian_note',
      note.path,
    );

    // 2. Инкрементальная проверка
    if (existing != null) {
      final existingDate = existing.sourceUpdatedAt;
      // Если файл не изменился - пропускаем
      if (existingDate.isAtSameMomentAs(note.modifiedAt) ||
          existingDate.isAfter(note.modifiedAt)) {
        DebugLogger().logMemory(
          'Пропущен (без изменений): ${note.path}',
          level: LogLevel.debug,
        );
        return _IndexResult.skipped;
      }

      DebugLogger().logMemory(
        'Обновление изменённого файла: ${note.path}',
        level: LogLevel.debug,
      );
    }

    // 3. Создаём эмбеддинг
    await indexSource(
      sourceType: 'obsidian_note',
      sourceId: note.path,
      content: note.content,
      metadata: {'title': note.title, 'path': note.path},
      sourceUpdatedAt: note.modifiedAt,
    );

    DebugLogger().logMemory(
      'Сохранён эмбеддинг Obsidian: ${note.path}',
      level: LogLevel.debug,
    );

    return _IndexResult.success;
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
