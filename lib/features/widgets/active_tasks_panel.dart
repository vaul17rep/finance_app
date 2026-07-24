import 'package:flutter/material.dart';

import '../../data/services/background_manager/background_task.dart';
import '../../data/services/background_manager/background_task_manager.dart';

class ActiveTasksPanel extends StatelessWidget {
  const ActiveTasksPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<BackgroundTask>>(
      valueListenable: BackgroundTaskManager.instance.tasks,

      builder: (context, tasks, _) {
        final activeTasks =
            tasks
                .where(
                  (task) =>
                      task.status == BackgroundTaskStatus.processing ||
                      task.status == BackgroundTaskStatus.waiting,
                )
                .toList()
              ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

        if (activeTasks.isEmpty) {
          return const SizedBox.shrink();
        }

        return Card(
          elevation: 8,

          child: Padding(
            padding: const EdgeInsets.all(12),

            child: AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,

              child: Column(
                key: ValueKey(activeTasks.length),

                mainAxisSize: MainAxisSize.min,

                children: activeTasks.map((task) {
                  return Padding(
                    key: ValueKey(task.id),

                    padding: const EdgeInsets.only(bottom: 12),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Row(
                          children: [
                            const Icon(Icons.receipt_long, size: 20),

                            const SizedBox(width: 8),

                            Expanded(
                              child: Text(
                                task.title,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            Text('${(task.progress * 100).toInt()}%'),
                          ],
                        ),

                        const SizedBox(height: 6),

                        LinearProgressIndicator(value: task.progress),

                        const SizedBox(height: 4),

                        Text(
                          task.message,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }
}
