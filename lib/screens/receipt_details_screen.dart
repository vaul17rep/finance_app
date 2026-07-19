import 'package:flutter/material.dart';

import '../models/receipt.dart';
import '../models/receipt_item.dart';
import '../repositories/receipt_repository.dart';

class ReceiptDetailsScreen extends StatefulWidget {
  final Receipt receipt;

  const ReceiptDetailsScreen({super.key, required this.receipt});

  @override
  State<ReceiptDetailsScreen> createState() => _ReceiptDetailsScreenState();
}

class _ReceiptDetailsScreenState extends State<ReceiptDetailsScreen> {
  final ReceiptRepository repository = ReceiptRepository();

  List<ReceiptItem> items = [];

  @override
  void initState() {
    super.initState();

    loadItems();
  }

  Future<void> loadItems() async {
    final result = await repository.getReceiptItems(widget.receipt.id);

    setState(() {
      items = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final receipt = widget.receipt;

    return Scaffold(
      appBar: AppBar(
        title: Text(receipt.shop),

        actions: [
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

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Text(
              receipt.shop,

              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Text(receipt.date.toString()),

            const SizedBox(height: 16),

            Text(
              'Всего: ${receipt.amount.toStringAsFixed(2)} ₽',

              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            const Text(
              'Товары:',

              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: items.isEmpty
                  ? const Center(child: Text('Товаров нет'))
                  : ListView.builder(
                      itemCount: items.length,

                      itemBuilder: (context, index) {
                        final item = items[index];

                        return ListTile(
                          title: Text(item.name),

                          subtitle: Text('${item.quantity} ${item.unit ?? ''}'),

                          trailing: Text('${item.total.toStringAsFixed(2)} ₽'),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
