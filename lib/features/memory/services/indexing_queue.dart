/// Управляемая очередь индексации с ограничением параллелизма.
/// Отвечает за последовательную обработку задач (файлов) с максимальным числом
/// одновременно выполняемых задач (maxConcurrent = 3). Поддерживает паузу,
/// возобновление и отмену. Сохраняет прогресс через колбэки.
library;

import 'dart:async';

/// Задача индексации для очереди.
class IndexingTask {
  final String id;
  final String filePath;
  final dynamic data; // можно передавать путь или уже загруженный файл
  final int retryCount;

  const IndexingTask({
    required this.id,
    required this.filePath,
    this.data,
    this.retryCount = 0,
  });

  IndexingTask copyWith({int? retryCount}) {
    return IndexingTask(
      id: id,
      filePath: filePath,
      data: data,
      retryCount: retryCount ?? this.retryCount,
    );
  }
}

/// Состояние очереди.
class QueueState {
  final List<IndexingTask> pending;
  final List<IndexingTask> active;
  final List<IndexingTask> completed;
  final List<IndexingTask> failed;
  final bool isPaused;
  final bool isCancelled;
  final bool isRunning;

  const QueueState({
    required this.pending,
    required this.active,
    required this.completed,
    required this.failed,
    this.isPaused = false,
    this.isCancelled = false,
    this.isRunning = false,
  });

  int get total =>
      pending.length + active.length + completed.length + failed.length;
  int get processed => completed.length + failed.length;
}

/// Очередь индексации.
class IndexingQueue {
  final int maxConcurrent;
  final Future<void> Function(IndexingTask task) taskHandler;
  final void Function(int processed, int total) onProgress;
  final void Function(QueueState state) onStateChanged;

  List<IndexingTask> _pending = [];
  List<IndexingTask> _active = [];
  List<IndexingTask> _completed = [];
  List<IndexingTask> _failed = [];

  bool _isPaused = false;
  bool _isCancelled = false;
  bool _isRunning = false;

  Timer? _processTimer;
  final _lock = AsyncLock();

  IndexingQueue({
    required this.maxConcurrent,
    required this.taskHandler,
    required this.onProgress,
    required this.onStateChanged,
  });

  void addTasks(List<IndexingTask> tasks) {
    _pending.addAll(tasks);
    _notifyStateChanged();
  }

  void start() {
    if (_isRunning) return;
    _isRunning = true;
    _isPaused = false;
    _isCancelled = false;
    _scheduleProcess();
    _notifyStateChanged();
  }

  void pause() {
    _isPaused = true;
    _notifyStateChanged();
  }

  void resume() {
    if (!_isPaused) return;
    _isPaused = false;
    _scheduleProcess();
    _notifyStateChanged();
  }

  void cancel() {
    _isCancelled = true;
    _isRunning = false;
    _isPaused = false;
    // Очищаем ожидающие задачи
    _pending.clear();
    // Активные задачи не прерываем, но они завершатся и не будут добавлять новые
    _notifyStateChanged();
  }

  bool get isRunning => _isRunning && !_isPaused && !_isCancelled;

  QueueState get state => QueueState(
    pending: List.unmodifiable(_pending),
    active: List.unmodifiable(_active),
    completed: List.unmodifiable(_completed),
    failed: List.unmodifiable(_failed),
    isPaused: _isPaused,
    isCancelled: _isCancelled,
    isRunning: isRunning,
  );

  void _scheduleProcess() {
    _processTimer?.cancel();
    _processTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _processLoop();
    });
  }

  Future<void> _processLoop() async {
    if (_isPaused || _isCancelled || !_isRunning) {
      if (_active.isEmpty && _pending.isEmpty && !_isRunning) {
        _processTimer?.cancel();
        _processTimer = null;
      }
      return;
    }

    // Заполняем активные задачи до maxConcurrent
    while (_active.length < maxConcurrent && _pending.isNotEmpty) {
      final task = _pending.removeAt(0);
      _active.add(task);
      _notifyStateChanged();
      // Запускаем обработку асинхронно, не блокируя цикл
      unawaited(_processTask(task));
    }

    // Если нет активных и нет ожидающих, завершаем
    if (_active.isEmpty && _pending.isEmpty) {
      _isRunning = false;
      _processTimer?.cancel();
      _processTimer = null;
      _notifyStateChanged();
    }
  }

  Future<void> _processTask(IndexingTask task) async {
    try {
      await taskHandler(task);
      // Если задача успешна, перемещаем в completed
      await _lock.synchronized(() {
        _active.removeWhere((t) => t.id == task.id);
        _completed.add(task);
        _notifyStateChanged();
        // Обновляем прогресс
        onProgress(_completed.length + _failed.length, state.total);
      });
    } catch (e) {
      // Ошибка: либо retry, либо в failed
      await _lock.synchronized(() {
        _active.removeWhere((t) => t.id == task.id);
        if (task.retryCount < 3 && !_isCancelled) {
          // Повторная попытка: добавляем обратно в pending с увеличенным retryCount
          _pending.insert(0, task.copyWith(retryCount: task.retryCount + 1));
        } else {
          _failed.add(task);
        }
        _notifyStateChanged();
        onProgress(_completed.length + _failed.length, state.total);
      });
    }
    // Продолжаем цикл
    _scheduleProcess();
  }

  void _notifyStateChanged() {
    onStateChanged(state);
  }
}

/// Простой асинхронный мьютекс для синхронизации.
class AsyncLock {
  Future<void> synchronized(FutureOr<void> Function() action) async {
    if (_lockFuture != null) {
      await _lockFuture;
    }
    final completer = Completer<void>();
    _lockFuture = completer.future;
    try {
      await action();
    } finally {
      completer.complete();
      _lockFuture = null;
    }
  }

  Future<void>? _lockFuture;
}
