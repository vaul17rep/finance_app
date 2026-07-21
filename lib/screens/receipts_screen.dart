import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

import '../models/receipt.dart';
import '../repositories/receipt_repository.dart';
import '../services/openrouter_service.dart';
import '../ai/ai_profiles.dart';
import '../ai/ai_profile.dart';
import '../models/parsed_receipt.dart';

import '../services/photo_storage_service.dart';
import '../models/receipt_item.dart';
import 'receipt_details_screen.dart';
import '../models/operation.dart';
import '../models/operation_type.dart';
import '../repositories/operation_repository.dart';
import 'widgets/select_account_dialog.dart';
import '../debug/debug_logger.dart';
import 'package:flutter/services.dart';
import '../ai/ai_limit_exception.dart';
import 'package:uuid/uuid.dart';

import 'package:flutter_image_compress/flutter_image_compress.dart';

String encodeImage(Uint8List bytes) {
  return "data:image/jpeg;base64,${base64Encode(bytes)}";
}

class ReceiptsScreen extends StatefulWidget {
  const ReceiptsScreen({super.key});

  @override
  State<ReceiptsScreen> createState() => _ReceiptsScreenState();
}

class _ReceiptsScreenState extends State<ReceiptsScreen> {
  final ReceiptRepository repository = ReceiptRepository();
  final OperationRepository operationRepository = OperationRepository();
  AiProfile selectedProfile = AiProfiles.free;

  final ImagePicker picker = ImagePicker();

  List<Receipt> receipts = [];

  int loadingCount = 0;

  @override
  void initState() {
    super.initState();

    loadReceipts();
  }

  final uuid = Uuid();

  Future<void> loadReceipts() async {
    print("START LOAD RECEIPTS");

    final result = await repository.getReceipts();

    print("RECEIPTS COUNT: ${result.length}");

    setState(() {
      receipts = result;
    });

    print("END LOAD RECEIPTS");
  }

  Future<ImageSource?> selectImageSource() async {
    return await showModalBottomSheet<ImageSource>(
      context: context,

      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),

                title: const Text('Камера'),

                onTap: () {
                  Navigator.pop(context, ImageSource.camera);
                },
              ),

              ListTile(
                leading: const Icon(Icons.photo),

                title: const Text('Галерея'),

                onTap: () {
                  Navigator.pop(context, ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool?> showAiLimitDialog(int tokens) async {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Лимит AI'),

          content: Text(
            'Бесплатный AI не может выполнить такой запрос.\n\n'
            'Доступно токенов: $tokens\n\n'
            'Что сделать?',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Использовать лимит'),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Перейти на платный AI'),
            ),
          ],
        );
      },
    );
  }

  Future<void> addReceipt() async {
    DebugLogger.log("START ADD RECEIPT");
    setState(() {
      loadingCount++;
    });

    final source = await selectImageSource();

    if (source == null) {
      setState(() {
        loadingCount--;
      });
      return;
    }

    final XFile? image = await picker.pickImage(source: source);

    if (image == null) {
      setState(() {
        loadingCount--;
      });
      return;
    }

    DebugLogger.log("IMAGE SELECTED: ${image.path}");

    final savedPhotoPath = await PhotoStorageService.savePhoto(
      File(image.path),
    );

    final compressed = await FlutterImageCompress.compressWithFile(
      image.path,
      quality: 85,
      minWidth: 2000,
      minHeight: 2000,
    );

    if (compressed == null) {
      throw Exception('Не удалось сжать изображение');
    }

    final bytes = compressed;
    DebugLogger.log("IMAGE COMPRESSED: ${bytes.length} bytes");
    final base64 = await compute(encodeImage, bytes);
    DebugLogger.log("BASE64 SIZE: ${base64.length}");
    final service = OpenRouterService(profile: selectedProfile);

    DebugLogger.log("AI PROFILE: ${selectedProfile.name}");
    ParsedReceipt result;

    try {
      result = await service.analyzeReceipt(base64);
    } on AiLimitException catch (e) {
      final usePaid = await showAiLimitDialog(e.availableTokens);

      if (usePaid == true) {
        final paidService = OpenRouterService(profile: AiProfiles.paid);

        result = await paidService.analyzeReceipt(base64);
      } else if (usePaid == false) {
        final limitedService = OpenRouterService(
          profile: selectedProfile,
          maxTokens: e.availableTokens,
        );

        result = await limitedService.analyzeReceipt(base64);
      } else {
        return;
      }
    } catch (e) {
      DebugLogger.log("ERROR: $e");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst("Exception: ", ""))),
        );
      }

      return;
    }

    DebugLogger.log("AI SUCCESS ITEMS: ${result.items.length}");

    DebugLogger.log("AI SHOP: ${result.shop}");

    final account = await showSelectAccountDialog(context);

    if (account == null) {
      setState(() {
        loadingCount--;
      });
      return;
    }

    final receipt = Receipt(
      id: 'CHK-${DateTime.now().millisecondsSinceEpoch}',

      date: result.date ?? DateTime.now(),

      time: result.time,

      shop: result.shop,

      amount: result.totalAmount,

      photoPath: savedPhotoPath,

      status: 'DONE',

      comment: result.paymentType,
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

    await repository.insertReceiptWithItems(receipt, items);

    final operation = Operation(
      id: 'OP-${DateTime.now().millisecondsSinceEpoch}',

      type: OperationType.expense,

      amount: receipt.amount,

      comment: receipt.comment ?? '',

      date: receipt.date,

      shop: receipt.shop,

      paymentType: result.paymentType,

      receiptId: receipt.id,

      accountId: account.id,

      categoryId: 'food',

      article: null,

      regularity: null,

      workDay: null,

      plannedAmount: null,

      processed: false,
    );

    await operationRepository.insertOperation(operation);

    await loadReceipts();

    setState(() {
      loadingCount--;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Чеки'),

            const SizedBox(width: 10),

            DropdownButton<AiProfile>(
              value: selectedProfile,

              underline: const SizedBox(),

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
          ],
        ),

        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report, color: Colors.red),

            onPressed: () {
              showDialog(
                context: context,

                builder: (context) {
                  return AlertDialog(
                    title: const Text('AI DEBUG'),

                    content: SizedBox(
                      width: double.maxFinite,
                      height: 400,

                      child: ValueListenableBuilder<List<String>>(
                        valueListenable: DebugLogger.logs,

                        builder: (context, logs, _) {
                          if (logs.isEmpty) {
                            return const Text("Логов пока нет");
                          }

                          return ListView.builder(
                            itemCount: logs.length,

                            itemBuilder: (context, index) {
                              return Text(
                                logs[index],
                                style: const TextStyle(fontSize: 12),
                              );
                            },
                          );
                        },
                      ),
                    ),

                    actions: [
                      TextButton(
                        onPressed: () async {
                          final text = DebugLogger.logs.value.join("\n");

                          await Clipboard.setData(ClipboardData(text: text));

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Лог скопирован")),
                          );
                        },

                        child: const Text("Копировать"),
                      ),

                      TextButton(
                        onPressed: () {
                          DebugLogger.clear();
                        },

                        child: const Text("Очистить"),
                      ),

                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },

                        child: const Text("Закрыть"),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: loadReceipts,

        child: receipts.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 300),
                  Center(child: Text('Чеков пока нет')),
                ],
              )
            : ListView.builder(
                itemCount: receipts.length,

                itemBuilder: (context, index) {
                  final receipt = receipts[index];

                  return ListTile(
                    title: Text(receipt.shop),

                    subtitle: Text(receipt.date.toString()),

                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,

                      children: [
                        Text('${receipt.amount.toStringAsFixed(2)} ₽'),

                        IconButton(
                          icon: const Icon(Icons.delete),

                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,

                              builder: (context) {
                                return AlertDialog(
                                  title: const Text('Удалить чек?'),

                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context, false);
                                      },

                                      child: const Text('Отмена'),
                                    ),

                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context, true);
                                      },

                                      child: const Text('Удалить'),
                                    ),
                                  ],
                                );
                              },
                            );

                            if (confirm == true) {
                              await repository.deleteReceipt(receipt.id);

                              await loadReceipts();
                            }
                          },
                        ),
                      ],
                    ),

                    onTap: () async {
                      await Navigator.push(
                        context,

                        MaterialPageRoute(
                          builder: (context) =>
                              ReceiptDetailsScreen(receipt: receipt),
                        ),
                      );

                      await loadReceipts();
                    },
                  );
                },
              ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: addReceipt,

        child: loadingCount > 0
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.add),
      ),
    );
  }
}
