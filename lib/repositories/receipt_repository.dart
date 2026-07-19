import '../database/database_helper.dart';
import '../models/receipt.dart';
import '../models/receipt_item.dart';

class ReceiptRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ============================================
  // Добавление чека
  // ============================================

  Future<void> insertReceipt(Receipt receipt) async {
    await _dbHelper.insertReceipt(receipt);
  }

  // ============================================
  // Получение всех чеков
  // ============================================

  Future<List<Receipt>> getReceipts() async {
    return await _dbHelper.getReceipts();
  }

  // ============================================
  // Добавление одного товара
  // ============================================

  Future<void> insertReceiptItem(ReceiptItem item) async {
    await _dbHelper.insertReceiptItem(item);
  }

  // ============================================
  // Обновление товара чека
  // ============================================

  Future<void> updateReceiptItem(ReceiptItem item) async {
    await _dbHelper.updateReceiptItem(item);
  }

  Future<void> recalculateReceiptAmount(String receiptId) async {
    final amount = await _dbHelper.recalculateReceiptAmount(receiptId);

    await _dbHelper.updateOperationAmount(receiptId, amount);
  }

  // ============================================
  // Обновление чека
  // ============================================

  Future<void> updateReceipt(Receipt receipt) async {
    await _dbHelper.updateReceipt(receipt);
  }

  // ============================================
  // Добавление списка товаров
  // ============================================

  Future<void> insertReceiptItems(List<ReceiptItem> items) async {
    await _dbHelper.insertReceiptItems(items);
  }

  // ============================================
  // Получение товаров чека
  // ============================================

  Future<List<ReceiptItem>> getReceiptItems(String receiptId) async {
    return await _dbHelper.getReceiptItems(receiptId);
  }

  // ============================================
  // Удаление чека
  // ============================================

  Future<void> deleteReceipt(String receiptId) async {
    await _dbHelper.deleteReceipt(receiptId);
  }

  Future<void> updateReceiptAmount(String receiptId, double amount) async {
    await _dbHelper.updateOperationAmount(receiptId, amount);
  }

  Future<Receipt?> getReceiptById(String id) async {
    return await _dbHelper.getReceiptById(id);
  }

  Future<void> insertReceiptWithItems(
    Receipt receipt,
    List<ReceiptItem> items,
  ) async {
    await _dbHelper.insertReceiptWithItems(receipt, items);
  }
}
