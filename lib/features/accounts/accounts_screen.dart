import 'package:flutter/material.dart';

import '../../models/account.dart';
import '../../data/repositories/account_repository.dart';
import '../../data/repositories/operation_repository.dart';
import 'widgets/create_account_dialog.dart';
import '../../core/utils/account_name_utils.dart';
import '../../core/theme/app_dimensions.dart';
import 'package:uuid/uuid.dart';

import '../../models/operation.dart';
import '../../models/operation_type.dart';
import '../../domain/usecases/financial_service.dart';
import '../../domain/usecases/financial_calculator.dart';
import 'account_details_screen.dart'; // ДОБАВИТЬ ИМПОРТ

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
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return AlertDialog(
          backgroundColor: colorScheme.surface,
          title: Text(
            'Скорректировать баланс',
            style: theme.textTheme.titleLarge,
          ),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: 'Введите текущий баланс',
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: colorScheme.surfaceVariant,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.onSurfaceVariant,
              ),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                final parsed = double.tryParse(
                  controller.text.replaceAll(',', '.'),
                );
                Navigator.pop(context, parsed);
              },
              style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );

    if (value == null) return;

    final difference = value - (balances[account.id] ?? 0);
    if (difference.abs() < 0.01) return;

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
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return AlertDialog(
          backgroundColor: colorScheme.surface,
          title: Text('Изменить название', style: theme.textTheme.titleLarge),
          content: TextField(
            controller: controller,
            maxLength: 40,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: colorScheme.surfaceVariant,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.onSurfaceVariant,
              ),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  processAccountName(controller.text.trim()),
                );
              },
              style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );

    if (name == null || name.isEmpty) return;

    await repository.updateAccount(account.copyWith(name: name));
  }

  Future<void> deleteAccount(Account account) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return AlertDialog(
          backgroundColor: colorScheme.surface,
          title: Text('Удалить счёт?', style: theme.textTheme.titleLarge),
          content: Text(
            'Удалить "${account.name}"?',
            style: theme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.onSurfaceVariant,
              ),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: colorScheme.error),
              child: const Text('Удалить'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await repository.deleteAccount(account.id);
      await loadAccounts();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
        ),
      );
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
    if (account == null) return;

    await repository.insertAccount(account);
    await loadAccounts();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Счета'),
        backgroundColor: Colors.transparent,
      ),
      body: accounts.isEmpty
          ? Center(
              child: Text(
                'Счетов нет',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            )
          : ReorderableListView.builder(
              itemCount: accounts.length,
              onReorderItem: (oldIndex, newIndex) async {
                final updated = List<Account>.from(accounts);
                final moved = updated.removeAt(oldIndex);
                updated.insert(newIndex, moved);
                setState(() => accounts = updated);
                await repository.updateAccountsOrder(updated);
              },
              itemBuilder: (context, index) {
                final account = accounts[index];
                return Card(
                  key: ValueKey(account.id),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusMedium,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusMedium,
                    ),
                    // ИСПРАВЛЕНО: открываем детали счёта
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AccountDetailsScreen(account: account),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: colorScheme.primary.withOpacity(
                              0.15,
                            ),
                            child: Icon(
                              account.isMain
                                  ? Icons.star
                                  : Icons.account_balance_wallet,
                              size: 24,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  account.name,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${(balances[account.id] ?? 0).toStringAsFixed(2)} ₽',
                                  style: theme.textTheme.headlineMedium
                                      ?.copyWith(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                                if (account.isMain)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      'Основной счёт',
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(
                                            color: colorScheme.primary,
                                            fontSize: 11,
                                          ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          ReorderableDragStartListener(
                            index: index,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Icon(
                                Icons.drag_handle,
                                color: colorScheme.onSurfaceVariant.withOpacity(
                                  0.5,
                                ),
                                size: 20,
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
                                    backgroundColor: colorScheme.primary,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppDimensions.radiusMedium,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              if (value == 'edit') await editAccount(account);
                              if (value == 'balance')
                                await editBalance(account);
                              if (value == 'delete')
                                await deleteAccount(account);
                              await loadAccounts();
                            },
                            itemBuilder: (context) => [
                              if (!account.isMain)
                                PopupMenuItem(
                                  value: 'main',
                                  child: Text(
                                    'Сделать основным',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ),
                              PopupMenuItem(
                                value: 'edit',
                                child: Text(
                                  'Редактировать',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                              PopupMenuItem(
                                value: 'balance',
                                child: Text(
                                  'Изменить баланс',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                              if (!account.isMain)
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text(
                                    'Удалить',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.error,
                                    ),
                                  ),
                                ),
                            ],
                            iconColor: colorScheme.onSurfaceVariant,
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
        shape: const CircleBorder(),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        child: const Icon(Icons.add, size: 30),
      ),
    );
  }
}
