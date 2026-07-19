import 'package:flutter/material.dart';

import '../models/operation.dart';
import '../models/operation_type.dart';

import '../domain/services/financial_calculator.dart';
import '../domain/services/financial_service.dart';
import '../domain/entities/financial_state.dart';

import '../repositories/operation_repository.dart';

import 'add_operation_screen.dart';
import 'receipts_screen.dart';
import 'operations_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Operation> operations = [];

  final OperationRepository _repository = OperationRepository();

  late final FinancialService _financialService = FinancialService(
    _repository,
    FinancialCalculator(),
  );

  FinancialState? financialState;

  @override
  void initState() {
    super.initState();

    loadOperations();
  }

  Future<void> loadOperations() async {
    final loaded = await _repository.getOperations();

    final state = await _financialService.getState();

    setState(() {
      operations = loaded;

      financialState = state;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Мои финансы')),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text('Баланс', style: TextStyle(fontSize: 18)),

            const SizedBox(height: 8),

            Text(
              '${(financialState?.balance ?? 0).toStringAsFixed(0)} ₽',

              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 32),

            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,

                  MaterialPageRoute(
                    builder: (context) => const ReceiptsScreen(),
                  ),
                );
              },

              icon: const Icon(Icons.receipt),

              label: const Text('Чеки'),
            ),

            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,

                  MaterialPageRoute(
                    builder: (context) => const OperationsScreen(),
                  ),
                );
              },

              icon: const Icon(Icons.list),

              label: const Text('Операции'),
            ),

            const SizedBox(height: 32),

            const Text(
              'Последние операции',

              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: operations.isEmpty
                  ? const Center(child: Text('Операций пока нет'))
                  : ListView.builder(
                      itemCount: operations.length,

                      itemBuilder: (context, index) {
                        final op = operations[index];

                        return ListTile(
                          title: Text(
                            op.comment.isEmpty
                                ? op.type.toString()
                                : op.comment,
                          ),

                          subtitle: Text(op.type.toString()),

                          trailing: Text(
                            '${op.type == OperationType.expense ? "-" : "+"}'
                            '${op.amount.toStringAsFixed(0)} ₽',
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<Operation>(
            context,

            MaterialPageRoute(builder: (context) => const AddOperationScreen()),
          );

          if (result != null) {
            await _repository.insertOperation(result);

            final state = await _financialService.getState();

            setState(() {
              operations.insert(0, result);

              financialState = state;
            });
          }
        },

        child: const Icon(Icons.add),
      ),
    );
  }
}
