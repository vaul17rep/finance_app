import 'dart:typed_data';
import 'package:finance_app/core/debug/debug_logger.dart';

/// Преобразует список double в Uint8List (Float32Array → байты)
///
/// Важно: создаёт копию данных, чтобы избежать проблем с выравниванием.
Uint8List vectorToBlob(List<double> vector) {
  final float32List = Float32List.fromList(vector);
  // Создаём копию байтов с правильным выравниванием
  final bytes = float32List.buffer.asUint8List();
  // Возвращаем копию, чтобы гарантировать правильное выравнивание
  return Uint8List.fromList(bytes);
}

/// Преобразует Uint8List (BLOB) в список double
///
/// Важно: создаёт копию данных, чтобы избежать проблем с выравниванием.
List<double> blobToVector(Uint8List blob) {
  // Проверяем длину
  if (blob.lengthInBytes % 4 != 0) {
    DebugLogger().logMemory(
      'Повреждён embedding BLOB: размер=${blob.lengthInBytes} байт',
      level: LogLevel.error,
    );

    // Пытаемся восстановить, обрезая до кратной 4 длины
    final correctedLength = blob.length - (blob.length % 4);
    if (correctedLength == 0) {
      throw Exception(
        'Некорректный размер embedding BLOB: ${blob.lengthInBytes} байт',
      );
    }

    final correctedBlob = blob.sublist(0, correctedLength);
    DebugLogger().logMemory(
      'BLOB обрезан до $correctedLength байт',
      level: LogLevel.warning,
    );

    // Создаём копию с правильным выравниванием
    final copy = Uint8List.fromList(correctedBlob);
    final float32List = Float32List.sublistView(copy);
    return float32List.toList();
  }

  // КРИТИЧЕСКИ ВАЖНО: создаём копию данных, а не используем view
  // Это гарантирует, что данные будут правильно выровнены в памяти
  //
  // Проблема: SQLite возвращает Uint8List, который может быть view на
  // внутренний буфер с произвольным смещением. При попытке создать
  // Float32List.view() с этим смещением, если оно не кратно 4,
  // возникает RangeError.
  //
  // Решение: создаём копию данных через Uint8List.fromList(),
  // которая гарантирует правильное выравнивание в памяти.
  final copy = Uint8List.fromList(blob);
  final float32List = Float32List.sublistView(copy);
  return float32List.toList();
}
