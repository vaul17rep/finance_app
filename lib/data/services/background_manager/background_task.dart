
enum BackgroundTaskStatus { waiting, processing, completed, failed }

class BackgroundTask {
  final String id;

  final DateTime createdAt;

  final String title;

  final BackgroundTaskStatus status;

  final double progress;

  final String message;

  BackgroundTask({
    required this.id,
    required this.title,
    required this.status,
    DateTime? createdAt,
    this.progress = 0,
    this.message = "",
  }) : createdAt = createdAt ?? DateTime.now();

  BackgroundTask copyWith({
    BackgroundTaskStatus? status,
    DateTime? createdAt,
    double? progress,
    String? message,
  }) {
    return BackgroundTask(
      id: id,
      title: title,
      status: status ?? this.status,
      createdAt: createdAt,
      progress: progress ?? this.progress,
      message: message ?? this.message,
    );
  }
}
