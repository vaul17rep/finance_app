import 'package:flutter/material.dart';

import '../models/operation.dart';
import '../repositories/operation_repository.dart';
import '../models/operation_type.dart';
import 'receipt_details_screen.dart';
import 'operation_details_screen.dart';
import '../repositories/receipt_repository.dart';

class OperationsScreen extends StatefulWidget {
  const OperationsScreen({super.key});

  @override
  State<OperationsScreen> createState() => _OperationsScreenState();
}

class _OperationsScreenState extends State<OperationsScreen> {
  final OperationRepository repository = OperationRepository();

  final ReceiptRepository receiptRepository = ReceiptRepository();

  List<Operation> operations = [];

  @override
  void initState() {
    super.initState();

    loadOperations();
  }

  Future<void> loadOperations() async {
    final result = await repository.getOperations();

    setState(() {
      operations = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Операции')),

      body: operations.isEmpty
          ? const Center(child: Text('Операций нет'))
          : RefreshIndicator(
              onRefresh: loadOperations,

              child: ListView.builder(
                itemCount: operations.length,

                itemBuilder: (context, index) {
                  final operation = operations[index];

                  return Dismissible(
                    key: Key(operation.id),

                    direction: DismissDirection.endToStart,

                    background: Container(
                      color: Colors.red,

                      alignment: Alignment.centerRight,

                      padding: const EdgeInsets.only(right: 20),

                      child: const Icon(Icons.delete),
                    ),

                    onDismissed: (_) async {
                      await repository.deleteOperation(operation.id);

                      await loadOperations();
                    },

                    child: ListTile(
                      onTap: () async {
                        if (operation.receiptId != null) {
                          final receipt = await receiptRepository
                              .getReceiptById(operation.receiptId!);

                          if (receipt != null && context.mounted) {
                            Navigator.push(
                              context,

                              MaterialPageRoute(
                                builder: (context) =>
                                    ReceiptDetailsScreen(receipt: receipt),
                              ),
                            );
                          }
                        } else {
                          Navigator.push(
                            context,

                            MaterialPageRoute(
                              builder: (context) =>
                                  OperationDetailsScreen(operation: operation),
                            ),
                          );
                        }
                      },
                      title: Text(operation.shop ?? 'Без описания'),

                      subtitle: Text(operation.date.toString()),

                      trailing: Text(
                        '${operation.type == OperationType.expense ? "-" : "+"}'
                        '${operation.amount.toStringAsFixed(2)} ₽',
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
