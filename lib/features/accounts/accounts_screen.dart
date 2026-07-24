import 'package:flutter/material.dart';

import '../../models/account.dart';
import '../../data/repositories/account_repository.dart';
import '../../data/repositories/operation_repository.dart';
import 'widgets/create_account_dialog.dart';
import '../../core/utils/account_name_utils.dart';
import 'package:uuid/uuid.dart';

import '../../models/operation.dart';
import '../../models/operation_type.dart';
import '../../domain/usecases/financial_service.dart';
import '../../domain/usecases/financial_calculator.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  final AccountRepository repository = AccountRepository();
  final OperationRepository operationRepository = OperationRepository();

  late final FinancialService financialService = FinancialService(
    operationRepository,
    FinancialCalculator(),
  );

  List<Account> accounts = [];

  Map<String, double> balances = {};

  @override
  void initState() {
    super.initState();

    loadAccounts();
  }

  Future<void> editBalance(Account account) async {
    final controller = TextEditingController(
      text: (balances[account.id] ?? 0).toStringAsFixed(2),
    );

    final value = await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Скорректировать баланс'),

          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              hintText: 'Введите текущий баланс',
            ),
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),

            TextButton(
              onPressed: () {
                final parsed = double.tryParse(
                  controller.text.replaceAll(',', '.'),
                );

                Navigator.pop(context, parsed);
              },
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );

    if (value == null) {
      return;
    }

    final difference = value - (balances[account.id] ?? 0);

    if (difference.abs() < 0.01) {
      return;
    }

    final operation = Operation(
      id: const Uuid().v4(),
      type: OperationType.adjustment,
      amount: difference,
      comment: 'Корректировка баланса',
      date: DateTime.now(),
      accountId: account.id,
    );

    await operationRepository.insertOperation(operation);

    await loadAccounts();
  }

  Future<void> editAccount(Account account) async {
    final controller = TextEditingController(text: account.name);

    final name = await showDialog<String>(
      context: context,

      builder: (context) {
        return AlertDialog(
          title: const Text('Изменить название'),

          content: TextField(controller: controller, maxLength: 40),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },

              child: const Text('Отмена'),
            ),

            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  processAccountName(controller.text.trim()),
                );
              },

              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );

    if (name == null || name.isEmpty) {
      return;
    }

    await repository.updateAccount(account.copyWith(name: name));
  }

  Future<void> deleteAccount(Account account) async {
    final confirm = await showDialog<bool>(
      context: context,

      builder: (context) {
        return AlertDialog(
          title: const Text('Удалить счёт?'),

          content: Text('Удалить "${account.name}"?'),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },

              child: const Text('Отмена'),
            ),

            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },

              child: const Text('Удалить'),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    try {
      await repository.deleteAccount(account.id);
      await loadAccounts();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> loadAccounts() async {
    final result = await repository.getAccounts();

    final calculatedBalances = <String, double>{};

    for (final account in result) {
      final state = await financialService.getState(account: account);
      calculatedBalances[account.id] = state.balance;
    }

    setState(() {
      accounts = result;
      balances = calculatedBalances;
    });
  }

  Future<void> addAccount() async {
    final account = await showCreateAccountDialog(
      context,
      isMain: accounts.isEmpty,
    );

    if (account == null) {
      return;
    }

    print("CREATED ACCOUNT: ${account.name}");

    await repository.insertAccount(account);

    final test = await repository.getAccounts();

    print(test);

    await loadAccounts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Счета')),

      body: accounts.isEmpty
          ? const Center(child: Text('Счетов нет'))
          : ReorderableListView.builder(
              itemCount: accounts.length,
              onReorderItem: (oldIndex, newIndex) async {
                final updated = List<Account>.from(accounts);

                final moved = updated.removeAt(oldIndex);

                updated.insert(newIndex, moved);

                setState(() {
                  accounts = updated;
                });

                await repository.updateAccountsOrder(updated);
              },
              itemBuilder: (context, index) {
                final account = accounts[index];

                return Card(
                  key: ValueKey(account.id),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      Navigator.pop(context, account);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          CircleAvatar(
                            child: Icon(
                              account.isMain
                                  ? Icons.star
                                  : Icons.account_balance_wallet,
                            ),
                          ),

                          const SizedBox(width: 16),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  account.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),

                                const SizedBox(height: 6),

                                Text(
                                  '${(balances[account.id] ?? 0).toStringAsFixed(2)} ₽',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                if (account.isMain)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Основной счёт',
                                      style: TextStyle(
                                        color: Colors.orange,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          ReorderableDragStartListener(
                            index: index,

                            child: const Padding(
                              padding: EdgeInsets.only(right: 8),

                              child: Icon(
                                Icons.drag_handle,
                                color: Colors.grey,
                              ),
                            ),
                          ),

                          PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'main') {
                                await repository.setMainAccount(account.id);

                                if (!mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${account.name} теперь основной счёт',
                                    ),
                                  ),
                                );
                              }

                              if (value == 'edit') {
                                await editAccount(account);
                              }

                              if (value == 'balance') {
                                await editBalance(account);
                              }

                              if (value == 'delete') {
                                await deleteAccount(account);
                              }

                              await loadAccounts();
                            },
                            itemBuilder: (context) => [
                              if (!account.isMain)
                                const PopupMenuItem(
                                  value: 'main',
                                  child: Text('Сделать основным'),
                                ),
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Редактировать'),
                              ),
                              const PopupMenuItem(
                                value: 'balance',
                                child: Text('Изменить баланс'),
                              ),
                              if (!account.isMain)
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Удалить'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

      floatingActionButton: FloatingActionButton(
        onPressed: addAccount,

        child: const Icon(Icons.add),
      ),
    );
  }
}
