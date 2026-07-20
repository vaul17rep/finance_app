import '../../domain/entities/financial_state.dart';
import '../../domain/services/financial_calculator.dart';
import '../../repositories/operation_repository.dart';
import '../../models/account.dart';

class FinancialService {
  final OperationRepository repository;
  final FinancialCalculator calculator;

  FinancialService(this.repository, this.calculator);

  Future<FinancialState> getState({required Account account}) async {
    final operations = await repository.getOperationsByAccount(account.id);

    return calculator.calculate(account, operations);
  }
}
