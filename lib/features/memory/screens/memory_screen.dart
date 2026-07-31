import 'package:flutter/material.dart';
import 'package:finance_app/features/memory/services/vector_search_service.dart';
import 'package:finance_app/features/memory/services/embedding_service.dart';
import 'package:finance_app/features/memory/models/embedding_model.dart';
import 'package:finance_app/features/memory/services/indexing_service.dart';
import 'package:finance_app/core/debug/debug_logger.dart';
import 'package:finance_app/features/debug/screens/debug_log_screen.dart';
import 'package:finance_app/features/memory/diagnostics/memory_diagnostic_service.dart';
import 'package:finance_app/features/memory/diagnostics/widgets/diagnostic_button.dart';
import 'package:finance_app/features/memory/services/chunking_service.dart';
import 'package:finance_app/features/memory/services/semantic_search_service.dart';
import 'package:finance_app/features/memory/services/vector_similarity_service.dart';
// ✅ ДОБАВЛЯЕМ импорт MemoryDatabase
import 'package:finance_app/data/database/memory_database.dart';

class MemoryScreen extends StatefulWidget {
  final VectorSearchService vectorSearchService;
  final EmbeddingService embeddingService;
  final IndexingService indexingService;
  final ChunkingService chunkingService;
  final SemanticSearchService semanticSearchService;
  final VectorSimilarityService vectorSimilarityService;

  const MemoryScreen({
    super.key,
    required this.vectorSearchService,
    required this.embeddingService,
    required this.indexingService,
    required this.chunkingService,
    required this.semanticSearchService,
    required this.vectorSimilarityService,
  });

  @override
  State<MemoryScreen> createState() => _MemoryScreenState();
}

const bool enableDiagnostics = bool.fromEnvironment('ENABLE_DIAGNOSTICS');

class _MemoryScreenState extends State<MemoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<EmbeddingModel> _results = [];
  bool _isLoading = false;
  String? _error;
  bool _isIndexingObsidian = false;

  // Прогресс индексации
  // ignore: prefer_final_fields
  int _indexedFiles = 0;
  // ignore: prefer_final_fields
  int _totalFiles = 0;
  bool _showProgress = false;
  bool _isPaused = false;

  // Инжектируем зависимости (через provider, getIt или параметры)
  late final VectorSearchService _vectorSearchService;
  late final EmbeddingService _embeddingService;
  late final IndexingService _indexingService;

  @override
  void initState() {
    super.initState();

    _vectorSearchService = widget.vectorSearchService;
    _embeddingService = widget.embeddingService;
    _indexingService = widget.indexingService;

    // Проверяем существование таблицы embeddings
    _ensureEmbeddingsTable();
  }

  // ✅ ИСПРАВЛЕНО: используем MemoryDatabase
  Future<void> _ensureEmbeddingsTable() async {
    try {
      final db = await MemoryDatabase.instance.database;
      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='embeddings'",
      );
      if (result.isEmpty) {
        DebugLogger().logMemory(
          'Таблица embeddings не существует. Будет создана при первой индексации.',
          level: LogLevel.warning,
        );
      } else {
        DebugLogger().logMemory(
          'Таблица embeddings существует',
          level: LogLevel.debug,
        );
      }
    } catch (e) {
      DebugLogger().logMemory(
        'Ошибка проверки таблицы embeddings: $e',
        level: LogLevel.error,
      );
    }
  }

  void _showObsidianNoteDetail(EmbeddingModel embedding) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(embedding.metadata['title'] ?? 'Без названия'),
        content: SingleChildScrollView(child: Text(embedding.content)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
      });
      return;
    }

    DebugLogger().logMemory(
      'Memory поиск начат: "$query"',
      level: LogLevel.info,
    );

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      DebugLogger().logMemory(
        'Создание embedding для запроса',
        level: LogLevel.debug,
      );

      final queryVector = await _embeddingService.getEmbeddingBlob(query);

      DebugLogger().logMemory(
        'Embedding создан, размер=${queryVector.length}',
        level: LogLevel.debug,
      );

      final results = await _vectorSearchService.search(queryVector, limit: 10);

      DebugLogger().logMemory(
        'Memory поиск завершён: найдено ${results.length} результатов',
        level: LogLevel.info,
      );

      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (e, stack) {
      DebugLogger().logMemory(
        'Ошибка Memory поиска: $e',
        level: LogLevel.error,
        error: e,
        stackTrace: stack,
      );

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Очистка битых эмбеддингов (где длина вектора не кратна 4)
  // ✅ ИСПРАВЛЕНО: используем MemoryDatabase
  Future<void> _cleanCorruptedEmbeddings() async {
    // Показываем диалог подтверждения
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Очистка битых эмбеддингов'),
        content: const Text(
          'Будут удалены все эмбеддинги с повреждёнными векторами '
          '(длина не кратна 4). Это может исправить ошибки поиска.\n\n'
          'После очистки рекомендуется выполнить переиндексацию.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Очистить'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // ✅ ИСПРАВЛЕНО: используем MemoryDatabase
      final db = await MemoryDatabase.instance.database;

      // ПРОВЕРКА: существует ли таблица embeddings
      final tableExists = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='embeddings'",
      );

      if (tableExists.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Таблица эмбеддингов ещё не создана. Сначала выполните индексацию.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Проверяем, есть ли колонка vector
      final columns = await db.rawQuery("PRAGMA table_info(embeddings)");
      final hasVectorColumn = columns.any((col) => col['name'] == 'vector');

      if (!hasVectorColumn) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Таблица эмбеддингов не содержит колонку vector.'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Считаем, сколько битых записей
      final countResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM embeddings WHERE LENGTH(vector) % 4 != 0',
      );
      final count = countResult.first['count'] as int? ?? 0;

      if (count == 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Битых эмбеддингов не найдено'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Удаляем битые записи
      final deleted = await db.rawDelete(
        'DELETE FROM embeddings WHERE LENGTH(vector) % 4 != 0',
      );

      DebugLogger().logMemory(
        'Удалено битых эмбеддингов: $deleted',
        level: LogLevel.info,
      );

      // Обновляем результаты поиска (очищаем, так как старые результаты могли содержать битые записи)
      setState(() {
        _results = [];
        _isLoading = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Удалено битых эмбеддингов: $deleted'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      // Предлагаем переиндексацию
      if (deleted > 0) {
        _showReindexAfterCleanDialog(deleted);
      }
    } catch (e, stack) {
      DebugLogger().logMemory(
        'Ошибка очистки битых эмбеддингов: $e',
        level: LogLevel.error,
        error: e,
        stackTrace: stack,
      );

      setState(() {
        _error = 'Ошибка очистки: $e';
        _isLoading = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка очистки: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showIndexingControlDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Управление индексацией'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Прогресс: $_indexedFiles из $_totalFiles',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              _isPaused ? '⏸ Приостановлено' : '▶ Выполняется',
              style: TextStyle(
                color: _isPaused ? Colors.orange : Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _isPaused
                      ? () async {
                          await widget.indexingService.resumeIndexing();
                          if (!ctx.mounted) return;
                          setState(() => _isPaused = false);
                          Navigator.pop(ctx);
                        }
                      : null,
                  child: const Text('▶ Возобновить'),
                ),
                ElevatedButton(
                  onPressed: !_isPaused
                      ? () async {
                          await widget.indexingService.pauseIndexing();
                          if (!ctx.mounted) return;
                          setState(() => _isPaused = true);
                          Navigator.pop(ctx);
                        }
                      : null,
                  child: const Text('⏸ Пауза'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: ctx,
                      builder: (_) => AlertDialog(
                        title: const Text('Отменить индексацию?'),
                        content: const Text(
                          'Прогресс будет потерян. Продолжить?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Нет'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('Да, отменить'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await widget.indexingService.cancelIndexing();
                      if (!ctx.mounted) return;
                      setState(() {
                        _isIndexingObsidian = false;
                        _isPaused = false;
                        _showProgress = false;
                      });
                      Navigator.pop(ctx);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('⏹ Отмена'),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  /// Диалог предложения переиндексации после очистки
  void _showReindexAfterCleanDialog(int deletedCount) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Рекомендуется переиндексация'),
        content: Text(
          'Удалено $deletedCount битых эмбеддингов.\n\n'
          'Рекомендуется выполнить полную переиндексацию '
          'для восстановления поиска.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Позже'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (!mounted) return;
              _showReindexDialog();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.blue),
            child: const Text('Переиндексация'),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticButton() {
    if (!enableDiagnostics) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<MemoryDiagnosticService>(
      future: _createDiagnosticService(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          print('Диагностика: создаём сервис...');
          return const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        if (snapshot.hasError) {
          print('Диагностика ОШИБКА: ${snapshot.error}');
          print(snapshot.stackTrace);

          return IconButton(
            icon: const Icon(Icons.error),
            tooltip: snapshot.error.toString(),
            onPressed: () {},
          );
        }

        if (!snapshot.hasData) {
          print('Диагностика: данных нет');
          return const Icon(Icons.warning);
        }

        print('Диагностика: сервис создан');

        return DiagnosticButton(diagnosticService: snapshot.data!);
      },
    );
  }

  Future<MemoryDiagnosticService> _createDiagnosticService() async {
    // ✅ ТОЖЕ ИСПРАВЛЯЕМ: диагностика тоже должна работать с MemoryDatabase
    final database = await MemoryDatabase.instance.database;

    return MemoryDiagnosticService.createWithAllChecks(
      database: database,
      embeddingService: widget.embeddingService,
      chunkingService: widget.chunkingService,
      searchService: widget.semanticSearchService,
      similarityService: widget.vectorSimilarityService,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Память'),
            if (_showProgress) ...[
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _showIndexingControlDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isIndexingObsidian && !_isPaused)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      if (_isIndexingObsidian && !_isPaused)
                        const SizedBox(width: 6),
                      Text(
                        '$_indexedFiles / $_totalFiles',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.cleaning_services),
            tooltip: 'Очистить битые эмбеддинги',
            onPressed: _cleanCorruptedEmbeddings,
          ),
          _buildDiagnosticButton(),
          IconButton(
            icon: const Icon(Icons.bug_report),
            tooltip: 'Логи Memory',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const DebugLogScreen(initialTag: LogTag.memory),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Что ищем?',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (value) => _performSearch(value),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  tooltip: 'Поиск',
                  onPressed: () {
                    _performSearch(_searchController.text);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.storage),
                  tooltip: 'Показать всю память',
                  onPressed: () async {
                    try {
                      final all = await _vectorSearchService.findAll();

                      DebugLogger().logMemory(
                        'Всего эмбеддингов в базе: ${all.length}',
                        level: LogLevel.info,
                      );

                      setState(() {
                        _results = all;
                      });
                    } catch (e, stack) {
                      DebugLogger().logMemory(
                        'Ошибка загрузки памяти: $e',
                        level: LogLevel.error,
                        error: e,
                        stackTrace: stack,
                      );
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.sync),
                  tooltip: 'Переиндексация',
                  onPressed: () {
                    _showReindexDialog();
                  },
                ),
              ],
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Ошибка: $_error',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          Expanded(
            child: _results.isEmpty
                ? const Center(child: Text('Нет результатов'))
                : ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final embedding = _results[index];
                      final metadata = embedding.metadata;

                      String title = '';
                      String typeLabel = '';
                      IconData icon = Icons.memory;

                      if (embedding.sourceType == 'receipt') {
                        typeLabel = 'Чек';
                        icon = Icons.receipt;
                        title = metadata['shop'] ?? 'Магазин';
                      } else if (embedding.sourceType == 'memory_note') {
                        typeLabel = 'Заметка';
                        icon = Icons.note;
                        title = metadata['title'] ?? 'Заметка';
                      } else if (embedding.sourceType == 'obsidian_note') {
                        typeLabel = 'Obsidian';
                        icon = Icons.notes;
                        title = metadata['title'] ?? 'Без названия';
                      }

                      return ListTile(
                        leading: Icon(icon),
                        title: Text('$typeLabel: $title'),
                        subtitle: Text(
                          embedding.content.length > 100
                              ? '${embedding.content.substring(0, 100)}...'
                              : embedding.content,
                        ),
                        onTap: () {
                          if (embedding.sourceType == 'obsidian_note') {
                            _showObsidianNoteDetail(embedding);
                          } else {
                            _openSource(
                              embedding.sourceType,
                              embedding.sourceId,
                            );
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showReindexDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Переиндексация'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Выберите источники для переиндексации:'),
            const SizedBox(height: 12),
            _buildReindexButton('Всё', null),
            const SizedBox(height: 4),
            _buildReindexButton('Только чеки', ['receipt']),
            const SizedBox(height: 4),
            _buildReindexButton('Только заметки', ['memory_note']),
            const SizedBox(height: 4),
            _buildReindexButton('Только Obsidian', ['obsidian_note']),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );
  }

  Widget _buildReindexButton(String label, List<String>? sourceTypes) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.pop(context);
          _indexingService.scheduleIndexing(
            sourceTypes: sourceTypes,
            fullReindex: true,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Запущена индексация: $label'),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 8),
          backgroundColor: Colors.grey.shade200,
          foregroundColor: Colors.black87,
        ),
        child: Text(label),
      ),
    );
  }

  void _openSource(String sourceType, String sourceId) {
    // Реализовать навигацию в зависимости от типа
    if (sourceType == 'receipt') {
      // Navigator.push(context, MaterialPageRoute(builder: (_) => ReceiptDetailsScreen(receiptId: sourceId)));
    } else if (sourceType == 'memory_note') {
      // Navigator.push(context, MaterialPageRoute(builder: (_) => MemoryNoteDetailsScreen(noteId: sourceId)));
    }
  }
}
