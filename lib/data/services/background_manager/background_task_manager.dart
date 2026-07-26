import 'dart:async';
import 'package:flutter/foundation.dart';
import 'background_task.dart';
import '../../../core/debug/debug_logger.dart';
import '../../../features/memory/services/indexing_service.dart';
import '../../../features/memory/services/vector_search_service.dart';

class BackgroundTaskManager {
  static final BackgroundTaskManager instance = BackgroundTaskManager._();

  BackgroundTaskManager._();

  IndexingService? _indexingService;
  VectorSearchService? _vectorSearchService;

  void init({
    required IndexingService indexingService,
    required VectorSearchService vectorSearchService,
  }) {
    _indexingService = indexingService;
    _vectorSearchService = vectorSearchService;
  }

  final ValueNotifier<List<BackgroundTask>> tasks = ValueNotifier([]);
  Timer? _animationTimer;

  void updateTask(
    String id, {
    BackgroundTaskStatus? status,
    double? progress,
    String? message,
  }) {
    tasks.value = tasks.value.map((task) {
      if (task.id != id) return task;

      return task.copyWith(
        status: status,
        progress: progress,
        message: message,
      );
    }).toList();

    DebugLogger().logBackground(
      'Обновление задачи $id: ${message ?? 'без сообщения'}',
      level: LogLevel.debug,
    );
  }

  void failTask(String id, {String? message}) {
    // Принудительно завершаем прогресс до 100%
    updateTask(
      id,
      status: BackgroundTaskStatus.failed,
      message: message ?? 'Отменено',
    );
  }

  void removeTask(String id) {
    tasks.value = tasks.value.where((task) => task.id != id).toList();

    if (tasks.value.isEmpty) {
      _stopAnimation();
    }

    DebugLogger().logBackground(
      'Задача удалена из списка: $id',
      level: LogLevel.debug,
    );
  }

  void clearCompleted() {
    tasks.value = tasks.value
        .where(
          (task) =>
              task.status != BackgroundTaskStatus.completed &&
              task.status != BackgroundTaskStatus.failed,
        )
        .toList();
    if (tasks.value.isEmpty) _stopAnimation();
  }

  void _startAnimation() {
    _animationTimer?.cancel();
    const double maxStepPerTick =
        1.0 / (2 * 60); // ≈0.00833 – 100% за 2 секунды

    _animationTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      tasks.value = tasks.value.map((task) {
        final double diff = task.progress - task.displayProgress;

        // Если разница пренебрежимо мала, не обновляем
        if (diff.abs() < 0.0005) return task;

        // Ограничиваем шаг сверху значением maxStepPerTick
        final double step = diff > 0
            ? diff.clamp(0.0, maxStepPerTick)
            : diff.clamp(-maxStepPerTick, 0.0);

        final double newDisplay = (task.displayProgress + step).clamp(0.0, 1.0);

        return task.copyWith(displayProgress: newDisplay);
      }).toList();
    });
  }

  void _stopAnimation() {
    _animationTimer?.cancel();
    _animationTimer = null;
  }

  void addTask(BackgroundTask task) {
    tasks.value = [...tasks.value, task];
    _startAnimation();
    DebugLogger().logBackground(
      'Добавлена задача ${task.id} (${task.type}): ${task.title}',
      level: LogLevel.info,
    );

    // Если задача относится к индексации, запускаем обработку асинхронно
    if (task.type == 'memory_index' || task.type == 'memory_index_single') {
      _processIndexingTask(task);
    }
  }

  Future<void> _processIndexingTask(BackgroundTask task) async {
    if (_indexingService == null || _vectorSearchService == null) {
      failTask(task.id, message: 'Сервисы индексации не инициализированы');
      return;
    }

    try {
      DebugLogger().logBackground(
        'Начало обработки задачи индексации ${task.id}',
        level: LogLevel.info,
      );
      if (task.type == 'memory_index') {
        final sourceTypes = task.params['sourceTypes'] as List<String>?;
        final fullReindex = task.params['fullReindex'] as bool? ?? false;

        if (fullReindex) {
          await _vectorSearchService!.deleteAll();
        }

        await _indexingService!.indexAll(
          sourceTypes: sourceTypes,
          onProgress: (processed, total) {
            final progress = total > 0 ? processed / total : 0.0;
            updateTask(
              task.id,
              progress: progress,
              message: 'Индексация: $processed из $total',
            );
          },
        );

        updateTask(
          task.id,
          status: BackgroundTaskStatus.completed,
          progress: 1.0,
          message: 'Индексация завершена',
        );
      } else if (task.type == 'memory_index_single') {
        final sourceType = task.params['sourceType'] as String;
        final sourceId = task.params['sourceId'] as String;
        final content = task.params['content'] as String;
        final metadata = task.params['metadata'] as Map<String, dynamic>;
        final sourceUpdatedAt = DateTime.parse(
          task.params['sourceUpdatedAt'] as String,
        );

        await _indexingService!.indexSource(
          sourceType: sourceType,
          sourceId: sourceId,
          content: content,
          metadata: metadata,
          sourceUpdatedAt: sourceUpdatedAt,
        );

        updateTask(
          task.id,
          status: BackgroundTaskStatus.completed,
          progress: 1.0,
          message: 'Объект проиндексирован',
        );
      }

      // Через некоторое время удаляем задачу (после завершения)
      await Future.delayed(const Duration(seconds: 3));
      removeTask(task.id);
    } catch (e) {
      DebugLogger().logBackground(
        'Ошибка в задаче индексации ${task.id}: $e',
        level: LogLevel.error,
        error: e,
      );
      failTask(task.id, message: e.toString());
      await Future.delayed(const Duration(seconds: 2));
      removeTask(task.id);
    }
  }
}
