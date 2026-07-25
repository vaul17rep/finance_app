import 'package:flutter/material.dart';

import '../../models/operation.dart';
import '../../models/operation_type.dart';
import '../../data/repositories/operation_repository.dart';
import '../../data/services/category_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';

class OperationDetailsScreen extends StatefulWidget {
  final Operation operation;

  const OperationDetailsScreen({super.key, required this.operation});

  @override
  State<OperationDetailsScreen> createState() => _OperationDetailsScreenState();
}

class _OperationDetailsScreenState extends State<OperationDetailsScreen> {
  final OperationRepository repository = OperationRepository();

  late Operation operation;

  @override
  void initState() {
    super.initState();
    operation = widget.operation;
  }

  Future<void> delete() async {
    await repository.deleteOperation(operation.id);
    if (mounted) Navigator.pop(context);
  }

  bool get _isExpense {
    return operation.type == OperationType.expense ||
        operation.type == OperationType.repayment ||
        (operation.type == OperationType.adjustment && operation.amount < 0);
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final amountColor = _isExpense ? AppColors.expense : AppColors.income;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Операция'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline, color: colorScheme.error),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusLarge,
                    ),
                  ),
                  title: const Text('Удалить операцию?'),
                  content: const Text('Это действие нельзя отменить'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(
                        'Отмена',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.error,
                        foregroundColor: colorScheme.onError,
                      ),
                      child: const Text('Удалить'),
                    ),
                  ],
                ),
              );

              if (confirm == true) await delete();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Сумма
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: amountColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusSmall,
                      ),
                    ),
                    child: Text(
                      _isExpense ? 'Расход' : 'Доход',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: amountColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${_isExpense ? '-' : '+'}${operation.amount.abs().toStringAsFixed(2)} ₽',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: amountColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Карточка с деталями
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
              ),
              child: Column(
                children: [
                  _detailRow(
                    icon: Icons.description,
                    label: 'Описание',
                    value: operation.comment.isNotEmpty
                        ? operation.comment
                        : 'Без описания',
                  ),
                  if (operation.shop != null && operation.shop!.isNotEmpty) ...[
                    const Divider(height: 24),
                    _detailRow(
                      icon: Icons.store,
                      label: 'Магазин',
                      value: operation.shop!,
                    ),
                  ],
                  if (operation.categoryId != null) ...[
                    const Divider(height: 24),
                    _detailRow(
                      icon: Icons.category,
                      label: 'Категория',
                      value: CategoryService.getName(operation.categoryId),
                    ),
                  ],
                  const Divider(height: 24),
                  _detailRow(
                    icon: Icons.calendar_today,
                    label: 'Дата',
                    value: _formatDate(operation.date),
                  ),
                  if (operation.paymentType != null &&
                      operation.paymentType!.isNotEmpty) ...[
                    const Divider(height: 24),
                    _detailRow(
                      icon: Icons.payment,
                      label: 'Способ оплаты',
                      value: operation.paymentType!,
                    ),
                  ],
                  const Divider(height: 24),
                  _detailRow(
                    icon: Icons.swap_horiz,
                    label: 'Тип',
                    value: _typeName(operation.type),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.end,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _typeName(OperationType type) {
    switch (type) {
      case OperationType.expense:
        return 'Расход';
      case OperationType.income:
        return 'Доход';
      case OperationType.transfer:
        return 'Перевод';
      case OperationType.repayment:
        return 'Погашение';
      case OperationType.adjustment:
        return 'Корректировка';
    }
  }
}
