import 'package:flutter/material.dart';

import '../../models/receipt.dart';
import '../../data/repositories/receipt_repository.dart';

import 'receipt_details_screen.dart';

import '../../core/utils/date_utils.dart';

class ReceiptsScreen extends StatefulWidget {
  const ReceiptsScreen({super.key});

  @override
  State<ReceiptsScreen> createState() => _ReceiptsScreenState();
}

class _ReceiptsScreenState extends State<ReceiptsScreen> {
  final ReceiptRepository repository = ReceiptRepository();

  List<Receipt> receipts = [];

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

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),

                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.receipt_long),
                      ),

                      title: Text(
                        receipt.shop,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),

                      subtitle: Text(
                        '${formatDate(receipt.date)} • ${receipt.time ?? "00:00"}',
                      ),

                      trailing: SizedBox(
                        width: 120,

                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,

                          children: [
                            Flexible(
                              child: Text(
                                '${receipt.amount.toStringAsFixed(2)} ₽',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),

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
                    ),
                  );
                },
              ),
      ),
    );
  }
}
