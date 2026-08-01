/// Сущность перевода между счетами.
///
/// Восстанавливается из двух операций (expense и income)
/// с одинаковым transferId.
///
/// Связанные документы:
/// - 03_Domain_Model — Transfer
/// - 04_Financial_Rules — правила переводов

import '../../models/operation.dart';
import '../../models/operation_type.dart';

/// Сущность перевода между счетами.
class Transfer {
  final String id;
  final String sourceAccountId;
  final String destinationAccountId;
  final double amount;
  final DateTime date;
  final String? comment;
  final String status;
  final DateTime createdAt;

  Transfer({
    required this.id,
    required this.sourceAccountId,
    required this.destinationAccountId,
    required this.amount,
    required this.date,
    this.comment,
    this.status = 'active',
    required this.createdAt,
  });

  /// Создаёт Transfer из двух операций.
  ///
  /// [expense] — операция списания (type = expense) со счёта-источника.
  /// [income] — операция зачисления (type = income) на счёт-назначения.
  ///
  /// Исключения:
  /// - [ArgumentError] — если операции не связаны через transferId
  /// - [ArgumentError] — если типы операций не соответствуют переводу
  factory Transfer.fromOperations(Operation expense, Operation income) {
    if (expense.transferId == null || expense.transferId != income.transferId) {
      throw ArgumentError('Operations are not linked by transferId');
    }
    if (expense.type != OperationType.expense ||
        income.type != OperationType.income) {
      throw ArgumentError('Invalid operation types for transfer');
    }
    return Transfer(
      id: expense.transferId!,
      sourceAccountId: expense.accountId!,
      destinationAccountId: income.accountId!,
      amount: expense.amount,
      date: expense.date,
      comment: expense.comment.isNotEmpty ? expense.comment : null,
      status: 'active',
      createdAt: expense.date,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
    };
  }
}
