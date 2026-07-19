import '../database/database_helper.dart';
import '../models/operation.dart';
import '../models/operation_type.dart';

class OperationRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<Operation>> getOperations() async {
    final data = await _dbHelper.getOperations();

    return data.map((json) {
      return Operation(
        id: json['id'].toString(),

        type: OperationType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => OperationType.expense,
        ),

        amount: (json['amount'] as num).toDouble(),

        comment: json['comment'] ?? '',

        date: DateTime.parse(json['date'].toString()),

        shop: json['shop'] as String?,

        article: json['article'] as String?,

        category: json['category'] as String?,

        receiptId: json['receiptId'] as String?,
      );
    }).toList();
  }

  // ============================================
  // Обновление операции связанной с чеком
  // ============================================

  Future<void> updateOperationByReceiptId(Operation operation) async {
    await _dbHelper.updateOperationByReceiptId(
      operation.receiptId!,
      operation.amount,
      operation.shop ?? '',
      operation.date,
    );
  }



  Future<void> insertOperation(Operation operation) async {
    await _dbHelper.insertOperation({
      'id': operation.id,

      'type': operation.type.name,

      'amount': operation.amount,

      'comment': operation.comment,

      'date': operation.date.toIso8601String(),

      'shop': operation.shop,

      'article': operation.article,

      'category': operation.category,

      'receiptId': operation.receiptId,
    });
  }

  Future<void> deleteByReceiptId(String receiptId) async {
    await _dbHelper.deleteOperationByReceiptId(receiptId);
  }
}
