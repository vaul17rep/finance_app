import '../../domain/entities/financial_state.dart';
import '../../domain/services/financial_calculator.dart';
import '../../repositories/operation_repository.dart';

class FinancialService {
  final OperationRepository repository;
  final FinancialCalculator calculator;

  FinancialService(this.repository, this.calculator);

  Future<FinancialState> getState() async {
    final operations = await repository.getOperations();

    return calculator.calculate(operations);
  }
}
