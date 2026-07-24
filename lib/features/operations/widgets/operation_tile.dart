import 'package:flutter/material.dart';

import '../../../models/operation.dart';
import '../../../models/operation_type.dart';

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

  @override
  Widget build(BuildContext context) {
    final isReceipt = operation.receiptId != null;

    return ListTile(
      leading: CircleAvatar(
        child: Icon(isReceipt ? Icons.receipt_long : Icons.swap_horiz),
      ),

      title: Text(
        operation.shop ??
            (operation.comment.isEmpty
                ? operation.type.name
                : operation.comment),

        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),

      subtitle: Text(
        '${isReceipt ? 'Чек' : 'Операция'} • ${_formatDate(operation.date)}',
      ),

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
