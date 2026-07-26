import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/debug/debug_logger.dart';
import '../widgets/log_filter_chips.dart';
import '../widgets/log_tile.dart';

class DebugLogScreen extends StatefulWidget {
  final LogTag? initialTag;

  const DebugLogScreen({super.key, this.initialTag});

  @override
  State<DebugLogScreen> createState() => _DebugLogScreenState();
}

class _DebugLogScreenState extends State<DebugLogScreen> {
  LogLevel? _selectedLevel;
  LogTag? _selectedTag;
  List<LogEntry> _filteredLogs = [];

  @override
  void initState() {
    super.initState();

    _selectedTag = widget.initialTag;

    _applyFilters();
  }

  void _applyFilters() {
    final all = DebugLogger().getAllEntries();
    _filteredLogs = all.where((e) {
      if (_selectedLevel != null && e.level != _selectedLevel) return false;
      if (_selectedTag != null && e.tag != _selectedTag) return false;
      return true;
    }).toList();
    setState(() {});
  }

  void _copyAllLogs() {
    final text = DebugLogger().getFullLogsText();
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Все логи скопированы в буфер обмена')),
    );
  }

  void _shareLogs() async {
    try {
      final path = await DebugLogger().getLogFilePath();
      final file = File(path);
      if (await file.exists()) {
        await Share.shareXFiles([
          XFile(path),
        ], text: 'Логи приложения Finance App');
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Файл логов не найден')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка при отправке: $e')));
    }
  }

  void _clearLogs() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Очистить логи?'),
        content: const Text('Все записи будут удалены безвозвратно.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Очистить'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await DebugLogger().clear();
      _applyFilters();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Логи очищены')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Логи'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Копировать всё',
            onPressed: _copyAllLogs,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Поделиться файлом',
            onPressed: _shareLogs,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Очистить логи',
            onPressed: _clearLogs,
          ),
        ],
      ),
      body: Column(
        children: [
          // Фильтры
          LogFilterChips(
            selectedLevel: _selectedLevel,
            onLevelSelected: (level) {
              setState(() {
                _selectedLevel = level;
                _applyFilters();
              });
            },
            selectedTag: _selectedTag,
            onTagSelected: (tag) {
              setState(() {
                _selectedTag = tag;
                _applyFilters();
              });
            },
          ),
          const Divider(height: 1),
          // Список логов
          Expanded(
            child: _filteredLogs.isEmpty
                ? const Center(child: Text('Нет записей'))
                : ListView.builder(
                    itemCount: _filteredLogs.length,
                    itemBuilder: (context, index) {
                      final entry = _filteredLogs[index];
                      return LogTile(entry: entry);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
