import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_compress_plus/image_compress_plus.dart';
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
    DebugLogger().logFinance(
      'Создание чека начато, taskId=$taskId',
      level: LogLevel.info,
    );

    try {
      final source = await selectImageSource(context);
      if (source == null) return;

      final image = await picker.pickImage(source: source);
      if (image == null) return;
      DebugLogger().logFinance(
        'Изображение выбрано: ${image.path}',
        level: LogLevel.debug,
      );

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
      DebugLogger().logFinance(
        'Фото сохранено: $savedPhotoPath',
        level: LogLevel.debug,
      );

      await Future.delayed(const Duration(milliseconds: 400));
      BackgroundTaskManager.instance.updateTask(
        taskId,
        progress: 0.3,
        message: "Сжатие изображения",
      );

      // ✅ Исправленный блок сжатия
      final imageFile = File(image.path);
      final compressed = await ImageCompressPlus.compressWithFile(
        imageFile.absolute.path,
        quality: 80,
      );

      if (compressed == null) {
        throw Exception("Не удалось сжать изображение");
      }

      DebugLogger().logFinance(
        'Изображение сжато, размер=${compressed.length}',
        level: LogLevel.debug,
      );

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
      DebugLogger().logFinance(
        'AI распознал чек, магазин=${result.shop}, сумма=${result.totalAmount}, товаров=${result.items.length}',
        level: LogLevel.info,
      );

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

        DebugLogger().logFinance(
          'Счёт не выбран, задача отменена',
          level: LogLevel.warning,
        );

        return;
      }

      DebugLogger().logFinance(
        'Выбран счёт: ${account.name} (${account.id})',
        level: LogLevel.debug,
      );

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
      DebugLogger().logFinance(
        'Чек сохранён: ${receipt.id}',
        level: LogLevel.info,
        extra: {'receiptId': receipt.id},
      );

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
      DebugLogger().logFinance(
        'Операция создана: ${operation.id}',
        level: LogLevel.info,
        extra: {'operationId': operation.id, 'amount': operation.amount},
      );

      if (AppSettings.autoIndexingEnabled) {
        final content = _buildReceiptContentForIndexing(receipt, items);
        final metadata = {
          'receiptId': receipt.id,
          'date': receipt.date.toIso8601String(),
          'shop': receipt.shop,
          'amount': receipt.amount,
        };
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

      await Future.delayed(const Duration(seconds: 3));
      BackgroundTaskManager.instance.removeTask(taskId);
    } catch (e, stack) {
      DebugLogger().logFinance(
        'Ошибка создания чека: $e',
        level: LogLevel.error,
        error: e,
        stackTrace: stack,
      );
      BackgroundTaskManager.instance.failTask(taskId, message: e.toString());
      DebugLogger().logFinance(
        'Ошибка создания чека: $e',
        level: LogLevel.error,
        error: e,
      );
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
