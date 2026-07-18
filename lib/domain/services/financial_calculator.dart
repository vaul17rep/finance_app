import '../entities/financial_state.dart';
import '../../models/operation.dart';

class FinancialCalculator {
  FinancialState calculate(List<Operation> operations) {
    double income = 0;
    double expense = 0;

    for (final operation in operations) {
      if (operation.type == 'income') {
        income += operation.amount;
      }

      if (operation.type == 'expense') {
        expense += operation.amount;
      }
    }

    return FinancialState(
      balance: income - expense,
      income: income,
      expense: expense,
    );
  }
}