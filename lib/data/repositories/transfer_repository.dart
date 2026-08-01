/// Репозиторий для работы с переводами.
///
/// Отвечает за сохранение и восстановление Transfer из операций.
///
/// Связанные документы:
/// - 03_Domain_Model — Transfer
/// - 05_Database_Specification — таблицы transfers и operations

import '../database/database_helper.dart';
import '../../domain/entities/transfer.dart';
import '../../models/operation.dart';
import '../../models/operation_type.dart';
import 'operation_repository.dart';

/// Репозиторий для работы с переводами.
class TransferRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final OperationRepository _operationRepository = OperationRepository();

  /// Сохраняет перевод и связанные операции атомарно.
  Future<void> saveTransferWithOperations(
    Transfer transfer,
    List<Operation> operations,
  ) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      // Сохраняем Transfer
      await txn.insert('transfers', transfer.toMap());

      // Сохраняем операции
      for (final op in operations) {
        await txn.insert('operations', op.toMap());
      }
    });
  }

  /// Находит Transfer по ID.
  Future<Transfer?> findById(String id) async {
    final operations = await _operationRepository.getOperationsByTransferId(id);
    if (operations.length != 2) return null;

    try {
      final expense = operations.firstWhere(
        (op) => op.type == OperationType.expense,
      );
      final income = operations.firstWhere(
        (op) => op.type == OperationType.income,
      );
      return Transfer.fromOperations(expense, income);
    } catch (_) {
      return null;
    }
  }

  /// Получает все переводы (оптимизированный запрос).
  Future<List<Transfer>> getAllTransfers() async {
    // 1. Получаем все transfers
    final transfersData = await _dbHelper.getTransfers();
    if (transfersData.isEmpty) return [];

    // 2. Получаем все transferId
    final transferIds = transfersData.map((t) => t['id'] as String).toList();

    // 3. Загружаем все операции для этих transferId одним запросом
    final allOperations = await _operationRepository.getOperationsByTransferIds(
      transferIds,
    );

    // 4. Группируем операции по transferId
    final operationsByTransferId = <String, List<Operation>>{};
    for (final op in allOperations) {
      if (op.transferId != null) {
        operationsByTransferId.putIfAbsent(op.transferId!, () => []).add(op);
      }
    }

    // 5. Собираем Transfer'ы
    final transfers = <Transfer>[];
    for (final data in transfersData) {
      final id = data['id'] as String;
      final ops = operationsByTransferId[id] ?? [];
      if (ops.length == 2) {
        try {
          final expense = ops.firstWhere(
            (op) => op.type == OperationType.expense,
          );
          final income = ops.firstWhere(
            (op) => op.type == OperationType.income,
          );
          transfers.add(Transfer.fromOperations(expense, income));
        } catch (_) {
          // Пропускаем некорректные переводы
        }
      }
    }
    return transfers;
  }

  /// Находит все переводы для счёта.
  Future<List<Transfer>> findByAccountId(String accountId) async {
    final allTransfers = await getAllTransfers();
    return allTransfers
        .where(
          (t) =>
              t.sourceAccountId == accountId ||
              t.destinationAccountId == accountId,
        )
        .toList();
  }

  /// Находит переводы по временному диапазону.
  Future<List<Transfer>> findByDateRange(DateTime start, DateTime end) async {
    final allTransfers = await getAllTransfers();
    return allTransfers
        .where((t) => t.date.isAfter(start) && t.date.isBefore(end))
        .toList();
  }

  /// Удаляет перевод и связанные операции.
  Future<void> deleteTransfer(String id) async {
    final operations = await _operationRepository.getOperationsByTransferId(id);
    for (final op in operations) {
      await _operationRepository.deleteOperation(op.id);
    }
    await _dbHelper.deleteTransfer(id);
  }
}
