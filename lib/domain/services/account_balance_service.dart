import '../../models/account.dart';
import '../../models/operation.dart';
import '../../models/operation_type.dart';

class AccountBalanceService {
  double calculate(Account account, List<Operation> operations) {
    double balance = 0;

    for (final operation in operations) {
      if (operation.accountId != account.id) {
        continue;
      }

      if (operation.type == OperationType.income) {
        balance += operation.amount;
      }

      if (operation.type == OperationType.expense) {
        balance -= operation.amount;
      }
    }

    return balance;
  }
}
