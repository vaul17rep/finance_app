import 'package:flutter/material.dart';

import '../models/receipt_item.dart';
import '../repositories/receipt_repository.dart';

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

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(text: widget.item.name);

    quantityController = TextEditingController(
      text: widget.item.quantity.toString(),
    );

    priceController = TextEditingController(text: widget.item.price.toString());

    categoryController = TextEditingController(
      text: widget.item.category ?? '',
    );

    commentController = TextEditingController(text: widget.item.comment ?? '');
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

      category: categoryController.text,

      comment: commentController.text,
    );

    await repository.updateReceiptItem(updatedItem);

    await repository.recalculateReceiptAmount(updatedItem.receiptId);

    if (mounted) {
      Navigator.pop(context, updatedItem);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Редактирование товара'),

        actions: [IconButton(icon: const Icon(Icons.save), onPressed: save)],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [
            TextField(
              controller: nameController,

              decoration: const InputDecoration(labelText: 'Название'),
            ),

            TextField(
              controller: quantityController,

              keyboardType: TextInputType.number,

              decoration: const InputDecoration(labelText: 'Количество'),
            ),

            TextField(
              controller: priceController,

              keyboardType: TextInputType.number,

              decoration: const InputDecoration(labelText: 'Цена'),
            ),

            TextField(
              controller: categoryController,

              decoration: const InputDecoration(labelText: 'Категория'),
            ),

            TextField(
              controller: commentController,

              decoration: const InputDecoration(labelText: 'Комментарий'),
            ),
          ],
        ),
      ),
    );
  }
}
