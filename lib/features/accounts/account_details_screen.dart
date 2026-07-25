import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/account.dart';
import '../../models/operation.dart';
import '../../models/operation_type.dart';
import '../../data/repositories/operation_repository.dart';
import '../../data/repositories/account_repository.dart';
import '../../domain/usecases/financial_service.dart';
import '../../domain/usecases/financial_calculator.dart';
import '../../domain/entities/financial_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/utils/account_name_utils.dart';
import 'widgets/account_card.dart';
import '/features/operations/operation_details_screen.dart';

class AccountDetailsScreen extends StatefulWidget {
  final Account account;

  const AccountDetailsScreen({super.key, required this.account});

  @override
  State<AccountDetailsScreen> createState() => _AccountDetailsScreenState();
}

class _AccountDetailsScreenState extends State<AccountDetailsScreen> {
  final OperationRepository _repository = OperationRepository();
  final AccountRepository _accountRepository = AccountRepository();

  late final FinancialService _financialService = FinancialService(
    _repository,
    FinancialCalculator(),
  );

  FinancialState? state;
  List<Operation> operations = [];
  bool _loading = true;
  String? _error;
  late Account _account;

  @override
  void initState() {
    super.initState();
    _account = widget.account;
    load();
  }

  Future<void> load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final accounts = await _accountRepository.getAccounts();
      final updated = accounts.firstWhere((a) => a.id == _account.id);
      _account = updated;

      final loadedOperations = await _repository.getOperationsByAccount(
        _account.id,
      );
      final financial = await _financialService.getState(account: _account);

      if (mounted) {
        setState(() {
          operations = loadedOperations;
          state = financial;
          _loading = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('AccountDetailsScreen ERROR: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
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

  bool _isExpense(Operation op) {
    return op.type == OperationType.expense ||
        op.type == OperationType.repayment ||
        (op.type == OperationType.adjustment && op.amount < 0);
  }

  Future<void> _editAccountName() async {
    final controller = TextEditingController(text: _account.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final colorScheme = theme.colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          ),
          title: Text('Изменить название', style: theme.textTheme.titleLarge),
          content: TextField(
            controller: controller,
            maxLength: 40,
            decoration: InputDecoration(
              labelText: 'Название счёта',
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
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Отмена',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                ctx,
                processAccountName(controller.text.trim()),
              ),
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );

    if (name == null || name.isEmpty) return;
    await _accountRepository.updateAccount(_account.copyWith(name: name));
    await load();
  }

  Future<void> _editBalance() async {
    final controller = TextEditingController(
      text: (state?.balance ?? 0).toStringAsFixed(2),
    );

    final value = await showDialog<double>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final colorScheme = theme.colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          ),
          title: Text(
            'Скорректировать баланс',
            style: theme.textTheme.titleLarge,
          ),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: 'Введите текущий баланс',
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
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Отмена',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ),
            FilledButton(
              onPressed: () {
                final parsed = double.tryParse(
                  controller.text.replaceAll(',', '.'),
                );
                Navigator.pop(ctx, parsed);
              },
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );

    if (value == null) return;
    final difference = value - (state?.balance ?? 0);
    if (difference.abs() < 0.01) return;

    final operation = Operation(
      id: const Uuid().v4(),
      type: OperationType.adjustment,
      amount: difference,
      comment: 'Корректировка баланса',
      date: DateTime.now(),
      accountId: _account.id,
    );

    await _repository.insertOperation(operation);
    await load();
  }

  Future<void> _toggleMainAccount() async {
    if (_account.isMain) return;
    await _accountRepository.setMainAccount(_account.id);
    await load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_account.name} теперь основной счёт'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
        ),
      );
    }
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final colorScheme = theme.colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          ),
          title: Text('Удалить счёт?', style: theme.textTheme.titleLarge),
          content: Text(
            'Удалить "${_account.name}"?',
            style: theme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'Отмена',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
              child: const Text('Удалить'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;
    try {
      await _accountRepository.deleteAccount(_account.id);
      if (mounted) Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_account.name),
        backgroundColor: Colors.transparent,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'edit') await _editAccountName();
              if (value == 'balance') await _editBalance();
              if (value == 'main') await _toggleMainAccount();
              if (value == 'delete') await _deleteAccount();
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'edit',
                child: Text('Редактировать название'),
              ),
              const PopupMenuItem(
                value: 'balance',
                child: Text('Изменить баланс'),
              ),
              if (!_account.isMain)
                const PopupMenuItem(
                  value: 'main',
                  child: Text('Сделать основным'),
                ),
              if (!_account.isMain)
                PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    'Удалить',
                    style: TextStyle(color: colorScheme.error),
                  ),
                ),
            ],
            iconColor: colorScheme.onSurface,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                  const SizedBox(height: 16),
                  Text('Ошибка загрузки', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: load, child: const Text('Повторить')),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  AccountCard(
                    account: _account,
                    balance: state?.balance ?? 0,
                    width: MediaQuery.of(context).size.width - 32,
                    expanded: true,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _infoCard(
                          'Доходы',
                          state?.income ?? 0,
                          AppColors.income,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _infoCard(
                          'Расходы',
                          state?.expenses ?? 0,
                          AppColors.expense,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('История операций', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  if (operations.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          'Операций пока нет',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  else
                    ...operations.map(
                      (op) => _buildOperationTile(op, theme, colorScheme),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildOperationTile(
    Operation op,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final isExpense = _isExpense(op);
    final amountColor = isExpense ? AppColors.expense : AppColors.income;
    final prefix = isExpense ? '-' : '+';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OperationDetailsScreen(operation: op),
            ),
          );
        },
        leading: CircleAvatar(
          backgroundColor: amountColor.withValues(alpha: 0.1),
          child: Icon(
            isExpense ? Icons.arrow_downward : Icons.arrow_upward,
            color: amountColor,
            size: 20,
          ),
        ),
        title: Text(
          op.comment.isNotEmpty ? op.comment : operationName(op.type),
          style: theme.textTheme.bodyLarge,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          op.shop ?? '',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          '$prefix${op.amount.abs().toStringAsFixed(2)} ₽',
          style: theme.textTheme.titleMedium?.copyWith(
            color: amountColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _infoCard(String title, double value, Color valueColor) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: valueColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${value.toStringAsFixed(2)} ₽',
            style: theme.textTheme.titleLarge?.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
