import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';

class HomeOverview extends StatelessWidget {
  final double income;
  final double expenses;

  const HomeOverview({super.key, required this.income, required this.expenses});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Text("Обзор", style: AppTextStyles.title),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Text('Доходы', style: AppTextStyles.secondary),

                      const SizedBox(height: 8),

                      Text(
                        '${income.toStringAsFixed(2)} ₽',

                        style: AppTextStyles.balance,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      const Text(
                        'Расходы',
                        style: TextStyle(color: Colors.grey),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        '${expenses.toStringAsFixed(2)} ₽',

                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
