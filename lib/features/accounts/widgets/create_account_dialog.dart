import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../models/account.dart';
import '../../../core/utils/account_name_utils.dart';

Future<Account?> showCreateAccountDialog(
  BuildContext context, {
  required bool isMain,
}) {
  final nameController = TextEditingController();
  final balanceController = TextEditingController(text: '0');

  String selectedType = 'card';

  return showDialog<Account>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Новый счёт'),

            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,

                    maxLength: 40,

                    decoration: const InputDecoration(
                      labelText: 'Название счёта',
                    ),
                  ),

                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    initialValue: selectedType,
                    decoration: const InputDecoration(labelText: 'Тип счёта'),
                    items: const [
                      DropdownMenuItem(value: 'card', child: Text('💳 Карта')),
                      DropdownMenuItem(
                        value: 'cash',
                        child: Text('💵 Наличные'),
                      ),
                      DropdownMenuItem(
                        value: 'bank',
                        child: Text('🏦 Банковский счёт'),
                      ),
                      DropdownMenuItem(
                        value: 'credit',
                        child: Text('💳 Кредитная карта'),
                      ),
                      DropdownMenuItem(
                        value: 'other',
                        child: Text('📦 Другое'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;

                      setState(() {
                        selectedType = value;
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: balanceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Начальный баланс',
                      suffixText: '₽',
                    ),
                  ),
                ],
              ),
            ),

            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Отмена'),
              ),
              FilledButton(
                onPressed: () {
                  final name = processAccountName(nameController.text.trim());

                  if (name.isEmpty) {
                    return;
                  }

                  final balance = double.tryParse(balanceController.text) ?? 0;

                  Navigator.pop(
                    dialogContext,
                    Account(
                      id: const Uuid().v4(),
                      name: name,
                      balance: 0,
                      initialBalance: balance,
                      isMain: isMain,
                      type: selectedType,
                    ),
                  );
                },
                child: const Text('Создать'),
              ),
            ],
          );
        },
      );
    },
  );
}
