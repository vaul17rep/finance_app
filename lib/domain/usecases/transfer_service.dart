/// Сервис для создания переводов между счетами.
///
/// Координирует создание двух операций (expense и income)
/// с одинаковым transferId в рамках атомарной транзакции.
///
/// Связанные документы:
/// - 03_Domain_Model — Transfer
/// - 04_Financial_Rules — правила переводов

import 'package:uuid/uuid.dart';
import '../../data/database/database_helper.dart';
import '../../models/operation.dart';
import '../../models/operation_type.dart';
import '../../data/repositories/account_repository.dart';
import '../../data/repositories/operation_repository.dart';
import '../../domain/entities/transfer.dart';
import 'financial_calculator.dart';

/// Запрос на создание перевода.
class TransferRequest {
  final String sourceAccountId;
  final String destinationAccountId;
  final double amount;
  final DateTime date;
  final String? comment;

  TransferRequest({
    required this.sourceAccountId,
    required this.destinationAccountId,
    required this.amount,
    required this.date,
    this.comment,
  });
}

/// Сервис для создания переводов между счетами.
class TransferService {
  final AccountRepository _accountRepository;
  final OperationRepository _operationRepository;
  final FinancialCalculator _financialCalculator;
  final DatabaseHelper _dbHelper;

  TransferService({
    AccountRepository? accountRepository,
    OperationRepository? operationRepository,
    FinancialCalculator? financialCalculator,
    DatabaseHelper? dbHelper,
  }) : _accountRepository = accountRepository ?? AccountRepository(),
       _operationRepository = operationRepository ?? OperationRepository(),
       _financialCalculator = financialCalculator ?? FinancialCalculator(),
       _dbHelper = dbHelper ?? DatabaseHelper.instance;

  /// Создаёт перевод между счетами.
  Future<void> createTransfer(TransferRequest request) async {
    // 1. Валидация
    if (request.sourceAccountId == request.destinationAccountId) {
      throw TransferException('Нельзя перевести на тот же счёт');
    }
    if (request.amount <= 0) {
      throw TransferException('Сумма должна быть больше 0');
    }

    // 2. Проверка существования счетов
    final accounts = await _accountRepository.getAccounts();
    final sourceAccount = accounts.firstWhere(
      (a) => a.id == request.sourceAccountId,
      orElse: () => throw AccountNotFoundException('Счёт-источник не найден'),
    );
    final destinationAccount = accounts.firstWhere(
      (a) => a.id == request.destinationAccountId,
      orElse: () => throw AccountNotFoundException('Счёт-назначение не найден'),
    );

    // 3. Проверка баланса источника
    final sourceOperations = await _operationRepository.getOperationsByAccount(
      request.sourceAccountId,
    );
    final state = _financialCalculator.calculate(
      sourceAccount,
      sourceOperations,
    );
    if (state.balance < request.amount) {
      throw InsufficientBalanceException(
        'Недостаточно средств на счёте ${sourceAccount.name}',
      );
    }

    // 4. Генерация ID
    final transferId = const Uuid().v4();

    // 5. Создание Transfer
    final transfer = Transfer(
      id: transferId,
      sourceAccountId: request.sourceAccountId,
      destinationAccountId: request.destinationAccountId,
      amount: request.amount,
      date: request.date,
      comment: request.comment,
      createdAt: DateTime.now(),
    );

    // 6. Атомарное сохранение в одной транзакции
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      // 6.1 Сохраняем Transfer
      await txn.insert('transfers', transfer.toMap());

      // 6.2 Создаём операцию списания (expense) со счёта-источника
      final expenseOp = Operation(
        id: const Uuid().v4(),
        type: OperationType.expense,
        amount: request.amount,
        comment: request.comment ?? 'Перевод на ${destinationAccount.name}',
        date: request.date,
        accountId: request.sourceAccountId,
        transferId: transferId,
      );

      // 6.3 Создаём операцию зачисления (income) на счёт-назначения
      final incomeOp = Operation(
        id: const Uuid().v4(),
        type: OperationType.income,
        amount: request.amount,
        comment: request.comment ?? 'Перевод с ${sourceAccount.name}',
        date: request.date,
        accountId: request.destinationAccountId,
        transferId: transferId,
      );

      // 6.4 Сохраняем обе операции в рамках одной транзакции
      await txn.insert('operations', expenseOp.toMap());
      await txn.insert('operations', incomeOp.toMap());
    });
  }
}

/// Исключение: ошибка перевода.
class TransferException implements Exception {
  final String message;
  TransferException(this.message);
  @override
  String toString() => 'TransferException: $message';
}

/// Исключение: недостаточно средств.
class InsufficientBalanceException implements Exception {
  final String message;
  InsufficientBalanceException(this.message);
  @override
  String toString() => 'InsufficientBalanceException: $message';
}

/// Исключение: счёт не найден.
class AccountNotFoundException implements Exception {
  final String message;
  AccountNotFoundException(this.message);
  @override
  String toString() => 'AccountNotFoundException: $message';
}
