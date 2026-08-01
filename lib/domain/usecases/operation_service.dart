/// Сервис для создания операций.
///
/// Инкапсулирует бизнес-логику создания операций:
/// - Валидация данных (существование счёта, корректность суммы)
/// - Формирование Operation с генерацией ID
/// - Сохранение через OperationRepository
///
/// Единая точка создания для всех типов операций.
///
/// Связанные документы:
/// - 03_Domain_Model — Operation
/// - 04_Financial_Rules — правила создания операций
/// - 02_Architecture — Application Logic Layer

import 'package:uuid/uuid.dart';
import '../../models/operation.dart';
import '../../models/operation_type.dart';
import '../../data/repositories/operation_repository.dart';
import '../../data/repositories/account_repository.dart';

/// Сервис для создания операций.
///
/// Инкапсулирует бизнес-логику создания операций:
/// - Валидация данных (существование счёта, корректность суммы)
/// - Формирование Operation с генерацией ID
/// - Сохранение через OperationRepository
///
/// Единая точка создания для всех типов операций.
class OperationService {
  final OperationRepository _operationRepository;
  final AccountRepository _accountRepository;

  OperationService({
    OperationRepository? operationRepository,
    AccountRepository? accountRepository,
  }) : _operationRepository = operationRepository ?? OperationRepository(),
       _accountRepository = accountRepository ?? AccountRepository();

  /// Создание операции.
  ///
  /// Параметры:
  /// - [accountId] — ID счёта, к которому привязана операция
  /// - [type] — тип операции (income, expense, adjustment, repayment)
  /// - [amount] — сумма операции (положительное число)
  /// - [description] — описание операции (будет использовано как comment)
  /// - [date] — дата операции (по умолчанию текущая)
  /// - [transferId] — ID перевода (опционально, только для операций перевода)
  /// - [shop] — магазин (опционально)
  /// - [article] — статья (опционально)
  /// - [categoryId] — ID категории (опционально)
  /// - [paymentType] — способ оплаты (опционально)
  /// - [receiptId] — ID чека (опционально)
  /// - [regularity] — регулярность (опционально)
  /// - [workDay] — рабочий день (опционально)
  /// - [plannedAmount] — плановая сумма (опционально)
  /// - [processed] — флаг обработки (по умолчанию false)
  ///
  /// Возвращает созданную операцию.
  ///
  /// Исключения:
  /// - [AccountNotFoundException] — если счёт не найден
  /// - [InvalidAmountException] — если сумма <= 0
  /// - [InvalidOperationTypeException] — если тип не поддерживается для операции
  Future<Operation> createOperation({
    required String accountId,
    required OperationType type,
    required double amount,
    required String description,
    DateTime? date,
    String? transferId,
    String? shop,
    String? article,
    String? categoryId,
    String? paymentType,
    String? receiptId,
    String? regularity,
    bool? workDay,
    double? plannedAmount,
    bool processed = false,
  }) async {
    // 1. Валидация суммы
    if (amount <= 0) {
      throw InvalidAmountException('Сумма должна быть больше 0');
    }

    // 2. Валидация типа операции
    if (type == OperationType.transfer) {
      throw InvalidOperationTypeException(
        'Для создания операций перевода используйте TransferService',
      );
    }

    // 3. Проверка существования счёта
    final accounts = await _accountRepository.getAccounts();
    final account = accounts.firstWhere(
      (a) => a.id == accountId,
      orElse: () =>
          throw AccountNotFoundException('Счёт с ID $accountId не найден'),
    );

    // 4. Формирование операции
    final operation = Operation(
      id: const Uuid().v4(),
      type: type,
      amount: amount,
      comment: description,
      date: date ?? DateTime.now(),
      shop: shop,
      article: article,
      categoryId: categoryId,
      paymentType: paymentType,
      receiptId: receiptId,
      accountId: accountId,
      regularity: regularity,
      workDay: workDay,
      plannedAmount: plannedAmount,
      processed: processed,
      transferId: transferId,
    );

    // 5. Сохранение
    await _operationRepository.insertOperation(operation);

    return operation;
  }

  /// Создание нескольких операций в рамках одной транзакции.
  ///
  /// Используется для атомарного создания связанных операций
  /// (например, двух операций перевода).
  ///
  /// Параметры:
  /// - [operations] — список параметров для создания операций
  ///
  /// Возвращает список созданных операций.
  ///
  /// Исключения:
  /// - [OperationCreationException] — если хотя бы одна операция не создалась
  Future<List<Operation>> createOperations(
    List<OperationCreationParams> operations,
  ) async {
    if (operations.isEmpty) {
      throw OperationCreationException('Список операций не может быть пустым');
    }

    // Проверяем, что все операции имеют одинаковый transferId (если указан)
    final transferIds = operations
        .map((p) => p.transferId)
        .where((id) => id != null)
        .toSet();
    if (transferIds.length > 1) {
      throw OperationCreationException(
        'Все операции должны иметь одинаковый transferId',
      );
    }

    // Создаём все операции
    final createdOperations = <Operation>[];
    for (final params in operations) {
      final operation = await createOperation(
        accountId: params.accountId,
        type: params.type,
        amount: params.amount,
        description: params.description,
        date: params.date,
        transferId: params.transferId,
        shop: params.shop,
        article: params.article,
        categoryId: params.categoryId,
        paymentType: params.paymentType,
        receiptId: params.receiptId,
        regularity: params.regularity,
        workDay: params.workDay,
        plannedAmount: params.plannedAmount,
        processed: params.processed,
      );
      createdOperations.add(operation);
    }

    return createdOperations;
  }
}

/// Параметры создания операции.
class OperationCreationParams {
  final String accountId;
  final OperationType type;
  final double amount;
  final String description;
  final DateTime? date;
  final String? transferId;
  final String? shop;
  final String? article;
  final String? categoryId;
  final String? paymentType;
  final String? receiptId;
  final String? regularity;
  final bool? workDay;
  final double? plannedAmount;
  final bool processed;

  OperationCreationParams({
    required this.accountId,
    required this.type,
    required this.amount,
    required this.description,
    this.date,
    this.transferId,
    this.shop,
    this.article,
    this.categoryId,
    this.paymentType,
    this.receiptId,
    this.regularity,
    this.workDay,
    this.plannedAmount,
    this.processed = false,
  });
}

/// Исключение: счёт не найден.
class AccountNotFoundException implements Exception {
  final String message;
  AccountNotFoundException(this.message);
  @override
  String toString() => 'AccountNotFoundException: $message';
}

/// Исключение: неверная сумма.
class InvalidAmountException implements Exception {
  final String message;
  InvalidAmountException(this.message);
  @override
  String toString() => 'InvalidAmountException: $message';
}

/// Исключение: неверный тип операции.
class InvalidOperationTypeException implements Exception {
  final String message;
  InvalidOperationTypeException(this.message);
  @override
  String toString() => 'InvalidOperationTypeException: $message';
}

/// Исключение: ошибка создания операции.
class OperationCreationException implements Exception {
  final String message;
  OperationCreationException(this.message);
  @override
  String toString() => 'OperationCreationException: $message';
}
