import 'package:flutter/material.dart';

import '../models/operation.dart';
import '../repositories/operation_repository.dart';
import '../services/category_service.dart';

class OperationDetailsScreen extends StatefulWidget {
  final Operation operation;

  const OperationDetailsScreen({super.key, required this.operation});

  @override
  State<OperationDetailsScreen> createState() => _OperationDetailsScreenState();
}

class _OperationDetailsScreenState extends State<OperationDetailsScreen> {
  final OperationRepository repository = OperationRepository();

  late Operation operation;

  @override
  void initState() {
    super.initState();

    operation = widget.operation;
  }

  Future<void> delete() async {
    await repository.deleteOperation(operation.id);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Операция'),

        actions: [
          IconButton(
            icon: const Icon(Icons.delete),

            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,

                builder: (context) {
                  return AlertDialog(
                    title: const Text('Удалить операцию?'),

                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context, false);
                        },

                        child: const Text('Отмена'),
                      ),

                      TextButton(
                        onPressed: () {
                          Navigator.pop(context, true);
                        },

                        child: const Text('Удалить'),
                      ),
                    ],
                  );
                },
              );

              if (confirm == true) {
                await delete();
              }
            },
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Text(
              operation.comment.isEmpty ? 'Без описания' : operation.comment,

              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            Text(
              '${operation.amount.toStringAsFixed(2)} ₽',

              style: const TextStyle(fontSize: 30),
            ),

            const SizedBox(height: 16),

            Text(operation.date.toString()),

            const SizedBox(height: 16),

            Text('Категория: ${CategoryService.getName(operation.categoryId)}'),

            Text('Магазин: ${operation.shop ?? "нет"}'),

            Text('Тип: ${operation.type.name}'),
          ],
        ),
      ),
    );
  }
}
