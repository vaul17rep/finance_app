import 'package:flutter/material.dart';

import '../../models/operation.dart';
import '../../data/repositories/operation_repository.dart';
import '../receipts/receipt_details_screen.dart';
import 'operation_details_screen.dart';
import '../../data/repositories/receipt_repository.dart';
import 'add_operation_screen.dart';
import 'dart:async';
import 'widgets/operation_tile.dart';
import '../../models/operation_type.dart';

class PendingDelete {
  final Operation operation;
  final int index;

  Timer? timer;

  PendingDelete({required this.operation, required this.index});
}

enum OperationFilter { all, receipts, operations, income, expenses }

class OperationsScreen extends StatefulWidget {
  const OperationsScreen({super.key});

  @override
  State<OperationsScreen> createState() => _OperationsScreenState();
}

class _OperationsScreenState extends State<OperationsScreen> {
  final OperationRepository repository = OperationRepository();
  final ReceiptRepository receiptRepository = ReceiptRepository();
  final List<PendingDelete> pendingDeletes = [];

  List<Operation> operations = [];
  List<Operation> filteredOperations = [];

  OperationFilter filter = OperationFilter.all;

  void updateFilteredOperations() {
    switch (filter) {
      case OperationFilter.all:
        filteredOperations = List.from(operations);
        break;

      case OperationFilter.receipts:
        filteredOperations = operations
            .where((e) => e.receiptId != null)
            .toList();
        break;

      case OperationFilter.operations:
        filteredOperations = operations
            .where((e) => e.receiptId == null)
            .toList();
        break;

      case OperationFilter.income:
        filteredOperations = operations.where((e) {
          return e.type == OperationType.income;
        }).toList();
        break;

      case OperationFilter.expenses:
        filteredOperations = operations.where((e) {
          return e.type == OperationType.expense ||
              e.type == OperationType.repayment ||
              (e.type == OperationType.adjustment && e.amount < 0);
        }).toList();
        break;
    }
  }

  void restoreOperation(PendingDelete item) {
    item.timer?.cancel();

    pendingDeletes.remove(item);

    setState(() {
      final index = item.index <= operations.length
          ? item.index
          : operations.length;

      operations.insert(index, item.operation);
      operations.sort((a, b) => b.date.compareTo(a.date));
      updateFilteredOperations();
    });
  }

  @override
  void initState() {
    super.initState();

    loadOperations();
  }

  Future<void> loadOperations() async {
    final result = await repository.getOperations();

    result.sort((a, b) => b.date.compareTo(a.date));

    setState(() {
      operations = result;

      updateFilteredOperations();
    });
  }

  Widget _filterButton(String text, OperationFilter value) {
    final selected = filter == value;

    return Padding(
      padding: const EdgeInsets.only(right: 8),

      child: ChoiceChip(
        label: Text(text),

        selected: selected,

        onSelected: (_) {
          setState(() {
            filter = value;
            updateFilteredOperations();
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Операции')),

      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(
                height: 55,

                child: ListView(
                  scrollDirection: Axis.horizontal,

                  padding: const EdgeInsets.symmetric(horizontal: 12),

                  children: [
                    _filterButton('📋 Все', OperationFilter.all),

                    _filterButton('🧾 Чеки', OperationFilter.receipts),

                    _filterButton('✏️ Вручную', OperationFilter.operations),

                    _filterButton('💰 Доходы', OperationFilter.income),

                    _filterButton('💸 Расходы', OperationFilter.expenses),
                  ],
                ),
              ),

              Expanded(
                child: operations.isEmpty
                    ? const Center(child: Text('Операций нет'))
                    : RefreshIndicator(
                        onRefresh: loadOperations,

                        child: ListView.builder(
                          itemCount: filteredOperations.length,

                          itemBuilder: (context, index) {
                            final operation = filteredOperations[index];

                            return Dismissible(
                              key: Key(operation.id),

                              direction: DismissDirection.endToStart,

                              background: Container(
                                color: Colors.red,

                                alignment: Alignment.centerRight,

                                padding: const EdgeInsets.only(right: 20),

                                child: const Icon(Icons.delete),
                              ),

                              onDismissed: (_) {
                                final deletedOperation = operation;

                                final item = PendingDelete(
                                  operation: deletedOperation,
                                  index: operations.indexWhere(
                                    (e) => e.id == deletedOperation.id,
                                  ),
                                );

                                setState(() {
                                  operations.removeWhere(
                                    (e) => e.id == deletedOperation.id,
                                  );

                                  updateFilteredOperations();

                                  pendingDeletes.insert(0, item);

                                  if (pendingDeletes.length > 3) {
                                    pendingDeletes.removeLast();
                                  }
                                });

                                item.timer = Timer(
                                  const Duration(seconds: 5),

                                  () async {
                                    if (!pendingDeletes.contains(item)) {
                                      return;
                                    }

                                    pendingDeletes.remove(item);

                                    await repository.deleteOperation(
                                      deletedOperation.id,
                                    );

                                    if (mounted) {
                                      setState(() {
                                        updateFilteredOperations();
                                      });
                                    }
                                  },
                                );
                              },

                              child: OperationTile(
                                operation: operation,

                                onTap: () async {
                                  if (operation.receiptId != null) {
                                    final receipt = await receiptRepository
                                        .getReceiptById(operation.receiptId!);

                                    if (receipt != null && context.mounted) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ReceiptDetailsScreen(
                                            receipt: receipt,
                                          ),
                                        ),
                                      );
                                    }
                                  } else {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => OperationDetailsScreen(
                                          operation: operation,
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
          if (pendingDeletes.isNotEmpty)
            Positioned(
              left: 12,
              right: 12,
              bottom: 90,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: pendingDeletes.map((item) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      elevation: 8,
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.transparent,
                      child: Container(
                        height: 60,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade900.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(16),
                        ),

                        child: Row(
                          children: [
                            const Icon(
                              Icons.delete,
                              color: Colors.white70,
                              size: 26,
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: Text(
                                item.operation.shop ?? 'Без описания',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                              ),
                            ),

                            TextButton(
                              onPressed: () {
                                restoreOperation(item);
                              },

                              child: const Text(
                                'Отменить',
                                style: TextStyle(
                                  color: Color.fromARGB(255, 211, 106, 106),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<Operation>(
            context,

            MaterialPageRoute(builder: (_) => const AddOperationScreen()),
          );

          if (result != null) {
            await repository.insertOperation(result);

            await loadOperations();
          }
        },

        child: const Icon(Icons.add),
      ),
    );
  }
}
