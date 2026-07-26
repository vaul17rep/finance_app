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
          existing.sourceUpdatedAt == sourceUpdatedAt) {
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
            sourceUpdatedAt: now, // используем текущее время
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
            sourceUpdatedAt: now, // используем текущее время
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
        print(
          'Ошибка индексации источника ${source.sourceType}:${source.sourceId}: $e',
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
  /// .trash
  /// .obsidian
  /// .git
  Future<void> cleanObsidianTrash() async {
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

        if (isTrash || isObsidian || isGit) {
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

  /// Индексация всех заметок из Obsidian vault
  Future<void> indexObsidian(String vaultPath) async {
    // 1. Перед индексацией удаляем старые мусорные embeddings
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
      DebugLogger().logMemory('Ошибка чтения vault: $e');
      rethrow;
    }

    if (notes.isEmpty) {
      throw Exception('В Vault не найдено markdown-файлов');
    }

    for (final note in notes) {
      try {
        await indexSource(
          sourceType: 'obsidian_note',
          sourceId: note.path,
          content: note.content,
          metadata: {'title': note.title, 'path': note.path},
          sourceUpdatedAt: note.modifiedAt,
        );

        DebugLogger().logMemory('Сохранён embedding Obsidian: ${note.path}');
      } catch (e) {
        DebugLogger().logMemory('Ошибка индексации Obsidian ${note.path}: $e');
      }
    }

    DebugLogger().logMemory('Индексация Obsidian завершена');
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
