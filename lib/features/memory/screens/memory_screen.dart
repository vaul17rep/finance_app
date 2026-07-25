import 'package:flutter/material.dart';
import 'package:finance_app/features/memory/services/vector_search_service.dart';
import 'package:finance_app/features/memory/services/embedding_service.dart';
import 'package:finance_app/features/memory/models/embedding_model.dart';
import 'package:finance_app/features/memory/services/indexing_service.dart';

class MemoryScreen extends StatefulWidget {
  @override
  _MemoryScreenState createState() => _MemoryScreenState();
}

class _MemoryScreenState extends State<MemoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<EmbeddingModel> _results = [];
  bool _isLoading = false;
  String? _error;

  // Инжектируем зависимости (через provider, getIt или параметры)
  late VectorSearchService _vectorSearchService;
  late EmbeddingService _embeddingService;
  late IndexingService _indexingService;

  @override
  void initState() {
    super.initState();
    // Инициализация зависимостей (замените на свой способ)
    // Например, через Provider.of(context) или getIt.get()
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // Получаем вектор запроса
      final queryVector = await _embeddingService.getEmbeddingBlob(query);
      // Ищем
      final results = await _vectorSearchService.search(queryVector, limit: 10);
      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Поиск по заметкам и чекам')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Что ищем?',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (value) => _performSearch(value),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () => _performSearch(_searchController.text),
                ),
                IconButton(
                  icon: Icon(Icons.sync),
                  onPressed: () {
                    // Запуск полной индексации (спросить подтверждение)
                    _showReindexDialog();
                  },
                ),
              ],
            ),
          ),
          if (_isLoading) LinearProgressIndicator(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Ошибка: $_error',
                style: TextStyle(color: Colors.red),
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final embedding = _results[index];
                final metadata = embedding.metadata;
                String title = '';
                String typeLabel = '';
                IconData icon = Icons.receipt;

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
                    // Переход к источнику
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
