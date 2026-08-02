/// Сервис индексации для системы знаний.
/// Отвечает за координацию индексации различных источников (чеки, заметки, Obsidian).
/// Теперь использует IndexingQueue для управляемой обработки, сохраняет состояние
/// в таблицу indexing_state для возобновления после перезапуска, и собирает
/// метрики пикового потребления памяти для диагностики OOM.
library;

import 'dart:async';
import 'dart:io';
import '/data/repositories/receipt_repository.dart';
import '/data/services/background_manager/background_task.dart';
import '/data/services/background_manager/background_task_manager.dart';
import '/features/memory/models/embedding_model.dart';
import '/features/memory/services/chunking_service.dart';
import '/features/memory/services/embedding_service.dart';
import '/features/memory/services/vector_search_service.dart';
import '/features/memory/repositories/memory_note_repository.dart';
import 'package:uuid/uuid.dart';
import '/models/receipt.dart';
import '/models/receipt_item.dart';
import '/features/memory/services/obsidian_reader_service.dart';
import '/features/memory/models/obsidian_note.dart';
import '/core/debug/debug_logger.dart';
import 'package:permission_handler/permission_handler.dart';
import '/features/memory/repositories/embedding_repository.dart';
import '/core/preferences/app_settings.dart';
// Новые импорты
import '/features/memory/models/indexing_state.dart';
import '/features/memory/repositories/indexing_state_repository.dart';
import '/features/memory/services/indexing_queue.dart';

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
  final EmbeddingRepository embeddingRepository;
  final MemoryNoteRepository? memoryNoteRepository;
  final BackgroundTaskManager taskManager;
  final IndexingStateRepository? indexingStateRepository; // новый
  final String embeddingModel;
  final int embeddingVersion;
  IndexingQueue? _queue;
  String? _currentTaskId;

  static const int maxFileSizeBytes = 5 * 1024 * 1024; // исправлено с 500 КБ
  static const int chunkThreshold = 8000; // исправлено с 5000

  IndexingService({
    required this.receiptRepository,
    required this.embeddingService,
    required this.vectorSearchService,
    required this.embeddingRepository,
    this.indexingStateRepository,
    this.memoryNoteRepository,
    required this.taskManager,
    this.embeddingModel = 'openai/text-embedding-3-small',
    this.embeddingVersion = 1,
  });

  /// Генерирует стабильный ID документа на основе пути.
  String _getDocumentId(String path) {
    return 'obs_${path.hashCode.abs().toRadixString(16)}';
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

    // Сохраняем в старую таблицу (всегда)
    await vectorSearchService.save(embedding);

    // Если включён новый движок, сохраняем также в новую таблицу
    if (AppSettings.useSqliteVec) {
      try {
        await embeddingRepository.saveVec(embedding);
      } catch (e) {
        DebugLogger().logMemory(
          'Ошибка сохранения в новую таблицу: $e',
          level: LogLevel.error,
        );
      }
    }
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

  /// Основной метод индексации Obsidian с использованием очереди.
  // Полностью переписать метод indexObsidian:
  Future<ObsidianIndexResult> indexObsidian(
    String vaultPath, {
    Function(int processed, int total)? onProgress,
  }) async {
    // Диагностика OOM: замеряем начальное потребление памяти
    final startMemory = ProcessInfo.currentRss;
    DebugLogger().logMemory(
      'Начало индексации Obsidian, начальная память: ${startMemory ~/ 1024} КБ',
      level: LogLevel.info,
    );

    // Проверяем, есть ли сохранённое состояние
    IndexingState? savedState;
    List<String> remainingPaths = [];
    int totalFiles = 0;

    if (indexingStateRepository != null) {
      try {
        savedState = await indexingStateRepository!.load('obsidian');
      } catch (e) {
        DebugLogger().logMemory(
          'Не удалось загрузить состояние индексации: $e',
          level: LogLevel.warning,
        );
      }

      if (savedState != null &&
          savedState.status != 'completed' &&
          savedState.status != 'failed') {
        // Восстанавливаем состояние
        remainingPaths = savedState.remainingPaths;
        totalFiles = savedState.totalFiles;
        DebugLogger().logMemory(
          'Восстановлено состояние индексации: обработано ${savedState.processedFiles} из $totalFiles',
          level: LogLevel.info,
        );
        // Если осталось 0 файлов, но статус не completed — возможно, ошибка, начинаем заново
        if (remainingPaths.isEmpty) {
          DebugLogger().logMemory(
            'Состояние повреждено (нет оставшихся файлов), начинаем заново',
            level: LogLevel.warning,
          );
          savedState = null;
        }
      }
    }

    if (savedState == null) {
      // Сканируем Vault заново
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
        DebugLogger().logMemory(
          'Ошибка чтения vault: $e',
          level: LogLevel.error,
        );
        rethrow;
      }

      if (notes.isEmpty) {
        throw Exception('В Vault не найдено markdown-файлов');
      }

      // Формируем список путей файлов
      final allPaths = notes.map((n) => n.path).toList();
      totalFiles = allPaths.length;
      remainingPaths = List.from(allPaths);

      // Создаём начальное состояние
      if (indexingStateRepository != null) {
        final initialState = IndexingState.initial(
          sourceType: 'obsidian',
          totalFiles: totalFiles,
          remainingPaths: remainingPaths,
        );
        await indexingStateRepository!.save(initialState);
      }
    }

    // Создаём задачу в BackgroundTaskManager
    final taskId = 'obsidian_index_${DateTime.now().millisecondsSinceEpoch}';
    _currentTaskId = taskId;
    final bgTask = BackgroundTask(
      id: taskId,
      title: 'Индексация Obsidian',
      status: BackgroundTaskStatus.processing,
      type: 'memory_index_obsidian',
      params: {'vaultPath': vaultPath},
    );
    taskManager.addTask(bgTask);

    // Создаём очередь
    // Создаём очередь
    late final IndexingQueue queue;
    queue = IndexingQueue(
      maxConcurrent: 3,
      taskHandler: (task) async {
        final filePath = task.filePath;
        final file = File(filePath);
        if (!await file.exists()) {
          DebugLogger().logMemory(
            'Файл не существует: $filePath',
            level: LogLevel.warning,
          );
          return;
        }
        final stat = await file.stat();
        if (stat.size > maxFileSizeBytes) {
          DebugLogger().logMemory(
            'Пропущен (слишком большой): $filePath (${stat.size} байт)',
            level: LogLevel.warning,
          );
          return;
        }
        final rawContent = await file.readAsString();
        final modifiedAt = await file.lastModified();
        final note = ObsidianNote.fromFile(
          path: filePath,
          rawContent: rawContent,
          modifiedAt: modifiedAt,
        );
        await _indexObsidianNote(note);
      },
      onProgress: (processed, total) {
        if (_currentTaskId != null) {
          final progress = total > 0 ? processed / total : 0.0;
          taskManager.updateTask(
            _currentTaskId!,
            progress: progress,
            message: 'Индексация: $processed из $total',
          );
        }
        _updateStateFromQueue(queue);
        onProgress?.call(processed, total);
      },
      onStateChanged: (state) {},
    );

    final tasks = remainingPaths.map((path) {
      return IndexingTask(id: 'file_${path.hashCode.abs()}', filePath: path);
    }).toList();

    queue.addTasks(tasks);
    _queue = queue;
    queue.start();

    await _waitForQueueCompletion(queue);

    final endMemory = ProcessInfo.currentRss;
    DebugLogger().logMemory(
      'Индексация завершена, пиковая память: ${endMemory ~/ 1024} КБ, '
      'прирост: ${(endMemory - startMemory) ~/ 1024} КБ',
      level: LogLevel.info,
    );

    if (indexingStateRepository != null) {
      await indexingStateRepository!.delete('obsidian');
    }

    final result = ObsidianIndexResult(
      totalFiles: totalFiles,
      successCount: queue.state.completed.length,
      skippedCount: 0,
      errorCount: queue.state.failed.length,
      errors: queue.state.failed.map((t) => t.filePath).toList(),
    );

    if (_currentTaskId != null) {
      taskManager.updateTask(
        _currentTaskId!,
        status: BackgroundTaskStatus.completed,
        progress: 1.0,
        message: 'Индексация завершена',
      );
      Future.delayed(const Duration(seconds: 3), () {
        if (_currentTaskId != null) {
          taskManager.removeTask(_currentTaskId!);
          _currentTaskId = null;
        }
      });
    }

    return result;
  }

  /// Ожидание завершения очереди.
  Future<void> _waitForQueueCompletion(IndexingQueue queue) async {
    final completer = Completer<void>();
    Timer? timer;
    timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!queue.isRunning &&
          queue.state.pending.isEmpty &&
          queue.state.active.isEmpty) {
        timer?.cancel();
        completer.complete();
      }
    });
    return completer.future;
  }

  /// Обновление состояния индексации в БД на основе состояния очереди.
  Future<void> _updateStateFromQueue(IndexingQueue queue) async {
    if (indexingStateRepository == null) return;

    final state = queue.state;
    final remainingPaths = state.pending.map((t) => t.filePath).toList();
    final updatedState = IndexingState(
      id: 'obsidian_index',
      sourceType: 'obsidian',
      totalFiles: state.total,
      processedFiles: state.processed,
      skippedFiles: 0,
      errorFiles: state.failed.length,
      currentFilePath: state.active.isNotEmpty
          ? state.active.first.filePath
          : null,
      status: queue.isRunning
          ? 'indexing'
          : (state.isPaused ? 'paused' : 'idle'),
      startedAt: DateTime.now(),
      updatedAt: DateTime.now(),
      resumeToken: IndexingState.encodeRemainingPaths(remainingPaths),
    );
    await indexingStateRepository!.save(updatedState);
  }

  // Методы управления очередью (для UI)
  Future<void> pauseIndexing() async {
    _queue?.pause();
    if (_currentTaskId != null) {
      taskManager.updateTask(
        _currentTaskId!,
        status: BackgroundTaskStatus.paused,
        message: 'Приостановлено',
      );
    }
  }

  Future<void> resumeIndexing() async {
    _queue?.resume();
    if (_currentTaskId != null) {
      taskManager.updateTask(
        _currentTaskId!,
        status: BackgroundTaskStatus.processing,
        message: 'Возобновлено',
      );
    }
  }

  Future<void> cancelIndexing() async {
    _queue?.cancel();
    if (_currentTaskId != null) {
      taskManager.failTask(_currentTaskId!, message: 'Отменено пользователем');
      taskManager.removeTask(_currentTaskId!);
      _currentTaskId = null;
    }
    if (indexingStateRepository != null) {
      await indexingStateRepository!.delete('obsidian');
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
  Future<_IndexResult> _indexObsidianNote(
    ObsidianNote note, {
    String? migrationId,
  }) async {
    final documentId = _getDocumentId(note.path);
    final content = note.content;
    const chunkThreshold = 5000;

    // Защита от OOM: проверка размера содержимого
    final contentSizeBytes =
        content.length * 2; // приблизительно 2 байта на символ в UTF-16
    if (contentSizeBytes > maxFileSizeBytes) {
      DebugLogger().logMemory(
        '⚠️ Файл пропущен (превышен лимит размера): ${note.path} '
        '(размер: ${(contentSizeBytes / 1024).toStringAsFixed(1)} КБ)',
        level: LogLevel.warning,
      );
      return _IndexResult.skipped;
    }

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
    }

    final baseMetadata = {'path': note.path, 'title': note.title};

    if (content.length > chunkThreshold) {
      // Большой файл — разбиваем на чанки
      DebugLogger().logMemory(
        'Разбивка на чанки: ${note.path} (${content.length} символов)',
        level: LogLevel.debug,
      );

      final chunker = ChunkingService();
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
        }
      }

      if (indexedChunks == 0) {
        final errorMsg = 'Не удалось сохранить ни один чанк для ${note.path}';
        if (chunkErrors.isNotEmpty) {
          throw Exception('$errorMsg: ${chunkErrors.join('; ')}');
        } else {
          throw Exception(errorMsg);
        }
      }

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

enum _IndexResult { success, skipped }

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
