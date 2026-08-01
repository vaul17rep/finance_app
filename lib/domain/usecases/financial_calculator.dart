/// Калькулятор финансового состояния.
///
/// Вычисляет баланс, доходы, расходы и сумму переводов
/// на основе списка операций.
///
/// Связанные документы:
/// - 04_Financial_Rules — правила расчёта
/// - 03_Domain_Model — FinancialState

import '../../models/account.dart';
import '../entities/financial_state.dart';
import '../../models/operation.dart';
import '../../models/operation_type.dart';

/// Калькулятор финансового состояния.
///
/// Вычисляет баланс, доходы, расходы и сумму переводов
/// на основе списка операций.
class FinancialCalculator {
  FinancialState calculate(Account account, List<Operation> operations) {
    double income = 0;
    double expense = 0;
    double transfers = 0;

    double balance = account.initialBalance;

    for (final operation in operations) {
      // Проверяем, является ли операция переводом
      final isTransfer = operation.isTransfer;

      // Если операция является переводом, учитываем её в transfers
      // и не учитываем в доходах/расходах
      if (isTransfer) {
        // Для операций с типом income или expense, но с transferId,
        // это операции перевода, созданные через TransferService
        if (operation.type == OperationType.income ||
            operation.type == OperationType.expense) {
          transfers += operation.amount;
        }
        // Баланс всё равно меняется
        if (operation.type == OperationType.income) {
          balance += operation.amount;
        } else if (operation.type == OperationType.expense) {
          balance -= operation.amount;
        }
        continue;
      }

      // Обычные операции (не переводы)
      switch (operation.type) {
        case OperationType.income:
          income += operation.amount;
          balance += operation.amount;
          break;

        case OperationType.expense:
          expense += operation.amount;
          balance -= operation.amount;
          break;

        case OperationType.repayment:
          expense += operation.amount;
          balance -= operation.amount;
          break;

        case OperationType.adjustment:
          balance += operation.amount;
          break;

        case OperationType.transfer:
          // Для операций перевода не должно быть прямых вызовов,
          // но на всякий случай обрабатываем
          transfers += operation.amount;
          balance += operation.amount;
          break;
      }
    }

    return FinancialState(
      balance: balance,
      income: income,
      expenses: expense,
      transfers: transfers,
    );
  }
}
