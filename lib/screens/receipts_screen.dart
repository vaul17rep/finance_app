import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

import '../models/receipt.dart';
import '../repositories/receipt_repository.dart';
import '../services/openrouter_service.dart';
import '../secrets.dart';
import '../services/photo_storage_service.dart';
import '../models/receipt_item.dart';
import 'receipt_details_screen.dart';
import '../models/operation.dart';
import '../models/operation_type.dart';
import '../repositories/operation_repository.dart';

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

  final ImagePicker picker = ImagePicker();

  List<Receipt> receipts = [];

  int loadingCount = 0;

  @override
  void initState() {
    super.initState();

    loadReceipts();
  }

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

  Future<void> addReceipt() async {
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

    final base64 = await compute(encodeImage, bytes);

    final service = OpenRouterService(apiKey: Secrets.openRouterApiKey);

    try {
      final result = await service.analyzeReceipt(base64);

      print("МАГАЗИН:");
      print(result.shop);

      print("ТОВАРОВ:");
      print(result.items.length);

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
          id: 'ITEM-${DateTime.now().millisecondsSinceEpoch}-${item.name}',

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

        categoryId: 'food',

        article: null,

        regularity: null,

        workDay: null,

        plannedAmount: null,

        processed: false,
      );

      await operationRepository.insertOperation(operation);

      await loadReceipts();
    } catch (e) {
      print("ОШИБКА: $e");
    } finally {
      setState(() {
        loadingCount--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Чеки')),

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
