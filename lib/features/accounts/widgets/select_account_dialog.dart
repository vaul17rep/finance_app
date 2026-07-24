import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../models/account.dart';
import '../../../data/repositories/account_repository.dart';

final uuid = Uuid();

Future<Account?> showSelectAccountDialog(BuildContext context) async {
  final repository = AccountRepository();

  return showDialog<Account>(
    context: context,
    builder: (context) {
      return _SelectAccountDialog(repository: repository);
    },
  );
}

class _SelectAccountDialog extends StatefulWidget {
  final AccountRepository repository;

  const _SelectAccountDialog({required this.repository});

  @override
  State<_SelectAccountDialog> createState() => _SelectAccountDialogState();
}

class _SelectAccountDialogState extends State<_SelectAccountDialog> {
  List<Account> accounts = [];

  Account? selectedAccount;

  @override
  void initState() {
    super.initState();
    loadAccounts();
  }

  Future<void> loadAccounts() async {
    final result = await widget.repository.getAccounts();

    if (!mounted) return;

    setState(() {
      accounts = result;

      selectedAccount = result.firstWhere(
        (a) => a.isMain,
        orElse: () => result.isNotEmpty
            ? result.first
            : Account(
                id: uuid.v4(),
                name: 'Новый счёт',
                balance: 0,
                initialBalance: 0,
                isMain: false,
                type: 'other',
              ),
      );
    });
  }

  Future<void> createAccount() async {
    final nameController = TextEditingController();

    String type = 'other';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Новый счёт'),

              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,

                    decoration: const InputDecoration(labelText: 'Название'),
                  ),

                  const SizedBox(height: 16),

                  DropdownButton<String>(
                    value: type,

                    isExpanded: true,

                    items: const [
                      DropdownMenuItem(value: 'cash', child: Text('Наличные')),

                      DropdownMenuItem(value: 'bank', child: Text('Банк')),

                      DropdownMenuItem(value: 'credit', child: Text('Кредит')),

                      DropdownMenuItem(value: 'other', child: Text('Другое')),
                    ],

                    onChanged: (value) {
                      if (value == null) return;

                      setState(() {
                        type = value;
                      });
                    },
                  ),
                ],
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, false);
                  },

                  child: const Text('Отмена'),
                ),

                FilledButton(
                  onPressed: () {
                    if (nameController.text.trim().isEmpty) {
                      return;
                    }

                    Navigator.pop(context, true);
                  },

                  child: const Text('Создать'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != true) {
      return;
    }

    final account = Account(
      id: uuid.v4(),
      name: nameController.text.trim(),
      balance: 0,
      initialBalance: 0,
      isMain: false,
      type: type,
    );

    await widget.repository.insertAccount(account);

    await loadAccounts();

    setState(() {
      selectedAccount = account;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Выберите счёт'),

      content: SizedBox(
        width: double.maxFinite,

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            ...accounts.map((account) {
              return RadioListTile<Account>(
                value: account,

                groupValue: selectedAccount,

                title: Text(account.name),

                subtitle: Text(account.type),

                onChanged: (value) {
                  setState(() {
                    selectedAccount = value;
                  });
                },
              );
            }),

            const Divider(),

            ListTile(
              leading: const Icon(Icons.add),

              title: const Text('Создать новый счёт'),

              onTap: createAccount,
            ),
          ],
        ),
      ),

      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },

          child: const Text('Отмена'),
        ),

        FilledButton(
          onPressed: () {
            Navigator.pop(context, selectedAccount);
          },

          child: const Text('Продолжить'),
        ),
      ],
    );
  }
}
