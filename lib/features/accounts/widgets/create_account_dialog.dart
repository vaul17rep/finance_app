import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../models/account.dart';
import '../../../core/utils/account_name_utils.dart';
import '../../../core/theme/app_dimensions.dart';

Future<Account?> showCreateAccountDialog(
  BuildContext context, {
  required bool isMain,
}) {
  final nameController = TextEditingController();
  final balanceController = TextEditingController(); // без начального текста
  final balanceFocusNode = FocusNode();
  String selectedType = 'card';

  // Убираем слушатель, который менял текст – больше не нужен
  // При сохранении пустое поле будет интерпретировано как 0

  return showDialog<Account>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;

          // Общий стиль для обоих полей
          final inputDecoration = InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: colorScheme.surfaceVariant,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          );

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            ),
            title: Text('Новый счёт', style: theme.textTheme.titleLarge),
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            actionsPadding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Название
                  TextField(
                    controller: nameController,
                    maxLength: 40,
                    decoration: inputDecoration.copyWith(
                      labelText: 'Название счёта',
                      prefixIcon: const Icon(Icons.edit_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Тип счёта
                  Text(
                    'Тип счёта',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Сетка 2×2
                  Row(
                    children: [
                      Expanded(
                        child: _typeChip(
                          icon: Icons.credit_card,
                          label: 'Карта',
                          selected: selectedType == 'card',
                          onTap: () => setState(() => selectedType = 'card'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _typeChip(
                          icon: Icons.credit_score,
                          label: 'Кредитная',
                          selected: selectedType == 'credit',
                          onTap: () => setState(() => selectedType = 'credit'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _typeChip(
                          icon: Icons.payments_outlined,
                          label: 'Наличные',
                          selected: selectedType == 'cash',
                          onTap: () => setState(() => selectedType = 'cash'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _typeChip(
                          icon: Icons.more_horiz,
                          label: 'Другое',
                          selected: selectedType == 'other',
                          onTap: () => setState(() => selectedType = 'other'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Баланс – теперь полностью идентичен названию
                  TextField(
                    controller: balanceController,
                    focusNode: balanceFocusNode,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: inputDecoration.copyWith(
                      labelText: 'Баланс',
                      prefixIcon: const Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 20,
                      ),
                      suffix: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Text(
                          '₽',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      // suffixText не используем, чтобы label не смещался
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  'Отмена',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ),
              FilledButton(
                onPressed: () {
                  final name = processAccountName(nameController.text.trim());
                  if (name.isEmpty) return;

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

Widget _typeChip({
  required IconData icon,
  required String label,
  required bool selected,
  required VoidCallback onTap,
}) {
  return Builder(
    builder: (context) {
      final colorScheme = Theme.of(context).colorScheme;
      final theme = Theme.of(context);

      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: selected
                  ? colorScheme.primary.withValues(alpha: 0.12)
                  : colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              border: Border.all(
                color: selected
                    ? colorScheme.primary.withValues(alpha: 0.4)
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: selected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
