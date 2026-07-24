import 'dart:io';

class PhotoCleanupService {
  static Future<void> cleanOldPhotos() async {
    final directory = Directory('/storage/emulated/0/FinanceReceipts');

    if (!await directory.exists()) {
      return;
    }

    final files = directory.listSync();

    final now = DateTime.now();

    for (final file in files) {
      if (file is File) {
        final modified = await file.lastModified();

        final difference = now.difference(modified);

        if (difference.inDays >= 7) {
          await file.delete();
        }
      }
    }
  }
}
