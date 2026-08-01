import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/account.dart';
import '../../../core/preferences/color_settings_notifier.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/card_color_settings.dart';
import '../../transfers/screens/transfer_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final height = width / AccountCard.aspectRatio;
    final isDark = theme.brightness == Brightness.dark;

    CardColorSettings settings;
    try {
      settings = Provider.of<ColorSettingsNotifier>(
        context,
        listen: false,
      ).settings;
    } catch (_) {
      settings = CardColorSettings.defaultSettings();
    }
    final colors = _getColors(account.type, isDark, settings);

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
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
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: colors,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(expanded ? 23 : 16),
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
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: isDark ? colorScheme.onPrimary : Colors.white,
                          fontSize: _getNameFontSize(account.name, expanded),
                        ),
                      ),
                    ),
                    // Звёздочка для основного счёта
                    if (account.isMain)
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                    // Кнопка перевода - компактная
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TransferScreen(
                              initialSourceAccountId: account.id,
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.swap_horiz,
                          size: 18,
                          color: (isDark ? colorScheme.onPrimary : Colors.white)
                              .withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
                // Тип счета
                Text(
                  _getTypeLabel(account.type, settings),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: (isDark ? colorScheme.onPrimary : Colors.white)
                        .withOpacity(0.5),
                  ),
                ),
                const Spacer(),
                Text(
                  'Баланс',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: (isDark ? colorScheme.onPrimary : Colors.white)
                        .withOpacity(0.7),
                  ),
                ),
                Text(
                  "${balance.toStringAsFixed(2)} ₽",
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: isDark ? colorScheme.onPrimary : Colors.white,
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

  String _getTypeLabel(String type, CardColorSettings settings) {
    switch (type) {
      case 'card':
        return 'Карта';
      case 'cash':
        return 'Наличные';
      case 'credit':
        return 'Кредитная';
      case 'other':
        return 'Другое';
      case 'custom1':
        return settings.custom1Name.isNotEmpty
            ? settings.custom1Name
            : 'Custom1';
      case 'custom2':
        return settings.custom2Name.isNotEmpty
            ? settings.custom2Name
            : 'Custom2';
      case 'custom3':
        return settings.custom3Name.isNotEmpty
            ? settings.custom3Name
            : 'Custom3';
      case 'custom4':
        return settings.custom4Name.isNotEmpty
            ? settings.custom4Name
            : 'Custom4';
      case 'custom5':
        return settings.custom5Name.isNotEmpty
            ? settings.custom5Name
            : 'Custom5';
      default:
        return type;
    }
  }

  List<Color> _getColors(String type, bool isDark, CardColorSettings settings) {
    switch (type) {
      case 'card':
        return isDark
            ? [Color(settings.cardDarkStart), Color(settings.cardDarkEnd)]
            : [Color(settings.cardLightStart), Color(settings.cardLightEnd)];
      case 'cash':
        return isDark
            ? [Color(settings.cashDarkStart), Color(settings.cashDarkEnd)]
            : [Color(settings.cashLightStart), Color(settings.cashLightEnd)];
      case 'credit':
        return isDark
            ? [Color(settings.creditDarkStart), Color(settings.creditDarkEnd)]
            : [
                Color(settings.creditLightStart),
                Color(settings.creditLightEnd),
              ];
      case 'other':
        return isDark
            ? [Color(settings.otherDarkStart), Color(settings.otherDarkEnd)]
            : [Color(settings.otherLightStart), Color(settings.otherLightEnd)];
      case 'custom1':
        return isDark
            ? [Color(settings.custom1DarkStart), Color(settings.custom1DarkEnd)]
            : [
                Color(settings.custom1LightStart),
                Color(settings.custom1LightEnd),
              ];
      case 'custom2':
        return isDark
            ? [Color(settings.custom2DarkStart), Color(settings.custom2DarkEnd)]
            : [
                Color(settings.custom2LightStart),
                Color(settings.custom2LightEnd),
              ];
      case 'custom3':
        return isDark
            ? [Color(settings.custom3DarkStart), Color(settings.custom3DarkEnd)]
            : [
                Color(settings.custom3LightStart),
                Color(settings.custom3LightEnd),
              ];
      case 'custom4':
        return isDark
            ? [Color(settings.custom4DarkStart), Color(settings.custom4DarkEnd)]
            : [
                Color(settings.custom4LightStart),
                Color(settings.custom4LightEnd),
              ];
      case 'custom5':
        return isDark
            ? [Color(settings.custom5DarkStart), Color(settings.custom5DarkEnd)]
            : [
                Color(settings.custom5LightStart),
                Color(settings.custom5LightEnd),
              ];
      default:
        return isDark
            ? [AppColors.darkCardGradientStart, AppColors.darkCardGradientEnd]
            : [AppColors.cardGradientStart, AppColors.cardGradientEnd];
    }
  }
}