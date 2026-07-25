import 'dart:async';
import 'package:flutter/foundation.dart';
import 'background_task.dart';
import '../../../core/debug/debug_logger.dart';

class BackgroundTaskManager {
  static final BackgroundTaskManager instance = BackgroundTaskManager._();

  BackgroundTaskManager._();

  final ValueNotifier<List<BackgroundTask>> tasks = ValueNotifier([]);
  Timer? _animationTimer;

  void addTask(BackgroundTask task) {
    tasks.value = [...tasks.value, task];
    _startAnimation();
    DebugLogger.log("TASK ADDED: ${task.title}");
  }

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

    DebugLogger.log("TASK UPDATED: $id");
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
    if (tasks.value.isEmpty) _stopAnimation();
    DebugLogger.log("TASK REMOVED: $id");
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
      bool needsUpdate = false;

      tasks.value = tasks.value.map((task) {
        final double diff = task.progress - task.displayProgress;

        // Если разница пренебрежимо мала, не обновляем
        if (diff.abs() < 0.0005) return task;

        needsUpdate = true;

        // Ограничиваем шаг сверху значением maxStepPerTick
        final double step = diff > 0
            ? diff.clamp(0.0, maxStepPerTick)
            : diff.clamp(-maxStepPerTick, 0.0);

        final double newDisplay = (task.displayProgress + step).clamp(0.0, 1.0);

        return task.copyWith(displayProgress: newDisplay);
      }).toList();

      if (needsUpdate) {
        tasks.notifyListeners();
      }
    });
  }

  void _stopAnimation() {
    _animationTimer?.cancel();
    _animationTimer = null;
  }
}
