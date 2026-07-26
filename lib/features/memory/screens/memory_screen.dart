import 'package:flutter/material.dart';
import 'package:finance_app/features/memory/services/vector_search_service.dart';
import 'package:finance_app/features/memory/services/embedding_service.dart';
import 'package:finance_app/features/memory/models/embedding_model.dart';
import 'package:finance_app/features/memory/services/indexing_service.dart';
import 'package:finance_app/core/debug/debug_logger.dart';
import 'package:finance_app/features/debug/screens/debug_log_screen.dart';


class MemoryScreen extends StatefulWidget {
  final VectorSearchService vectorSearchService;
  final EmbeddingService embeddingService;
  final IndexingService indexingService;

  const MemoryScreen({
    super.key,
    required this.vectorSearchService,
    required this.embeddingService,
    required this.indexingService,
  });

  @override
  State<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends State<MemoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<EmbeddingModel> _results = [];
  bool _isLoading = false;
  String? _error;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Память'),
        actions: [
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
                          _openSource(embedding.sourceType, embedding.sourceId);
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
        title: Text('Переиндексация'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Выберите источники для переиндексации:'),
            // Здесь можно добавить чекбоксы для выбора типов
            // Пока просто кнопки
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _indexingService.scheduleIndexing(
                sourceTypes: ['receipt', 'memory_note'],
                fullReindex: true,
              );
            },
            child: Text('Всё'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _indexingService.scheduleIndexing(
                sourceTypes: ['receipt'],
                fullReindex: true,
              );
            },
            child: Text('Только чеки'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _indexingService.scheduleIndexing(
                sourceTypes: ['memory_note'],
                fullReindex: true,
              );
            },
            child: Text('Только заметки'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Отмена'),
          ),
        ],
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
