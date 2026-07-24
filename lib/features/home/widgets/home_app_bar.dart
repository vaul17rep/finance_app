import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../settings/settings_screen.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onRefresh;

  const HomeAppBar({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        'Finance App',
        style: AppTextStyles.title.copyWith(fontSize: 26, letterSpacing: 1.5),
      ),

      actions: [
        IconButton(
          icon: const Icon(Icons.settings_rounded),

          tooltip: 'Настройки',

          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );

            onRefresh();
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
