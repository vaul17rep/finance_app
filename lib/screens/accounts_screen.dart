import 'package:flutter/material.dart';

import '../models/account.dart';
import '../repositories/account_repository.dart';
import '../repositories/operation_repository.dart';
import '../domain/services/account_balance_service.dart';
import 'home_screen.dart';
import 'widgets/create_account_dialog.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  final AccountRepository repository = AccountRepository();
  final OperationRepository operationRepository = OperationRepository();

  final AccountBalanceService balanceService = AccountBalanceService();

  List<Account> accounts = [];

  @override
  void initState() {
    super.initState();

    loadAccounts();
  }

  Future<void> editBalance(Account account) async {
    final controller = TextEditingController(
      text: account.balance.toStringAsFixed(2),
    );

    final value = await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Изменить баланс'),

          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(hintText: 'Например: 1500.50'),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
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

    await repository.updateAccount(account.copyWith(initialBalance: value));

    await loadAccounts();
  }

  Future<void> editAccount(Account account) async {
    final controller = TextEditingController(text: account.name);

    final name = await showDialog<String>(
      context: context,

      builder: (context) {
        return AlertDialog(
          title: const Text('Изменить название'),

          content: TextField(controller: controller),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },

              child: const Text('Отмена'),
            ),

            TextButton(
              onPressed: () {
                Navigator.pop(context, controller.text.trim());
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
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> loadAccounts() async {
    final result = await repository.getAccounts();

    final operations = await operationRepository.getOperations();

    final updated = result.map((account) {
      final balance = balanceService.calculate(account, operations);

      return account.copyWith(balance: balance);
    }).toList();

    setState(() {
      accounts = updated;
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
          : ListView.builder(
              itemCount: accounts.length,

              itemBuilder: (context, index) {
                final account = accounts[index];

                return Card(
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
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HomeScreen(initialAccount: account),
                        ),
                      );
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
                                  '${account.balance.toStringAsFixed(2)} ₽',
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
