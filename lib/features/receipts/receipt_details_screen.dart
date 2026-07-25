import 'dart:io';
import 'package:flutter/material.dart';

import '../../models/receipt.dart';
import '../../models/receipt_item.dart';
import '../../data/repositories/receipt_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import 'edit_receipt_screen.dart';
import 'edit_receipt_item_screen.dart';

class ReceiptDetailsScreen extends StatefulWidget {
  final Receipt receipt;

  const ReceiptDetailsScreen({super.key, required this.receipt});

  @override
  State<ReceiptDetailsScreen> createState() => _ReceiptDetailsScreenState();
}

class _ReceiptDetailsScreenState extends State<ReceiptDetailsScreen> {
  final ReceiptRepository repository = ReceiptRepository();

  List<ReceiptItem> items = [];
  late Receipt currentReceipt;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    currentReceipt = widget.receipt;
    loadData();
  }

  Future<void> loadData() async {
    setState(() => _loading = true);

    try {
      final receipt = await repository.getReceiptById(currentReceipt.id);
      final receiptItems = await repository.getReceiptItems(currentReceipt.id);

      if (mounted) {
        setState(() {
          if (receipt != null) currentReceipt = receipt;
          items = receiptItems;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final receipt = currentReceipt;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Чек'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditReceiptScreen(receipt: currentReceipt),
                ),
              );
              if (updated != null) await loadData();
            },
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: colorScheme.error),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusLarge,
                    ),
                  ),
                  title: const Text('Удалить чек?'),
                  content: const Text('Чек и операция будут удалены.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Отмена'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.error,
                      ),
                      child: const Text('Удалить'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await repository.deleteReceipt(receipt.id);
                if (mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Фото чека (если есть)
                    if (receipt.photoPath != null &&
                        File(receipt.photoPath!).existsSync())
                      _buildPhotoPreview(receipt.photoPath!),

                    if (receipt.photoPath != null &&
                        File(receipt.photoPath!).existsSync())
                      const SizedBox(height: 16),

                    // Магазин
                    Text(
                      receipt.shop,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 8),

                    // Дата и время
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${receipt.date.day.toString().padLeft(2, '0')}.${receipt.date.month.toString().padLeft(2, '0')}.${receipt.date.year}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (receipt.time != null) ...[
                          const SizedBox(width: 12),
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            receipt.time!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),

                    if (receipt.address != null &&
                        receipt.address!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              receipt.address!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Сумма
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.expense.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusLarge,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Итого', style: theme.textTheme.titleMedium),
                          Text(
                            '${receipt.amount.toStringAsFixed(2)} ₽',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: AppColors.expense,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Товары
                    Text('Товары', style: theme.textTheme.titleLarge),

                    const SizedBox(height: 12),

                    if (items.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            'Список товаров пуст',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      )
                    else
                      ...items.map((item) => _buildItemTile(item, theme)),

                    if (receipt.comment != null &&
                        receipt.comment!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text('Комментарий', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(
                        receipt.comment!,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPhotoPreview(String photoPath) {
    return GestureDetector(
      onTap: () => _showFullScreenPhoto(photoPath),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        child: Image.file(
          File(photoPath),
          width: double.infinity,
          height: 200,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            ),
            child: const Center(
              child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
            ),
          ),
        ),
      ),
    );
  }

  void _showFullScreenPhoto(String photoPath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(child: Image.file(File(photoPath))),
          ),
        ),
      ),
    );
  }

  Widget _buildItemTile(ReceiptItem item, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: ListTile(
        onTap: () async {
          final updated = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EditReceiptItemScreen(item: item),
            ),
          );
          if (updated == true) await loadData();
        },
        title: Text(
          item.name,
          style: theme.textTheme.bodyLarge,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${item.quantity} ${item.unit ?? ''}${item.price != null ? ' × ${item.price.toStringAsFixed(2)} ₽' : ''}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Text(
          '${item.total.toStringAsFixed(2)} ₽',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
