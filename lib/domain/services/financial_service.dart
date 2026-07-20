import '../../domain/entities/financial_state.dart';
import '../../domain/services/financial_calculator.dart';
import '../../repositories/operation_repository.dart';

class FinancialService {
  final OperationRepository repository;
  final FinancialCalculator calculator;

  FinancialService(this.repository, this.calculator);

  Future<FinancialState> getState({String? accountId}) async {
    final operations = accountId == null
        ? await repository.getOperations()
        : await repository.getOperationsByAccount(accountId);

    return calculator.calculate(operations);
  }
}
