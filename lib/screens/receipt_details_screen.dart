import 'package:flutter/material.dart';

import '../models/receipt.dart';
import '../models/receipt_item.dart';
import '../repositories/receipt_repository.dart';
import 'edit_receipt_screen.dart';

class ReceiptDetailsScreen extends StatefulWidget {
  final Receipt receipt;

  const ReceiptDetailsScreen({super.key, required this.receipt});

  @override
  State<ReceiptDetailsScreen> createState() => _ReceiptDetailsScreenState();
}

class _ReceiptDetailsScreenState extends State<ReceiptDetailsScreen> {
  final ReceiptRepository repository = ReceiptRepository();

  List<ReceiptItem> items = [];

  late Receipt currentReceipt;

  @override
  void initState() {
    super.initState();

    currentReceipt = widget.receipt;

    loadData();
  }

  Future<void> loadData() async {
    final receipt = await repository.getReceiptById(currentReceipt.id);

    final receiptItems = await repository.getReceiptItems(currentReceipt.id);

    setState(() {
      if (receipt != null) {
        currentReceipt = receipt;
      }

      items = receiptItems;
    });
  }

  @override
  Widget build(BuildContext context) {
    final receipt = currentReceipt;

    return Scaffold(
      appBar: AppBar(
        title: Text(receipt.shop),

        actions: [
          IconButton(
            icon: const Icon(Icons.edit),

            onPressed: () async {
              final updatedReceipt = await Navigator.push(
                context,

                MaterialPageRoute(
                  builder: (context) =>
                      EditReceiptScreen(receipt: currentReceipt),
                ),
              );

              if (updatedReceipt != null) {
                await loadData();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),

            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,

                builder: (context) {
                  return AlertDialog(
                    title: const Text('Удалить чек?'),

                    content: const Text('Чек и операция будут удалены.'),

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

                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: loadData,

        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),

          child: Padding(
            padding: const EdgeInsets.all(16),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  receipt.shop,

                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(receipt.date.toString()),

                const SizedBox(height: 16),

                Text(
                  'Всего: ${receipt.amount.toStringAsFixed(2)} ₽',

                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Товары:',

                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                SizedBox(
                  height: 300,

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
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
