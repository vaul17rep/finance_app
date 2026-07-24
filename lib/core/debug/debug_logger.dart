import 'package:flutter/foundation.dart';

class DebugLogger {
  static final ValueNotifier<List<String>> logs =
      ValueNotifier<List<String>>([]);

  static void log(String message) {
    debugPrint(message);

    logs.value = [
      ...logs.value,
      "${DateTime.now().toString().substring(11, 19)} | $message",
    ];

    if (logs.value.length > 100) {
      logs.value = logs.value.sublist(logs.value.length - 100);
    }
  }

  static void clear() {
    logs.value = [];
  }
}