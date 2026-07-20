// ignore_for_file: avoid_print

import '../database/database_helper.dart';
import '../models/operation.dart';


class OperationRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<Operation>> getOperations() async {
    final data = await _dbHelper.getOperations();

    return data.map((json) => Operation.fromMap(json)).toList();
  }

  // ============================================
  // Обновление операции связанной с чеком
  // ============================================

  Future<List<Operation>> debugOperations() async {
    final data = await _dbHelper.getOperations();

    print("===== OPERATIONS =====");

    for (var item in data) {
      print(item);
    }

    return data.map((json) => Operation.fromMap(json)).toList();
  }

  Future<List<Operation>> getOperationsByAccount(String accountId) async {
    final data = await _dbHelper.getOperationsByAccount(accountId);

    return data.map((json) => Operation.fromMap(json)).toList();
  }

  Future<void> updateOperationByReceiptId(Operation operation) async {
    await _dbHelper.updateOperationByReceiptId(
      operation.receiptId!,
      operation.amount,
      operation.shop ?? '',
      operation.date,
    );
  }

  Future<void> insertOperation(Operation operation) async {
    await _dbHelper.insertOperation(operation.toMap());
  }

  Future<void> deleteOperation(String id) async {
    await _dbHelper.deleteOperation(id);
  }

  Future<void> deleteByReceiptId(String receiptId) async {
    await _dbHelper.deleteOperationByReceiptId(receiptId);
  }
}
