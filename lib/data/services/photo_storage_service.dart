import 'dart:io';
import 'package:path/path.dart' as p;

class PhotoStorageService {
  static Future<String> savePhoto(File source) async {
    final directory = Directory(
      '${Directory.systemTemp.path}/finance_receipts',
    );

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final fileName = 'CHK-${DateTime.now().millisecondsSinceEpoch}.jpg';

    final target = File(p.join(directory.path, fileName));

    await source.copy(target.path);

    return target.path;
  }
}
