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
import '../../core/theme/app_dimensions.dart';

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

  void _previousFilter() {
    const filters = OperationFilter.values;
    final currentIndex = filters.indexOf(filter);
    final newIndex = (currentIndex - 1 + filters.length) % filters.length;
    setState(() {
      filter = filters[newIndex];
      updateFilteredOperations();
    });
  }

  void _nextFilter() {
    const filters = OperationFilter.values;
    final currentIndex = filters.indexOf(filter);
    final newIndex = (currentIndex + 1) % filters.length;
    setState(() {
      filter = filters[newIndex];
      updateFilteredOperations();
    });
  }

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
        filteredOperations = operations
            .where((e) => e.type == OperationType.income)
            .toList();
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(
          text,
          style: theme.textTheme.labelMedium?.copyWith(
            color: selected
                ? colorScheme.onPrimary
                : colorScheme.onSurfaceVariant,
          ),
        ),
        selected: selected,
        selectedColor: colorScheme.primary,
        backgroundColor: colorScheme.surfaceVariant,
        showCheckmark: false,
        onSelected: (_) {
          setState(() {
            filter = value;
            updateFilteredOperations();
          });
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          side: BorderSide(
            color: selected ? colorScheme.primary : Colors.transparent,
            width: 1,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Операции'),
        backgroundColor: Colors.transparent,
      ),
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
                    ? Center(
                        child: Text(
                          'Операций нет',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
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
                                color: colorScheme.error,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                child: Icon(
                                  Icons.delete,
                                  color: colorScheme.onError,
                                ),
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
                                    if (!pendingDeletes.contains(item)) return;
                                    pendingDeletes.remove(item);
                                    await repository.deleteOperation(
                                      deletedOperation.id,
                                    );
                                    if (mounted) {
                                      setState(
                                        () => updateFilteredOperations(),
                                      );
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
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMedium,
                      ),
                      color: Colors.transparent,
                      child: Container(
                        height: 60,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceVariant.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusMedium,
                          ),
                          border: Border.all(
                            color: colorScheme.primary.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete,
                              color: colorScheme.error,
                              size: 26,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item.operation.shop ?? 'Без описания',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => restoreOperation(item),
                              style: TextButton.styleFrom(
                                foregroundColor: colorScheme.primary,
                                textStyle: theme.textTheme.labelMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              child: const Text('Отменить'),
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
      floatingActionButtonLocation: FloatingActionButtonLocation
          .centerFloat, // если хотите по центру, иначе endFloat
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton.small(
              heroTag: 'filter_left',
              shape: const CircleBorder(),
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.onPrimaryContainer,
              elevation: 4,
              onPressed: _previousFilter,
              child: const Icon(Icons.chevron_left),
            ),
            const SizedBox(width: 16),
            FloatingActionButton(
              heroTag: 'add_operation',
              shape: const CircleBorder(),
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              elevation: 6,
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
              child: const Icon(Icons.add, size: 30),
            ),
            const SizedBox(width: 16),
            FloatingActionButton.small(
              heroTag: 'filter_right',
              shape: const CircleBorder(),
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.onPrimaryContainer,
              elevation: 4,
              onPressed: _nextFilter,
              child: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }
}
