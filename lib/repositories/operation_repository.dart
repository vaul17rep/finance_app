import '../database/database_helper.dart';
import '../models/operation.dart';

class OperationRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<Operation>> getOperations() async {
    final data = await _dbHelper.getOperations();
    return data.map((json) => Operation(
      id: json['id'].toString(),
      type: json['type'].toString(),
      amount: (json['amount'] as num).toDouble(),
      comment: json['comment'] ?? '',
      date: DateTime.parse(json['date'].toString()),
    )).toList();
  }

  Future<void> insertOperation(Operation operation) async {
    await _dbHelper.insertOperation({
      'id': operation.id,
      'type': operation.type,
      'amount': operation.amount,
      'comment': operation.comment,
      'date': operation.date.toIso8601String(),
    });
  }
}