import 'package:flutter/material.dart';

import '../../models/account.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class AccountCard extends StatelessWidget {
  static const double aspectRatio = 85.6 / 53.98;

  final Account account;
  final double balance;
  final double width;
  final bool expanded;

  const AccountCard({
    super.key,
    required this.account,
    required this.balance,
    required this.width,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final height = width / AccountCard.aspectRatio;

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          // Только поверхность карты участвует в Hero
          Positioned.fill(
            child: PhysicalModel(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(expanded ? 28 : 20),
              elevation: expanded ? 18 : 10,
              shadowColor: Colors.black38,

              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(expanded ? 28 : 20),

                  gradient: LinearGradient(
                    colors: [
                      Colors.blueGrey.shade900,
                      Colors.blueGrey.shade700,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Контент карты
          Padding(
            padding: EdgeInsets.all(expanded ? 23 : 19),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,

                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Text(
                          account.name,

                          style: AppTextStyles.title.copyWith(
                            color: Colors.white,
                            fontSize: expanded ? 26 : null,
                          ),
                        ),

                        Text(
                          account.isMain ? "Основной счёт" : "Счёт",

                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),

                    if (account.isMain)
                      const Icon(Icons.star, color: Colors.amber),
                  ],
                ),

                const Spacer(),

                Text(
                  "Баланс",

                  style: AppTextStyles.caption.copyWith(color: Colors.white70),
                ),

                Text(
                  "${balance.toStringAsFixed(0)} ₽",

                  style: AppTextStyles.balance.copyWith(
                    color: Colors.white,
                    fontSize: expanded ? 42 : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
