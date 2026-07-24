import 'package:flutter/material.dart';

import '../../../models/account.dart';
import '../../../core/theme/app_text_styles.dart';

class AccountCard extends StatelessWidget {
  static const double aspectRatio = 85.6 / 53.98;

  double _getNameFontSize(String name, bool expanded) {
    if (expanded) {
      if (name.length > 28) return 16;
      if (name.length > 18) return 20;
      return 26;
    }

    if (name.length > 32) return 13;
    if (name.length > 22) return 15;
    if (name.length > 15) return 16;

    return 18;
  }

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
                  children: [
                    Expanded(
                      child: Text(
                        account.name,

                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,

                        style: AppTextStyles.title.copyWith(
                          color: Colors.white,
                          fontSize: _getNameFontSize(account.name, expanded),
                        ),
                      ),
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
                  "${balance.toStringAsFixed(2)} ₽",

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
