import 'package:flutter/material.dart';

import '../../models/receipt.dart';
import '../../data/repositories/receipt_repository.dart';
import '../../models/receipt_item.dart';
import '../../core/theme/app_dimensions.dart';
import 'edit_receipt_item_screen.dart';
import '/core/preferences/app_settings.dart';
import '/data/services/background_manager/background_task.dart';
import '/data/services/background_manager/background_task_manager.dart';

class EditReceiptScreen extends StatefulWidget {
  final Receipt receipt;

  const EditReceiptScreen({super.key, required this.receipt});

  @override
  State<EditReceiptScreen> createState() => _EditReceiptScreenState();
}

class _EditReceiptScreenState extends State<EditReceiptScreen> {
  final ReceiptRepository repository = ReceiptRepository();

  late TextEditingController shopController;
  late TextEditingController commentController;

  late DateTime selectedDate;
  late TimeOfDay selectedTime;
  List<ReceiptItem> items = [];
  bool hasChanges = false;

  String _buildReceiptContentForIndexing(Receipt receipt) {
    final buffer = StringBuffer();
    buffer.writeln('Магазин: ${receipt.shop}');
    buffer.writeln('Дата: ${receipt.date}');
    buffer.writeln('Сумма: ${receipt.amount}');
    if (items.isNotEmpty) {
      buffer.writeln('Товары:');
      for (var item in items) {
        buffer.writeln('- ${item.name} x${item.quantity} = ${item.total}');
      }
    }
    return buffer.toString();
  }

  @override
  void initState() {
    super.initState();

    loadItems();

    shopController = TextEditingController(text: widget.receipt.shop);
    shopController.addListener(() => setState(() => hasChanges = true));

    commentController = TextEditingController(
      text: widget.receipt.comment ?? '',
    );
    commentController.addListener(() => setState(() => hasChanges = true));

    selectedDate = widget.receipt.date;

    if (widget.receipt.time != null && widget.receipt.time!.contains(":")) {
      final parts = widget.receipt.time!.split(":");
      selectedTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    } else {
      selectedTime = const TimeOfDay(hour: 0, minute: 0);
    }
  }

  Future<bool> confirmExit() async {
    if (!hasChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        ),
        title: const Text('Выйти без сохранения?'),
        content: const Text('Изменения будут потеряны.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Остаться'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<void> loadItems() async {
    final result = await repository.getReceiptItems(widget.receipt.id);
    setState(() => items = result);
  }

  @override
  void dispose() {
    shopController.dispose();
    commentController.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final total = items.fold<double>(0, (sum, item) => sum + item.total);

    final updatedReceipt = widget.receipt.copyWith(
      shop: shopController.text,
      comment: commentController.text.isNotEmpty
          ? commentController.text
          : null,
      date: DateTime(selectedDate.year, selectedDate.month, selectedDate.day),
      time:
          '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
      amount: total,
    );

    hasChanges = false;

    await repository.updateReceipt(updatedReceipt);
    await repository.updateReceiptAmount(updatedReceipt.id, total);

    // Индексация обновлённого чека, если автоиндексация включена
    if (AppSettings.autoIndexingEnabled) {
      final content = _buildReceiptContentForIndexing(updatedReceipt);
      final metadata = {
        'receiptId': updatedReceipt.id,
        'date': updatedReceipt.date.toIso8601String(),
        'shop': updatedReceipt.shop,
        'amount': updatedReceipt.amount,
      };
      BackgroundTaskManager.instance.addTask(
        BackgroundTask(
          id: 'index_receipt_${updatedReceipt.id}_${DateTime.now().millisecondsSinceEpoch}',
          type: 'memory_index_single',
          title: 'Обновление индекса чека',
          status: BackgroundTaskStatus.processing,
          progress: 0.0,
          message: 'Обновление',
          params: {
            'sourceType': 'receipt',
            'sourceId': updatedReceipt.id,
            'content': content,
            'metadata': metadata,
            'sourceUpdatedAt': DateTime.now().toIso8601String(),
          },
        ),
      );
      if (mounted) {
        Navigator.pop(context, updatedReceipt);
      }
    }
  }

  Future<void> selectDate() async {
    final result = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (result != null) {
      setState(() {
        selectedDate = result;
        hasChanges = true;
      });
    }
  }

  Future<void> selectTime() async {
    final result = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );

    if (result != null) {
      setState(() {
        selectedTime = result;
        hasChanges = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final canExit = await confirmExit();
        if (canExit && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Редактирование чека'),
          backgroundColor: Colors.transparent,
          actions: [
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: hasChanges ? save : null,
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Магазин
              TextField(
                controller: shopController,
                decoration: InputDecoration(
                  labelText: 'Магазин',
                  prefixIcon: const Icon(Icons.store, size: 20),
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

              // Дата и время
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusMedium,
                  ),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('Дата'),
                      subtitle: Text(
                        '${selectedDate.day.toString().padLeft(2, '0')}.${selectedDate.month.toString().padLeft(2, '0')}.${selectedDate.year}',
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusMedium,
                        ),
                      ),
                      onTap: selectDate,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.access_time),
                      title: const Text('Время'),
                      subtitle: Text(selectedTime.format(context)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusMedium,
                        ),
                      ),
                      onTap: selectTime,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Комментарий
              TextField(
                controller: commentController,
                decoration: InputDecoration(
                  labelText: 'Комментарий',
                  prefixIcon: const Icon(Icons.description, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusMedium,
                    ),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceVariant,
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 24),

              // Товары
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Товары', style: theme.textTheme.titleLarge),
                  Text(
                    '${items.length} шт.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              if (items.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'Товаров нет',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              else
                ...items.map(
                  (item) => _buildItemTile(item, theme, colorScheme),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemTile(
    ReceiptItem item,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: ListTile(
        title: Text(
          item.name,
          style: theme.textTheme.bodyLarge,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${item.quantity} ${item.unit ?? ''} × ${item.price.toStringAsFixed(2)} ₽',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Text(
          '${item.total.toStringAsFixed(2)} ₽',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        onTap: () async {
          final updated = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditReceiptItemScreen(item: item),
            ),
          );
          if (updated == true) {
            await loadItems();
            setState(() => hasChanges = true);
          }
        },
      ),
    );
  }
}
