import 'package:flutter/material.dart';

import '/data/services/background_manager/background_task.dart';
import '/data/services/background_manager/background_task_manager.dart';

class TaskMonitorFloating extends StatefulWidget {
  final bool isActive;
  final bool hasError;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  const TaskMonitorFloating({
    super.key,
    required this.isActive,
    required this.hasError,
    required this.onTap,
    required this.onDismissed,
  });

  @override
  State<TaskMonitorFloating> createState() => _TaskMonitorFloatingState();
}

class _TaskMonitorFloatingState extends State<TaskMonitorFloating>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  static const Color softRed = Color(0xFFE57373);

  @override
  void didUpdateWidget(covariant TaskMonitorFloating oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Если ошибка появилась и панель свёрнута — показываем кнопку активно
    if (widget.hasError && !oldWidget.hasError && !_isExpanded) {
      // кнопка будет яркой, пока ошибка видна
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<BackgroundTask>>(
      valueListenable: BackgroundTaskManager.instance.tasks,
      builder: (context, tasks, _) {
        if (tasks.isEmpty) {
          _isExpanded = false;
          return const SizedBox.shrink();
        }

        final targetColor = widget.hasError ? softRed : Colors.blue;

        return AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: Alignment.bottomCenter,
          child: _isExpanded
              ? _buildExpandedPanel(tasks)
              : _buildFloatingButton(tasks, targetColor),
        );
      },
    );
  }

  Widget _buildExpandedPanel(List<BackgroundTask> tasks) {
    return Dismissible(
      key: const ValueKey('expanded'),
      direction: DismissDirection.down,
      onDismissed: (_) {
        setState(() => _isExpanded = false);
        widget.onDismissed();
      },
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.85,
        child: _ActiveTasksPanelContent(tasks: tasks, errorColor: softRed),
      ),
    );
  }

  Widget _buildFloatingButton(List<BackgroundTask> tasks, Color targetColor) {
    final activeCount = tasks
        .where(
          (t) =>
              t.status == BackgroundTaskStatus.processing ||
              t.status == BackgroundTaskStatus.waiting,
        )
        .length;

    return GestureDetector(
      key: const ValueKey('collapsed'),
      onTap: () {
        setState(() => _isExpanded = true);
        widget.onTap();
      },
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: widget.isActive ? 1.0 : 0.0, // плавное исчезновение
        child: Material(
          elevation: widget.isActive ? 8 : 2,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          color: Colors.transparent,
          child: TweenAnimationBuilder<Color?>(
            tween: ColorTween(begin: Colors.blue, end: targetColor),
            duration: const Duration(milliseconds: 300),
            builder: (context, color, child) {
              return Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.receipt_long,
                      size: 24,
                      color: Colors.white,
                    ),
                    if (activeCount > 0)
                      Positioned(
                        right: 4,
                        bottom: 4,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: Text(
                            '$activeCount',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ActiveTasksPanelContent extends StatelessWidget {
  final List<BackgroundTask> tasks;
  final Color errorColor;

  const _ActiveTasksPanelContent({
    required this.tasks,
    required this.errorColor,
  });

  @override
  Widget build(BuildContext context) {
    final sortedTasks = List<BackgroundTask>.from(tasks)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return Card(
      elevation: 8,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: sortedTasks.map((task) {
            final Color targetColor;
            switch (task.status) {
              case BackgroundTaskStatus.failed:
                targetColor = errorColor;
                break;
              case BackgroundTaskStatus.completed:
                targetColor = Colors.green;
                break;
              default:
                targetColor = Colors.blue;
            }

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
                      const SizedBox(width: 8),
                      Text('${(task.progress * 100).toInt()}%'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TweenAnimationBuilder<Color?>(
                    tween: ColorTween(begin: Colors.blue, end: targetColor),
                    duration: const Duration(milliseconds: 300),
                    builder: (context, color, child) {
                      return LinearProgressIndicator(
                        value: task.displayProgress,
                        color: color,
                        backgroundColor: Colors.grey.shade200,
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  Text(task.message, style: const TextStyle(fontSize: 12)),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
