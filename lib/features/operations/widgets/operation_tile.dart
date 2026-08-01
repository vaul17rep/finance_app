/// Виджет для отображения операции в списке.
///
/// Отображает тип операции, сумму, дату и пометку о переводе.

import 'package:flutter/material.dart';

import '../../../models/operation.dart';
import '../../../models/operation_type.dart';

/// Виджет для отображения операции в списке.
class OperationTile extends StatelessWidget {
  final Operation operation;
  final VoidCallback? onTap;

  const OperationTile({super.key, required this.operation, this.onTap});

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  bool get _isExpense {
    return operation.type == OperationType.expense ||
        operation.type == OperationType.repayment ||
        (operation.type == OperationType.adjustment && operation.amount < 0);
  }

  String get _subtitle {
    final parts = <String>[];

    // Тип операции
    if (operation.isTransfer) {
      parts.add('Перевод');
    } else if (operation.receiptId != null) {
      parts.add('Чек');
    } else {
      parts.add('Операция');
    }

    // Дата
    parts.add(_formatDate(operation.date));

    return parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final isReceipt = operation.receiptId != null;

    return ListTile(
      leading: CircleAvatar(
        child: Icon(
          operation.isTransfer
              ? Icons.swap_horiz
              : (isReceipt ? Icons.receipt_long : Icons.swap_horiz),
        ),
      ),
      title: Text(
        operation.shop ??
            (operation.comment.isEmpty
                ? operation.type.name
                : operation.comment),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(_subtitle),
      trailing: Text(
        _isExpense
            ? '-${operation.amount.abs().toStringAsFixed(2)} ₽'
            : '+${operation.amount.toStringAsFixed(2)} ₽',
        style: TextStyle(
          color: _isExpense ? Colors.red : Colors.green,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: onTap,
    );
  }
}
