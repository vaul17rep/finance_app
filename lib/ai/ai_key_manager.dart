import 'dart:math';

import '../secrets.dart';
import 'ai_profile.dart';

class AiKeyManager {
  static final Map<String, DateTime> _blockedKeys = {};

  static String getAvailableKey(AiProfile profile) {
    final now = DateTime.now();

    final availableKeys = profile.keys.where((key) {
      final blockedUntil = _blockedKeys[key];

      if (blockedUntil == null) {
        return true;
      }

      return now.isAfter(blockedUntil);
    }).toList();

    if (availableKeys.isEmpty) {
      return profile.fallbackKey;
    }

    return availableKeys.first;
  }

  static void markFailed(String key) {
    _blockedKeys[key] = DateTime.now().add(const Duration(minutes: 10));
  }

  static void resetKey(String key) {
    _blockedKeys.remove(key);
  }
}
