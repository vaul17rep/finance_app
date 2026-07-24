import '../entities/financial_state.dart';
import 'financial_calculator.dart';
import '../../data/repositories/operation_repository.dart';
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
