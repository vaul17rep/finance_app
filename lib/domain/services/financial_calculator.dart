import '../entities/financial_state.dart';
import '../../models/operation.dart';
import '../../models/operation_type.dart';

class FinancialCalculator {
  FinancialState calculate(List<Operation> operations) {
    double income = 0;
    double expense = 0;

    for (final operation in operations) {
      switch (operation.type) {
        case OperationType.income:
          income += operation.amount;
          break;

        case OperationType.expense:
          expense += operation.amount;
          break;

        case OperationType.transfer:
          break;

        case OperationType.repayment:
          expense += operation.amount;
          break;
      }
    }

    return FinancialState(
      balance: income - expense,
      income: income,
      expenses: expense,
    );
  }
}
