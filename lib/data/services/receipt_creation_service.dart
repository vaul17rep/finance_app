import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../core/debug/debug_logger.dart';
import '../../models/parsed_receipt.dart';
import '../../models/receipt.dart';
import '../../models/receipt_item.dart';
import '../../models/operation.dart';
import '../../models/operation_type.dart';

import '../services/openrouter_service.dart';
import '../services/photo_storage_service.dart';

import '../../features/ai/ai_profiles.dart';
import '../../features/ai/ai_profile.dart';

import '../repositories/receipt_repository.dart';
import '../repositories/operation_repository.dart';

import '../../features/accounts/widgets/select_account_dialog.dart';
import 'background_manager/background_task_manager.dart';
import 'background_manager/background_task.dart';
import '/core/preferences/app_settings.dart';

String encodeImage(Uint8List bytes) {
  return "data:image/jpeg;base64,${base64Encode(bytes)}";
}

class ReceiptCreationService {
  static final picker = ImagePicker();
  static final receiptRepository = ReceiptRepository();
  static final operationRepository = OperationRepository();
  static final uuid = Uuid();
  static AiProfile selectedProfile = AiProfiles.paid;

  static Future<void> createReceipt(BuildContext context) async {
    final taskId = "CHK-${DateTime.now().millisecondsSinceEpoch}";

    try {
      final source = await selectImageSource(context);
      if (source == null) return;

      final image = await picker.pickImage(source: source);
      if (image == null) return;

      BackgroundTaskManager.instance.addTask(
        BackgroundTask(
          id: taskId,
          title: "Распознавание чека",
          status: BackgroundTaskStatus.processing,
          progress: 0.0,
          message: "Подготовка изображения",
        ),
      );

      await Future.delayed(const Duration(milliseconds: 400));
      BackgroundTaskManager.instance.updateTask(
        taskId,
        progress: 0.15,
        message: "Сохранение фотографии",
      );

      final savedPhotoPath = await PhotoStorageService.savePhoto(
        File(image.path),
      );

      await Future.delayed(const Duration(milliseconds: 400));
      BackgroundTaskManager.instance.updateTask(
        taskId,
        progress: 0.3,
        message: "Сжатие изображения",
      );

      final compressed = await FlutterImageCompress.compressWithFile(
        image.path,
        quality: 85,
        minWidth: 2000,
        minHeight: 2000,
      );

      if (compressed == null) {
        throw Exception("Не удалось сжать изображение");
      }

      await Future.delayed(const Duration(milliseconds: 400));
      BackgroundTaskManager.instance.updateTask(
        taskId,
        progress: 0.4,
        message: "Кодирование изображения",
      );

      final base64 = await compute(encodeImage, compressed);

      await Future.delayed(const Duration(milliseconds: 400));
      BackgroundTaskManager.instance.updateTask(
        taskId,
        progress: 0.5,
        message: "Анализ чека AI",
      );

      final service = OpenRouterService(profile: selectedProfile);
      ParsedReceipt result = await service.analyzeReceipt(base64);

      await Future.delayed(const Duration(milliseconds: 400));
      BackgroundTaskManager.instance.updateTask(
        taskId,
        progress: 0.75,
        message: "Создание записи",
      );

      final account = await showSelectAccountDialog(context);
      if (account == null) {
        BackgroundTaskManager.instance.failTask(
          taskId,
          message: 'Счёт не выбран',
        );
        return;
      }

      final receipt = Receipt(
        id: 'CHK-${DateTime.now().millisecondsSinceEpoch}',
        date: result.date ?? DateTime.now(),
        time: result.time,
        shop: result.shop,
        address: result.address,
        amount: result.totalAmount,
        photoPath: savedPhotoPath,
        status: 'DONE',
        comment: result.comment,
      );

      final items = result.items.map((item) {
        return ReceiptItem(
          id: uuid.v4(),
          receiptId: receipt.id,
          name: item.name,
          category: item.category,
          quantity: item.quantity,
          unit: item.unit,
          price: item.price,
          total: item.total,
          priceBeforeDiscount: item.priceBeforeDiscount,
          comment: item.comment,
        );
      }).toList();

      await Future.delayed(const Duration(milliseconds: 400));
      BackgroundTaskManager.instance.updateTask(
        taskId,
        progress: 0.9,
        message: "Сохранение в базу",
      );

      await receiptRepository.insertReceiptWithItems(receipt, items);

      final operation = Operation(
        id: 'OP-${DateTime.now().millisecondsSinceEpoch}',
        type: OperationType.expense,
        amount: receipt.amount,
        comment: result.comment,
        date: receipt.date,
        shop: receipt.shop,
        paymentType: result.paymentType,
        receiptId: receipt.id,
        accountId: account.id,
        categoryId: null,
        processed: false,
      );

      await operationRepository.insertOperation(operation);

      if (AppSettings.autoIndexingEnabled) {
        // Формируем контент для индексации
        final content = _buildReceiptContentForIndexing(receipt, items);
        final metadata = {
          'receiptId': receipt.id,
          'date': receipt.date.toIso8601String(),
          'shop': receipt.shop,
          'amount': receipt.amount,
          //'category': receipt.category ?? '',
        };
        // Запускаем задачу индексации одного чека
        BackgroundTaskManager.instance.addTask(
          BackgroundTask(
            id: 'index_receipt_${receipt.id}',
            type: 'memory_index_single',
            title: 'Индексация чека',
            status: BackgroundTaskStatus.processing,
            progress: 0.0,
            message: 'Подготовка',
            params: {
              'sourceType': 'receipt',
              'sourceId': receipt.id,
              'content': content,
              'metadata': metadata,
              'sourceUpdatedAt': DateTime.now().toIso8601String(),
            },
          ),
        );
      }

      BackgroundTaskManager.instance.updateTask(
        taskId,
        status: BackgroundTaskStatus.completed,
        progress: 1.0,
        message: "Чек готов",
      );

      await Future.delayed(
        const Duration(seconds: 3),
      ); // даём анимации полностью дойти
      BackgroundTaskManager.instance.removeTask(taskId);
    } catch (e) {
      BackgroundTaskManager.instance.failTask(taskId, message: e.toString());
      DebugLogger.log("RECEIPT ERROR: $e");
      // Даём время на анимацию покраснения (например, 2 секунды)
      await Future.delayed(const Duration(seconds: 2));
      BackgroundTaskManager.instance.removeTask(taskId);
    }
  }

  static String _buildReceiptContentForIndexing(
    Receipt receipt,
    List<ReceiptItem> items,
  ) {
    final buffer = StringBuffer();

    buffer.writeln('Магазин: ${receipt.shop}');
    buffer.writeln('Дата: ${receipt.date}');

    if (items.isNotEmpty) {
      buffer.writeln('Товары:');

      for (var item in items) {
        buffer.writeln('- ${item.name} x${item.quantity} = ${item.total}');
      }
    }

    return buffer.toString();
  }

  static Future<ImageSource?> selectImageSource(BuildContext context) async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return SafeArea(
              child: Wrap(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: DropdownButton<AiProfile>(
                      value: selectedProfile,
                      isExpanded: true,
                      items: AiProfiles.all.map((profile) {
                        return DropdownMenuItem(
                          value: profile,
                          child: Text(profile.name),
                        );
                      }).toList(),
                      onChanged: (profile) {
                        if (profile == null) return;
                        setState(() {
                          selectedProfile = profile;
                        });
                      },
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.camera_alt),
                    title: const Text('Камера'),
                    onTap: () => Navigator.pop(context, ImageSource.camera),
                  ),
                  ListTile(
                    leading: const Icon(Icons.photo),
                    title: const Text('Галерея'),
                    onTap: () => Navigator.pop(context, ImageSource.gallery),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
