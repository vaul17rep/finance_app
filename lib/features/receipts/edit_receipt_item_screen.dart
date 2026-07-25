import 'package:flutter/material.dart';

import '../../models/receipt_item.dart';
import '../../data/repositories/receipt_repository.dart';
import '../../core/theme/app_dimensions.dart';

class EditReceiptItemScreen extends StatefulWidget {
  final ReceiptItem item;

  const EditReceiptItemScreen({super.key, required this.item});

  @override
  State<EditReceiptItemScreen> createState() => _EditReceiptItemScreenState();
}

class _EditReceiptItemScreenState extends State<EditReceiptItemScreen> {
  final ReceiptRepository repository = ReceiptRepository();

  late TextEditingController nameController;
  late TextEditingController quantityController;
  late TextEditingController priceController;
  late TextEditingController categoryController;
  late TextEditingController commentController;

  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(text: widget.item.name);
    nameController.addListener(() => setState(() => _hasChanges = true));

    quantityController = TextEditingController(
      text: widget.item.quantity.toString(),
    );
    quantityController.addListener(() => setState(() => _hasChanges = true));

    priceController = TextEditingController(text: widget.item.price.toString());
    priceController.addListener(() => setState(() => _hasChanges = true));

    categoryController = TextEditingController(
      text: widget.item.category ?? '',
    );
    categoryController.addListener(() => setState(() => _hasChanges = true));

    commentController = TextEditingController(text: widget.item.comment ?? '');
    commentController.addListener(() => setState(() => _hasChanges = true));
  }

  @override
  void dispose() {
    nameController.dispose();
    quantityController.dispose();
    priceController.dispose();
    categoryController.dispose();
    commentController.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final quantity = double.tryParse(quantityController.text) ?? 0;
    final price = double.tryParse(priceController.text) ?? 0;

    final updatedItem = widget.item.copyWith(
      name: nameController.text,
      quantity: quantity,
      price: price,
      total: quantity * price,
      category: categoryController.text.isNotEmpty
          ? categoryController.text
          : null,
      comment: commentController.text.isNotEmpty
          ? commentController.text
          : null,
    );

    await repository.updateReceiptItem(updatedItem);
    await repository.recalculateReceiptAmount(updatedItem.receiptId);

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final canExit = await _confirmExit();
        if (canExit && mounted) Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Редактирование товара'),
          backgroundColor: Colors.transparent,
          actions: [
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _hasChanges ? save : null,
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildTextField(
                controller: nameController,
                label: 'Название',
                icon: Icons.shopping_bag,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: quantityController,
                      label: 'Количество',
                      icon: Icons.numbers,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: priceController,
                      label: 'Цена',
                      icon: Icons.attach_money,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: categoryController,
                label: 'Категория',
                icon: Icons.category,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: commentController,
                label: 'Комментарий',
                icon: Icons.description,
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: colorScheme.surfaceVariant,
      ),
    );
  }

  Future<bool> _confirmExit() async {
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
}
