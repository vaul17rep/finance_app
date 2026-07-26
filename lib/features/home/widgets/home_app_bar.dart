import 'package:flutter/material.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/preferences/app_settings.dart';
import '../../settings/settings_screen.dart';
import '../../debug/screens/debug_log_screen.dart'; // новый импорт

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
        // Иконка жука (режим разработчика)
        if (AppSettings.developerMode)
          IconButton(
            icon: const Icon(Icons.bug_report_outlined, color: Colors.black),
            tooltip: 'Логи',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DebugLogScreen()),
              );
            },
          ),
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
