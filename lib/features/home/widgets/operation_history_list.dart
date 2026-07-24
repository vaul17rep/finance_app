import 'package:flutter/material.dart';

import '../../../models/operation.dart';
import '../../../models/operation_type.dart';

import '../../operations/operation_details_screen.dart';
import '../../receipts/receipt_details_screen.dart';

import '../../../data/repositories/receipt_repository.dart';

class OperationHistoryList extends StatelessWidget {
  final List<Operation> operations;

  const OperationHistoryList({super.key, required this.operations});

  Future<void> openOperation(BuildContext context, Operation operation) async {
    if (operation.receiptId != null) {
      final receipt = await ReceiptRepository().getReceiptById(
        operation.receiptId!,
      );

      if (receipt != null && context.mounted) {
        Navigator.push(
          context,

          MaterialPageRoute(
            builder: (_) => ReceiptDetailsScreen(receipt: receipt),
          ),
        );
      }
    } else {
      Navigator.push(
        context,

        MaterialPageRoute(
          builder: (_) => OperationDetailsScreen(operation: operation),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (operations.isEmpty) {
      return const Center(child: Text('Операций пока нет'));
    }

    return Column(
      children: operations.map((op) {
        final isReceipt = op.receiptId != null;

        return ListTile(
          leading: CircleAvatar(
            child: Icon(isReceipt ? Icons.receipt_long : Icons.swap_horiz),
          ),

          title: Text(
            op.shop ?? (op.comment.isEmpty ? op.type.name : op.comment),

            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          subtitle: Text(
            isReceipt
                ? 'Чек • ${op.date.day}.${op.date.month}'
                : 'Операция • ${op.date.day}.${op.date.month}',
          ),

          trailing: Text(
            op.type == OperationType.expense ||
                    op.type == OperationType.repayment ||
                    (op.type == OperationType.adjustment && op.amount < 0)
                ? '-${op.amount.abs().toStringAsFixed(2)} ₽'
                : '+${op.amount.toStringAsFixed(2)} ₽',
          ),

          onTap: () {
            openOperation(context, op);
          },
        );
      }).toList(),
    );
  }
}
