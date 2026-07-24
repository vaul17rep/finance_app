import 'package:flutter/material.dart';
import '../../core/preferences/app_settings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Настройки")),

      body: ListView(
        children: [
          SwitchListTile(
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
    );
  }
}
