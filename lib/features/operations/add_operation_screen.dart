import 'package:flutter/material.dart';
import '../../models/operation.dart' as model;
import '../../models/operation_type.dart';
import '../../models/account.dart';
import '../../data/repositories/account_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../features/accounts/widgets/create_account_dialog.dart';

class AddOperationScreen extends StatefulWidget {
  final Account? account;

  const AddOperationScreen({super.key, this.account});

  @override
  State<AddOperationScreen> createState() => _AddOperationScreenState();
}

class _AddOperationScreenState extends State<AddOperationScreen> {
  final amountController = TextEditingController();
  final commentController = TextEditingController();
  final shopController = TextEditingController();
  final AccountRepository accountRepository = AccountRepository();

  List<Account> accounts = [];

  OperationType type = OperationType.expense;
  Account? selectedAccount;
  DateTime selectedDate = DateTime.now();

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

  bool get canSave {
    final amount = double.tryParse(amountController.text);
    return amount != null && amount > 0 && selectedAccount != null;
  }

  void saveOperation() {
    final amount = double.tryParse(amountController.text);
    final account = selectedAccount;

    if (amount == null || account == null) return;

    final operation = model.Operation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: selectedDate,
      type: type,
      amount: amount,
      comment: commentController.text,
      shop: shopController.text.isNotEmpty ? shopController.text : null,
      accountId: account.id,
    );

    Navigator.pop(context, operation);
  }

  Future<void> selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('ru'),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  Future<void> _createNewAccount() async {
    final newAccount = await showCreateAccountDialog(
      context,
      isMain: accounts.isEmpty,
    );
    if (newAccount != null) {
      await accountRepository.insertAccount(newAccount);
      await loadAccounts();
      setState(() {
        selectedAccount = newAccount;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Добавить операцию'),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Тип операции
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _typeButton(
                      label: 'Расход',
                      icon: Icons.arrow_downward,
                      isSelected: type == OperationType.expense,
                      color: AppColors.expense,
                      onTap: () => setState(() => type = OperationType.expense),
                    ),
                  ),
                  Expanded(
                    child: _typeButton(
                      label: 'Доход',
                      icon: Icons.arrow_upward,
                      isSelected: type == OperationType.income,
                      color: AppColors.income,
                      onTap: () => setState(() => type = OperationType.income),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Сумма
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              autofocus: true,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontSize: 32,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '0.00',
                hintStyle: theme.textTheme.headlineMedium?.copyWith(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant.withOpacity(0.3),
                ),
                suffixText: '₽',
                suffixStyle: theme.textTheme.headlineMedium?.copyWith(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 20),

            // Счёт с кнопкой создания нового
            _buildAccountDropdown(),

            const SizedBox(height: 12),

            // Дата
            InkWell(
              onTap: selectDate,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusMedium,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Дата',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatDate(selectedDate),
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Магазин (необязательный)
            TextField(
              controller: shopController,
              decoration: InputDecoration(
                labelText: 'Магазин',
                hintText: 'Название магазина',
                prefixIcon: Icon(
                  Icons.store,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Комментарий
            TextField(
              controller: commentController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Комментарий',
                hintText: 'Дополнительная информация',
                prefixIcon: Icon(
                  Icons.notes,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Кнопка сохранения
            ElevatedButton(
              onPressed: canSave ? saveOperation : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: type == OperationType.expense
                    ? AppColors.expense
                    : AppColors.income,
                foregroundColor: Colors.white,
                disabledBackgroundColor: colorScheme.surfaceVariant,
                disabledForegroundColor: colorScheme.onSurfaceVariant,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusMedium,
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                type == OperationType.expense
                    ? 'Добавить расход'
                    : 'Добавить доход',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountDropdown() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Account>(
                value: selectedAccount,
                hint: Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      accounts.isEmpty ? 'Нет счетов' : 'Выберите счёт',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: colorScheme.onSurfaceVariant,
                ),
                isExpanded: true,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface,
                ),
                items: accounts.map((account) {
                  return DropdownMenuItem<Account>(
                    value: account,
                    child: Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          size: 20,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 12),
                        Text(account.name),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedAccount = value;
                  });
                },
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.add_circle_outline,
              color: colorScheme.primary,
              size: 24,
            ),
            onPressed: _createNewAccount,
            tooltip: 'Создать новый счёт',
          ),
        ],
      ),
    );
  }

  Widget _typeButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? color : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: isSelected ? color : colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    amountController.dispose();
    commentController.dispose();
    shopController.dispose();
    super.dispose();
  }
}
