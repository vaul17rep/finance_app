library;
enum BackgroundTaskStatus { waiting, processing, completed, failed, paused }

class BackgroundTask {
  final String id;
  final DateTime createdAt;
  final String title;
  final BackgroundTaskStatus status;
  final double progress;
  final double displayProgress;
  final String message;
  final String? type;
  final Map<String, dynamic> params;

  BackgroundTask({
    required this.id,
    required this.title,
    required this.status,
    DateTime? createdAt,
    this.progress = 0,
    this.displayProgress = 0,
    this.message = "",
    this.type,
    this.params = const {},
  }) : createdAt = createdAt ?? DateTime.now();

  BackgroundTask copyWith({
    BackgroundTaskStatus? status,
    DateTime? createdAt,
    double? progress,
    double? displayProgress,
    String? message,
    String? type,
    Map<String, dynamic>? params,
  }) {
    return BackgroundTask(
      id: id,
      title: title,
      status: status ?? this.status,
      createdAt: createdAt,
      progress: progress ?? this.progress,
      displayProgress: displayProgress ?? this.displayProgress,
      message: message ?? this.message,
      type: type ?? this.type,
      params: params ?? this.params,
    );
  }
}
