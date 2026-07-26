import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme_notifier.dart'; // создайте файл или оставьте как в main.dart
import '../../core/preferences/app_settings.dart';
import 'card_colors_settings_screen.dart';
import '/data/services/background_manager/background_task_manager.dart';
import '/data/services/background_manager/background_task.dart';
import '../debug/screens/debug_log_screen.dart';

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

  void _showEmbeddingModelDialog(BuildContext context) {
    const models = [
      'openai/text-embedding-3-small',
      'openai/text-embedding-3-large',
      'cohere/embed-english-v3.0',
      // другие
    ];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Выберите модель эмбеддингов'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: models.map((model) {
            return ListTile(
              title: Text(model),
              onTap: () {
                setState(() {
                  AppSettings.embeddingModel = model;
                });
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );
  }

  void _showReindexDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Переиндексация'),
        content: const Text('Выберите источники для полной переиндексации:'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _startReindex(
                context,
                sourceTypes: ['receipt', 'memory_note'],
                fullReindex: true,
              );
            },
            child: const Text('Всё'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _startReindex(
                context,
                sourceTypes: ['receipt'],
                fullReindex: true,
              );
            },
            child: const Text('Только чеки'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _startReindex(
                context,
                sourceTypes: ['memory_note'],
                fullReindex: true,
              );
            },
            child: const Text('Только заметки'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );
  }

  void _startReindex(
    BuildContext context, {
    required List<String> sourceTypes,
    required bool fullReindex,
  }) {
    // Запускаем задачу через BackgroundTaskManager
    final task = BackgroundTask(
      id: 'memory_index_${DateTime.now().millisecondsSinceEpoch}',
      type: 'memory_index',
      title: 'Полная переиндексация',
      status: BackgroundTaskStatus.processing,
      progress: 0.0,
      message: 'Подготовка',
      params: {'sourceTypes': sourceTypes, 'fullReindex': fullReindex},
    );
    BackgroundTaskManager.instance.addTask(task);
    // Можно показать snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Запущена переиндексация (${sourceTypes.join(", ")})'),
      ),
    );
  }

  void _showIndexingStatsDialog(BuildContext context) {
    // Здесь можно получить данные через EmbeddingRepository.countIndexedSources() и т.д.
    // Пока просто заглушка.
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Статистика индексации'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Проиндексировано записей: 0'),
            Text('Последняя индексация: никогда'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Закрыть'),
          ),
        ],
      ),
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

          sectionTitle("AI и поиск"),
          settingsCard(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.smart_toy_outlined),
                title: const Text("Автоиндексация новых данных"),
                subtitle: const Text(
                  "Чеки и заметки будут автоматически индексироваться",
                ),
                value: AppSettings.autoIndexingEnabled,
                onChanged: (value) {
                  setState(() {
                    AppSettings.autoIndexingEnabled = value;
                  });
                  // Сохранить настройку (при желании)
                },
              ),
              ListTile(
                leading: const Icon(Icons.model_training),
                title: const Text("Модель эмбеддингов"),
                subtitle: Text(AppSettings.embeddingModel),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // Диалог выбора модели (пока можно просто показать список)
                  _showEmbeddingModelDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.storage),
                title: const Text("Статистика индексации"),
                subtitle: const Text(
                  "Проиндексировано записей: ...",
                ), // можно вычислить через репозиторий
                trailing: const Icon(Icons.info_outline),
                onTap: () {
                  // Показать детальную статистику
                  _showIndexingStatsDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.sync),
                title: const Text("Переиндексировать все данные"),
                subtitle: const Text("Запустить полную переиндексацию"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showReindexDialog(context);
                },
              ),
            ],
          ),

          sectionTitle("Разработка"),
          settingsCard(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.bug_report_outlined),
                title: const Text("Режим разработчика"),
                subtitle: const Text("Показывать отладочные функции"),
                value: AppSettings.developerMode,
                onChanged: (value) {
                  setState(() {
                    AppSettings.developerMode = value;
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.list_alt),
                title: const Text("Логи"),
                subtitle: const Text("Просмотр логов приложения"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DebugLogScreen()),
                  );
                },
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
