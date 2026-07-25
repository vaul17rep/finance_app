import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../models/account.dart';
import '../../../data/repositories/account_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';

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
  bool _loading = true;

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
      _loading = false;
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
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
              ),
              title: Text('Новый счёт', style: theme.textTheme.titleLarge),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Название',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusMedium,
                        ),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: colorScheme.surfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: InputDecoration(
                      labelText: 'Тип',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusMedium,
                        ),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: colorScheme.surfaceVariant,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'cash', child: Text('Наличные')),
                      DropdownMenuItem(value: 'bank', child: Text('Банк')),
                      DropdownMenuItem(value: 'credit', child: Text('Кредит')),
                      DropdownMenuItem(value: 'other', child: Text('Другое')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => type = value);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    'Отмена',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ),
                FilledButton(
                  onPressed: () {
                    if (nameController.text.trim().isEmpty) return;
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

    if (result != true) return;

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
    setState(() => selectedAccount = account);
  }

  String _accountTypeLabel(String type) {
    switch (type) {
      case 'cash':
        return 'Наличные';
      case 'bank':
        return 'Банк';
      case 'credit':
        return 'Кредит';
      default:
        return 'Другое';
    }
  }

  IconData _accountTypeIcon(String type) {
    switch (type) {
      case 'cash':
        return Icons.money;
      case 'bank':
        return Icons.account_balance;
      case 'credit':
        return Icons.credit_card;
      default:
        return Icons.account_balance_wallet;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
      ),
      title: Text('Выберите счёт', style: theme.textTheme.titleLarge),
      content: SizedBox(
        width: double.maxFinite,
        child: _loading
            ? const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (accounts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Нет доступных счетов',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  else
                    ...accounts.map((account) {
                      final isSelected = selectedAccount?.id == account.id;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colorScheme.primary.withValues(alpha: 0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusMedium,
                          ),
                        ),
                        child: RadioListTile<Account>(
                          value: account,
                          groupValue: selectedAccount,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusMedium,
                            ),
                          ),
                          title: Text(
                            account.name,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: Row(
                            children: [
                              Icon(
                                _accountTypeIcon(account.type),
                                size: 14,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _accountTypeLabel(account.type),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              if (account.isMain) ...[
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.star,
                                  size: 14,
                                  color: Colors.amber,
                                ),
                              ],
                            ],
                          ),
                          onChanged: (value) {
                            setState(() => selectedAccount = value);
                          },
                        ),
                      );
                    }),
                  const Divider(),
                  ListTile(
                    leading: Icon(Icons.add, color: colorScheme.primary),
                    title: Text(
                      'Создать новый счёт',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMedium,
                      ),
                    ),
                    onTap: createAccount,
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Отмена',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ),
        FilledButton(
          onPressed: selectedAccount != null
              ? () => Navigator.pop(context, selectedAccount)
              : null,
          child: const Text('Продолжить'),
        ),
      ],
    );
  }
}
