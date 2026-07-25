import 'dart:typed_data';

/// Преобразует список double в Uint8List (Float32Array → байты)
Uint8List vectorToBlob(List<double> vector) {
  final float32List = Float32List.fromList(vector);
  return float32List.buffer.asUint8List();
}

/// Преобразует Uint8List (BLOB) в список double
List<double> blobToVector(Uint8List blob) {
  final float32List = Float32List.sublistView(blob);
  return float32List.toList();
}
