import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme_notifier.dart'; // создайте файл или оставьте как в main.dart
import '../../core/preferences/app_settings.dart';
import 'card_colors_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Widget sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.grey,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget settingsCard({required List<Widget> children}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: children),
    );
  }

  Future<void> _showThemeDialog(BuildContext context) async {
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
    final current = themeNotifier.themeMode;

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выберите тему'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Системная'),
              leading: Radio<ThemeMode>(
                value: ThemeMode.system,
                groupValue: current,
                onChanged: (value) {
                  if (value != null) {
                    themeNotifier.setThemeMode(value);
                    Navigator.pop(context);
                  }
                },
              ),
            ),
            ListTile(
              title: const Text('Светлая'),
              leading: Radio<ThemeMode>(
                value: ThemeMode.light,
                groupValue: current,
                onChanged: (value) {
                  if (value != null) {
                    themeNotifier.setThemeMode(value);
                    Navigator.pop(context);
                  }
                },
              ),
            ),
            ListTile(
              title: const Text('Тёмная'),
              leading: Radio<ThemeMode>(
                value: ThemeMode.dark,
                groupValue: current,
                onChanged: (value) {
                  if (value != null) {
                    themeNotifier.setThemeMode(value);
                    Navigator.pop(context);
                  }
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Настройки")),
      body: ListView(
        children: [
          sectionTitle("Счета"),
          settingsCard(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.account_balance_wallet),
                title: const Text("Ограничивать длину названия счета"),
                subtitle: const Text("Максимум 40 символов"),
                value: AppSettings.limitAccountNameLength,
                onChanged: (value) {
                  setState(() {
                    AppSettings.limitAccountNameLength = value;
                  });
                },
              ),
            ],
          ),

          sectionTitle("Внешний вид"),
          settingsCard(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.dark_mode_outlined),
                title: const Text("Тёмная тема"),
                subtitle: const Text("Быстрое переключение"),
                value: themeNotifier.themeMode == ThemeMode.dark,
                onChanged: (value) {
                  themeNotifier.toggleDarkMode(value);
                },
              ),
              ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: const Text("Тема"),
                subtitle: Text(
                  themeNotifier.themeMode == ThemeMode.system
                      ? "Системная"
                      : themeNotifier.themeMode == ThemeMode.light
                      ? "Светлая"
                      : "Тёмная",
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showThemeDialog(context),
              ),
              ListTile(
                leading: const Icon(Icons.palette),
                title: const Text("Цвета карт"),
                subtitle: const Text("Настроить цвета для каждого типа"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ColorSettingsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),

          sectionTitle("Приложение"),
          settingsCard(
            children: [
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text("Язык"),
                subtitle: const Text("Русский"),
                trailing: const Icon(Icons.chevron_right),
              ),
            ],
          ),

          sectionTitle("AI"),
          settingsCard(
            children: [
              ListTile(
                leading: const Icon(Icons.smart_toy_outlined),
                title: const Text("Настройки AI"),
                subtitle: const Text("Модели, лимиты, ключи"),
                trailing: const Icon(Icons.chevron_right),
              ),
            ],
          ),

          sectionTitle("Разработка"),
          settingsCard(
            children: [
              ListTile(
                leading: const Icon(Icons.bug_report_outlined),
                title: const Text("Отладка"),
                subtitle: const Text("Логи и диагностика"),
                trailing: const Icon(Icons.chevron_right),
              ),
            ],
          ),

          const SizedBox(height: 30),
          const Center(
            child: Text(
              "Finance App\nВерсия 0.1",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
