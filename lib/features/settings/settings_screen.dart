import 'package:flutter/material.dart';

import '../../core/preferences/app_settings.dart';

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

  @override
  Widget build(BuildContext context) {
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

          sectionTitle("Приложение"),

          settingsCard(
            children: [
              ListTile(
                leading: const Icon(Icons.palette_outlined),

                title: const Text("Тема"),

                subtitle: const Text("Системная"),

                trailing: const Icon(Icons.chevron_right),

                onTap: () {},
              ),

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
