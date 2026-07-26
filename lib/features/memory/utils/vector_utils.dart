import 'dart:typed_data';
import 'package:finance_app/core/debug/debug_logger.dart';

/// Преобразует список double в Uint8List (Float32Array → байты)
Uint8List vectorToBlob(List<double> vector) {
  final float32List = Float32List.fromList(vector);
  return float32List.buffer.asUint8List();
}

/// Преобразует Uint8List (BLOB) в список double
List<double> blobToVector(Uint8List blob) {
  if (blob.lengthInBytes % 4 != 0) {
    DebugLogger().logMemory(
      'Повреждён embedding BLOB: размер=${blob.lengthInBytes} байт',
      level: LogLevel.error,
    );

    throw Exception(
      'Некорректный размер embedding BLOB: ${blob.lengthInBytes} байт',
    );
  }

  final float32List = Float32List.view(
    blob.buffer,
    blob.offsetInBytes,
    blob.lengthInBytes ~/ 4,
  );

  return float32List.toList();
}
