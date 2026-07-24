import '../../models/account.dart';
import '../entities/financial_state.dart';
import '../../models/operation.dart';
import '../../models/operation_type.dart';

class FinancialCalculator {
  FinancialState calculate(Account account, List<Operation> operations) {
    double income = 0;
    double expense = 0;

    double balance = account.initialBalance;

    for (final operation in operations) {
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
          break;
      }
    }

    return FinancialState(
      balance: balance,
      income: income,
      expenses: expense,
    );
  }
}