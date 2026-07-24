import 'package:flutter/material.dart';
import '../../models/operation.dart' as model;
import '../../models/operation_type.dart';
import '../../models/account.dart';
import '../../data/repositories/account_repository.dart';

class AddOperationScreen extends StatefulWidget {
  final Account? account;

  const AddOperationScreen({super.key, this.account});

  @override
  State<AddOperationScreen> createState() => _AddOperationScreenState();
}

class _AddOperationScreenState extends State<AddOperationScreen> {
  final amountController = TextEditingController();
  final commentController = TextEditingController();
  final AccountRepository accountRepository = AccountRepository();

  List<Account> accounts = [];

  OperationType type = OperationType.expense;
  Account? selectedAccount;

  @override
  void initState() {
    super.initState();
    loadAccounts();
  }

  Future<void> loadAccounts() async {
    final data = await accountRepository.getAccounts();

    Account? account;

    if (widget.account != null) {
      account = data.firstWhere(
        (a) => a.id == widget.account!.id,
        orElse: () => data.first,
      );
    } else if (data.isNotEmpty) {
      account = data.firstWhere((a) => a.isMain, orElse: () => data.first);
    }

    setState(() {
      accounts = data;
      selectedAccount = account;
    });
  }

  void saveOperation() {
    final amount = double.tryParse(amountController.text);

    final account = selectedAccount;

    if (amount == null || account == null) {
      return;
    }

    final operation = model.Operation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),

      date: DateTime.now(),

      type: type,

      amount: amount,

      comment: commentController.text,

      accountId: account.id,
    );

    Navigator.pop(context, operation);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Добавить операцию')),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [
            TextField(
              controller: amountController,

              keyboardType: TextInputType.number,

              decoration: const InputDecoration(
                labelText: 'Сумма',
                suffixText: '₽',
              ),
            ),

            const SizedBox(height: 16),

            DropdownButton<OperationType>(
              value: type,

              items: const [
                DropdownMenuItem(
                  value: OperationType.expense,
                  child: Text('Расход'),
                ),

                DropdownMenuItem(
                  value: OperationType.income,
                  child: Text('Доход'),
                ),
              ],

              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    type = value;
                  });
                }
              },
            ),

            DropdownButton<Account>(
              value: selectedAccount,

              hint: const Text('Выберите счёт'),

              items: accounts.map((account) {
                return DropdownMenuItem(
                  value: account,
                  child: Text(account.name),
                );
              }).toList(),

              onChanged: (value) {
                setState(() {
                  selectedAccount = value;
                });
              },
            ),

            const SizedBox(height: 16),

            TextField(
              controller: commentController,

              decoration: const InputDecoration(labelText: 'Комментарий'),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                onPressed: saveOperation,

                child: const Text('Сохранить'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
