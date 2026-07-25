import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../core/preferences/color_settings_notifier.dart';
import '../../models/card_color_settings.dart';
import '../../core/theme/app_dimensions.dart';

class ColorSettingsScreen extends StatefulWidget {
  const ColorSettingsScreen({super.key});

  @override
  State<ColorSettingsScreen> createState() => _ColorSettingsScreenState();
}

class _ColorSettingsScreenState extends State<ColorSettingsScreen> {
  bool _hasChanges = false;
  late CardColorSettings _originalSettings;

  @override
  void initState() {
    super.initState();
    final notifier = context.read<ColorSettingsNotifier>();
    _originalSettings = notifier.tempSettings;
    notifier.addListener(_onChange);
  }

  @override
  void dispose() {
    context.read<ColorSettingsNotifier>().removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (!mounted) return;
    final current = context.read<ColorSettingsNotifier>().tempSettings;
    // Сравниваем с оригиналом (можно упрощённо по JSON, но допустим так)
    final changed = _hasSettingsChanged(_originalSettings, current);
    if (changed != _hasChanges) {
      setState(() => _hasChanges = changed);
    }
  }

  bool _hasSettingsChanged(CardColorSettings a, CardColorSettings b) {
    return a.cardLightStart != b.cardLightStart ||
        a.cardLightEnd != b.cardLightEnd ||
        a.cashLightStart != b.cashLightStart ||
        a.cashLightEnd != b.cashLightEnd ||
        a.creditLightStart != b.creditLightStart ||
        a.creditLightEnd != b.creditLightEnd ||
        a.otherLightStart != b.otherLightStart ||
        a.otherLightEnd != b.otherLightEnd ||
        a.cardDarkStart != b.cardDarkStart ||
        a.cardDarkEnd != b.cardDarkEnd ||
        a.cashDarkStart != b.cashDarkStart ||
        a.cashDarkEnd != b.cashDarkEnd ||
        a.creditDarkStart != b.creditDarkStart ||
        a.creditDarkEnd != b.creditDarkEnd ||
        a.otherDarkStart != b.otherDarkStart ||
        a.otherDarkEnd != b.otherDarkEnd ||
        a.custom1Name != b.custom1Name ||
        a.custom1LightStart != b.custom1LightStart ||
        a.custom1LightEnd != b.custom1LightEnd ||
        a.custom1DarkStart != b.custom1DarkStart ||
        a.custom1DarkEnd != b.custom1DarkEnd ||
        a.custom2Name != b.custom2Name ||
        a.custom2LightStart != b.custom2LightStart ||
        a.custom2LightEnd != b.custom2LightEnd ||
        a.custom2DarkStart != b.custom2DarkStart ||
        a.custom2DarkEnd != b.custom2DarkEnd ||
        a.custom3Name != b.custom3Name ||
        a.custom3LightStart != b.custom3LightStart ||
        a.custom3LightEnd != b.custom3LightEnd ||
        a.custom3DarkStart != b.custom3DarkStart ||
        a.custom3DarkEnd != b.custom3DarkEnd ||
        a.custom4Name != b.custom4Name ||
        a.custom4LightStart != b.custom4LightStart ||
        a.custom4LightEnd != b.custom4LightEnd ||
        a.custom4DarkStart != b.custom4DarkStart ||
        a.custom4DarkEnd != b.custom4DarkEnd ||
        a.custom5Name != b.custom5Name ||
        a.custom5LightStart != b.custom5LightStart ||
        a.custom5LightEnd != b.custom5LightEnd ||
        a.custom5DarkStart != b.custom5DarkStart ||
        a.custom5DarkEnd != b.custom5DarkEnd;
  }

  Future<bool> _showSaveConfirmation() async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        ),
        title: const Text('Сохранить изменения?'),
        content: const Text('У вас есть несохранённые изменения цветов.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'discard'),
            child: const Text('Выйти без сохранения'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'cancel'),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'save'),
            child: const Text('Сохранить и выйти'),
          ),
        ],
      ),
    );
    if (result == 'save') {
      await context.read<ColorSettingsNotifier>().saveSettings();
      return true;
    } else if (result == 'discard') {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ColorSettingsNotifier>();
    final settings = notifier.tempSettings;

    // Список отображаемых типов: предустановленные + custom с непустым именем
    final List<_AccountTypeEntry> types = [
      _AccountTypeEntry(
        'card',
        'Банковская карта',
        settings.cardLightStart,
        settings.cardLightEnd,
        settings.cardDarkStart,
        settings.cardDarkEnd,
      ),
      _AccountTypeEntry(
        'cash',
        'Наличные',
        settings.cashLightStart,
        settings.cashLightEnd,
        settings.cashDarkStart,
        settings.cashDarkEnd,
      ),
      _AccountTypeEntry(
        'credit',
        'Кредитная карта',
        settings.creditLightStart,
        settings.creditLightEnd,
        settings.creditDarkStart,
        settings.creditDarkEnd,
      ),
      _AccountTypeEntry(
        'other',
        'Другой счёт',
        settings.otherLightStart,
        settings.otherLightEnd,
        settings.otherDarkStart,
        settings.otherDarkEnd,
      ),
    ];

    // Добавляем кастомные типы, если имя задано
    if (settings.custom1Name.isNotEmpty)
      types.add(
        _AccountTypeEntry(
          'custom1',
          settings.custom1Name,
          settings.custom1LightStart,
          settings.custom1LightEnd,
          settings.custom1DarkStart,
          settings.custom1DarkEnd,
        ),
      );
    if (settings.custom2Name.isNotEmpty)
      types.add(
        _AccountTypeEntry(
          'custom2',
          settings.custom2Name,
          settings.custom2LightStart,
          settings.custom2LightEnd,
          settings.custom2DarkStart,
          settings.custom2DarkEnd,
        ),
      );
    if (settings.custom3Name.isNotEmpty)
      types.add(
        _AccountTypeEntry(
          'custom3',
          settings.custom3Name,
          settings.custom3LightStart,
          settings.custom3LightEnd,
          settings.custom3DarkStart,
          settings.custom3DarkEnd,
        ),
      );
    if (settings.custom4Name.isNotEmpty)
      types.add(
        _AccountTypeEntry(
          'custom4',
          settings.custom4Name,
          settings.custom4LightStart,
          settings.custom4LightEnd,
          settings.custom4DarkStart,
          settings.custom4DarkEnd,
        ),
      );
    if (settings.custom5Name.isNotEmpty)
      types.add(
        _AccountTypeEntry(
          'custom5',
          settings.custom5Name,
          settings.custom5LightStart,
          settings.custom5LightEnd,
          settings.custom5DarkStart,
          settings.custom5DarkEnd,
        ),
      );

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _showSaveConfirmation();
        if (shouldPop && mounted) Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Цвета карт'),
          actions: [
            TextButton(
              onPressed: () {
                notifier.resetToDefault();
                setState(() => _hasChanges = true);
              },
              child: const Text('Сбросить'),
            ),
            TextButton(
              onPressed: () async {
                await notifier.saveSettings();
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Сохранить'),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionTitle('Светлая тема'),
            const SizedBox(height: 8),
            ...types.map(
              (t) => _AccountColorCard(
                title: t.title,
                startColor: Color(t.lightStart),
                endColor: Color(t.lightEnd),
                isCustom: t.key.startsWith('custom'),
                onChanged: (start, end, isGradient) {
                  notifier.updateColor('${t.key}LightStart', start);
                  notifier.updateColor(
                    '${t.key}LightEnd',
                    isGradient ? end : start,
                  );
                },
                onRename: t.key.startsWith('custom')
                    ? () => _renameCustomType(notifier, t.key)
                    : null,
              ),
            ),
            const SizedBox(height: 24),
            _SectionTitle('Тёмная тема'),
            const SizedBox(height: 8),
            ...types.map(
              (t) => _AccountColorCard(
                title: t.title,
                startColor: Color(t.darkStart),
                endColor: Color(t.darkEnd),
                isCustom: t.key.startsWith('custom'),
                onChanged: (start, end, isGradient) {
                  notifier.updateColor('${t.key}DarkStart', start);
                  notifier.updateColor(
                    '${t.key}DarkEnd',
                    isGradient ? end : start,
                  );
                },
                onRename: t.key.startsWith('custom')
                    ? () => _renameCustomType(notifier, t.key)
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Добавить тип счёта'),
                onPressed: () => _addCustomType(notifier),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _renameCustomType(ColorSettingsNotifier notifier, String key) {
    final index = int.parse(key.replaceAll('custom', ''));
    final currentName = _getCurrentCustomName(notifier.tempSettings, index);
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Название типа'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Название'),
          maxLength: 20,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              notifier.updateCustomName(index, controller.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  String _getCurrentCustomName(CardColorSettings s, int index) {
    switch (index) {
      case 1:
        return s.custom1Name;
      case 2:
        return s.custom2Name;
      case 3:
        return s.custom3Name;
      case 4:
        return s.custom4Name;
      case 5:
        return s.custom5Name;
      default:
        return '';
    }
  }

  void _addCustomType(ColorSettingsNotifier notifier) {
    // Ищем первый пустой custom
    final settings = notifier.tempSettings;
    int? emptyIndex;
    if (settings.custom1Name.isEmpty)
      emptyIndex = 1;
    else if (settings.custom2Name.isEmpty)
      emptyIndex = 2;
    else if (settings.custom3Name.isEmpty)
      emptyIndex = 3;
    else if (settings.custom4Name.isEmpty)
      emptyIndex = 4;
    else if (settings.custom5Name.isEmpty)
      emptyIndex = 5;
    else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Достигнут лимит пользовательских типов (5)'),
        ),
      );
      return;
    }
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Новый тип счёта'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Название'),
          maxLength: 20,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              notifier.updateCustomName(emptyIndex!, controller.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Создать'),
          ),
        ],
      ),
    );
  }
}

// Вспомогательный класс для хранения информации о типе
class _AccountTypeEntry {
  final String key;
  final String title;
  final int lightStart, lightEnd, darkStart, darkEnd;
  _AccountTypeEntry(
    this.key,
    this.title,
    this.lightStart,
    this.lightEnd,
    this.darkStart,
    this.darkEnd,
  );
}

// Виджет секции заголовка
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

// Карточка выбора цвета для одного типа
class _AccountColorCard extends StatelessWidget {
  final String title;
  final Color startColor, endColor;
  final bool isCustom;
  final Function(Color start, Color end, bool isGradient) onChanged;
  final VoidCallback? onRename;

  const _AccountColorCard({
    required this.title,
    required this.startColor,
    required this.endColor,
    required this.isCustom,
    required this.onChanged,
    this.onRename,
  });

  bool get isGradient => startColor != endColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openColorEditor(context),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: isGradient
                      ? LinearGradient(
                          colors: [startColor, endColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isGradient ? null : startColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: Text(title, style: theme.textTheme.bodyLarge)),
              if (isCustom)
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: onRename,
                ),
              Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  void _openColorEditor(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusLarge),
        ),
      ),
      builder: (_) => _ColorEditorSheet(
        title: title,
        startColor: startColor,
        endColor: endColor,
        isGradient: isGradient,
        onChanged: onChanged,
      ),
    );
  }
}

// Нижний лист редактора цвета
class _ColorEditorSheet extends StatefulWidget {
  final String title;
  final Color startColor, endColor;
  final bool isGradient;
  final Function(Color start, Color end, bool isGradient) onChanged;

  const _ColorEditorSheet({
    required this.title,
    required this.startColor,
    required this.endColor,
    required this.isGradient,
    required this.onChanged,
  });

  @override
  State<_ColorEditorSheet> createState() => _ColorEditorSheetState();
}

class _ColorEditorSheetState extends State<_ColorEditorSheet> {
  late bool _isGradient;
  late Color _startColor, _endColor;

  @override
  void initState() {
    super.initState();
    _isGradient = widget.isGradient;
    _startColor = widget.startColor;
    _endColor = widget.endColor;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Градиент'),
            value: _isGradient,
            onChanged: (v) => setState(() => _isGradient = v),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),
          _ColorField(
            label: _isGradient ? 'Цвет 1' : 'Цвет',
            color: _startColor,
            onChanged: (c) => setState(() => _startColor = c),
          ),
          if (_isGradient) ...[
            const SizedBox(height: 12),
            _ColorField(
              label: 'Цвет 2',
              color: _endColor,
              onChanged: (c) => setState(() => _endColor = c),
            ),
          ],
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: _isGradient
                  ? LinearGradient(
                      colors: [_startColor, _endColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: _isGradient ? null : _startColor,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Отмена'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    widget.onChanged(_startColor, _endColor, _isGradient);
                    Navigator.pop(context);
                  },
                  child: const Text('Применить'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ColorField extends StatelessWidget {
  final String label;
  final Color color;
  final ValueChanged<Color> onChanged;

  const _ColorField({
    required this.label,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Row(
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        const Spacer(),
        GestureDetector(
          onTap: () async {
            final newColor = await showDialog<Color>(
              context: context,
              builder: (_) => _HsvColorPickerDialog(initialColor: color),
            );
            if (newColor != null) onChanged(newColor);
          },
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: colorScheme.outline, width: 1.5),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '#${color.value.toRadixString(16).substring(2).toUpperCase()}',
          style: theme.textTheme.labelMedium?.copyWith(
            fontFamily: 'monospace',
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _HsvColorPickerDialog extends StatefulWidget {
  final Color initialColor;
  const _HsvColorPickerDialog({required this.initialColor});

  @override
  State<_HsvColorPickerDialog> createState() => _HsvColorPickerDialogState();
}

class _HsvColorPickerDialogState extends State<_HsvColorPickerDialog> {
  late Color selectedColor;

  @override
  void initState() {
    super.initState();
    selectedColor = widget.initialColor;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Text('Выберите цвет'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                color: selectedColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outline),
              ),
            ),
            const SizedBox(height: 16),
            ColorPicker(
              pickerColor: selectedColor,
              onColorChanged: (color) => setState(() => selectedColor = color),
              enableAlpha: false,
              pickerAreaBorderRadius: BorderRadius.circular(12),
              displayThumbColor: true,
              portraitOnly: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, selectedColor),
          child: const Text('Выбрать'),
        ),
      ],
    );
  }
}
