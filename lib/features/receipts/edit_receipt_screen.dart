import 'package:flutter/material.dart';

import '../../models/receipt.dart';
import '../../data/repositories/receipt_repository.dart';
import '../../models/receipt_item.dart';
import 'edit_receipt_item_screen.dart';

class EditReceiptScreen extends StatefulWidget {
  final Receipt receipt;

  const EditReceiptScreen({super.key, required this.receipt});

  @override
  State<EditReceiptScreen> createState() => _EditReceiptScreenState();
}

class _EditReceiptScreenState extends State<EditReceiptScreen> {
  final ReceiptRepository repository = ReceiptRepository();

  late TextEditingController shopController;
  late TextEditingController commentController;

  late DateTime selectedDate;
  late TimeOfDay selectedTime;
  List<ReceiptItem> items = [];
  bool hasChanges = false;

  @override
  void initState() {
    super.initState();

    loadItems();

    shopController = TextEditingController(text: widget.receipt.shop);

    shopController.addListener(() {
      setState(() {
        hasChanges = true;
      });
    });

    commentController = TextEditingController(
      text: widget.receipt.comment ?? '',
    );

    commentController.addListener(() {
      setState(() {
        hasChanges = true;
      });
    });

    selectedDate = widget.receipt.date;

    if (widget.receipt.time != null && widget.receipt.time!.contains(":")) {
      final parts = widget.receipt.time!.split(":");

      selectedTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    } else {
      selectedTime = const TimeOfDay(hour: 0, minute: 0);
    }
  }

  Future<bool> confirmExit() async {
    if (!hasChanges) {
      return true;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Выйти без сохранения?'),

          content: const Text('Изменения будут потеряны.'),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Остаться'),
            ),

            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Выйти'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<void> loadItems() async {
    final result = await repository.getReceiptItems(widget.receipt.id);

    setState(() {
      items = result;
    });
  }

  @override
  void dispose() {
    shopController.dispose();

    commentController.dispose();

    super.dispose();
  }

  Future<void> save() async {
    final total = items.fold<double>(0, (sum, item) => sum + item.total);

    final updatedReceipt = widget.receipt.copyWith(
      shop: shopController.text,

      comment: commentController.text,

      date: DateTime(selectedDate.year, selectedDate.month, selectedDate.day),

      time:
          '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
      amount: total,
    );

    hasChanges = false;

    await repository.updateReceipt(updatedReceipt);

    await repository.updateReceiptAmount(updatedReceipt.id, total);

    if (mounted) {
      Navigator.pop(context, updatedReceipt);
    }
  }

  Future<void> selectDate() async {
    final result = await showDatePicker(
      context: context,

      initialDate: selectedDate,

      firstDate: DateTime(2000),

      lastDate: DateTime(2100),
    );

    if (result != null) {
      setState(() {
        selectedDate = result;
        hasChanges = true;
      });
    }
  }

  Future<void> selectTime() async {
    final result = await showTimePicker(
      context: context,

      initialTime: selectedTime,
    );

    if (result != null) {
      setState(() {
        selectedTime = result;
        hasChanges = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,

      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final canExit = await confirmExit();

        if (canExit && context.mounted) {
          Navigator.pop(context);
        }
      },

      child: Scaffold(
        appBar: AppBar(
          title: const Text('Редактирование чека'),

          actions: [IconButton(icon: const Icon(Icons.save), onPressed: save)],
        ),

        body: Padding(
          padding: const EdgeInsets.all(16),

          child: Column(
            children: [
              TextField(
                controller: shopController,

                decoration: const InputDecoration(labelText: 'Магазин'),
              ),

              const SizedBox(height: 16),

              Column(
                children: [
                  ListTile(
                    title: const Text('Дата'),

                    subtitle: Text(
                      '${selectedDate.day}.${selectedDate.month}.${selectedDate.year}',
                    ),

                    trailing: const Icon(Icons.calendar_today),

                    onTap: selectDate,
                  ),

                  ListTile(
                    title: const Text('Время'),

                    subtitle: Text(selectedTime.format(context)),

                    trailing: const Icon(Icons.access_time),

                    onTap: selectTime,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              TextField(
                controller: commentController,

                decoration: const InputDecoration(labelText: 'Комментарий'),

                maxLines: 3,
              ),
              const SizedBox(height: 20),

              const Text(
                'Товары:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              Expanded(
                child: items.isEmpty
                    ? const Center(child: Text('Товаров нет'))
                    : ListView.builder(
                        itemCount: items.length,

                        itemBuilder: (context, index) {
                          final item = items[index];

                          return ListTile(
                            title: Text(item.name),

                            subtitle: Text(
                              '${item.quantity} ${item.unit ?? ''}',
                            ),

                            trailing: Text(
                              '${item.total.toStringAsFixed(2)} ₽',
                            ),

                            onTap: () async {
                              final updatedItem = await Navigator.push(
                                context,

                                MaterialPageRoute(
                                  builder: (context) =>
                                      EditReceiptItemScreen(item: item),
                                ),
                              );

                              if (updatedItem != null) {
                                await loadItems();

                                setState(() {
                                  hasChanges = true;
                                });
                              }
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
