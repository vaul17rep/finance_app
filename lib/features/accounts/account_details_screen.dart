import 'package:flutter/material.dart';

import '../../models/account.dart';
import '../../data/repositories/operation_repository.dart';
import '../../domain/usecases/financial_service.dart';
import '../../domain/usecases/financial_calculator.dart';
import '../../domain/entities/financial_state.dart';
import 'widgets/account_card.dart';

import '../../models/operation.dart';
import '../../models/operation_type.dart';

class AccountDetailsScreen extends StatefulWidget {
  final Account account;

  const AccountDetailsScreen({super.key, required this.account});

  @override
  State<AccountDetailsScreen> createState() => _AccountDetailsScreenState();
}

class _AccountDetailsScreenState extends State<AccountDetailsScreen> {
  final OperationRepository _repository = OperationRepository();

  late final FinancialService _financialService = FinancialService(
    _repository,
    FinancialCalculator(),
  );

  FinancialState? state;

  List<Operation> operations = [];

  @override
  void initState() {
    super.initState();

    load();
  }

  Future<void> load() async {
    final loadedOperations = await _repository.getOperationsByAccount(
      widget.account.id,
    );

    final financial = await _financialService.getState(account: widget.account);

    setState(() {
      operations = loadedOperations;

      state = financial;
    });
  }

  String operationName(OperationType type) {
    switch (type) {
      case OperationType.income:
        return 'Доход';
      case OperationType.expense:
        return 'Расход';
      case OperationType.transfer:
        return 'Перевод';
      case OperationType.repayment:
        return 'Погашение';
      case OperationType.adjustment:
        return 'Корректировка';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.account.name)),

      body: ListView(
        padding: const EdgeInsets.all(16),

        children: [
          AccountCard(
            account: widget.account,

            balance: state?.balance ?? 0,

            width: MediaQuery.of(context).size.width * 0.85,

            expanded: true,
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(child: _infoCard("Доходы", state?.income ?? 0)),

              const SizedBox(width: 12),

              Expanded(child: _infoCard("Расходы", state?.expenses ?? 0)),
            ],
          ),

          const SizedBox(height: 24),

          Text("История", style: Theme.of(context).textTheme.titleLarge),

          ...operations.map(
            (op) => ListTile(
              title: Text(
                op.comment.isEmpty ? operationName(op.type) : op.comment,
              ),

              trailing: Text(
                '${op.type == OperationType.expense || op.type == OperationType.repayment || (op.type == OperationType.adjustment && op.amount < 0) ? "-" : "+"}${op.amount.abs().toStringAsFixed(2)} ₽',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(String title, double value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Text(title),

            const SizedBox(height: 8),

            Text(
              "${value.toStringAsFixed(2)} ₽",

              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }
}
