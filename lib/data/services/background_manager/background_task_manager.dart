import 'package:flutter/foundation.dart';

import 'background_task.dart';

import '../../../core/debug/debug_logger.dart';

class BackgroundTaskManager {
  static final BackgroundTaskManager instance = BackgroundTaskManager._();

  BackgroundTaskManager._();

  final ValueNotifier<List<BackgroundTask>> tasks = ValueNotifier([]);

  void addTask(BackgroundTask task) {
    tasks.value = [...tasks.value, task];

    DebugLogger.log("TASK ADDED: ${task.title}");
  }

  void updateTask(
    String id, {
    BackgroundTaskStatus? status,
    double? progress,
    String? message,
  }) {
    tasks.value = tasks.value.map((task) {
      if (task.id != id) {
        return task;
      }

      return task.copyWith(
        status: status,
        progress: progress,
        message: message,
      );
    }).toList();

    DebugLogger.log("TASK UPDATED: $id");
  }

  void removeTask(String id) {
    tasks.value = tasks.value.where((task) => task.id != id).toList();

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
  }
}
