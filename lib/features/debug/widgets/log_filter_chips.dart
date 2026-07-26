import 'package:flutter/material.dart';
import '../../../core/debug/log_entry.dart';

class LogFilterChips extends StatelessWidget {
  final LogLevel? selectedLevel;
  final ValueChanged<LogLevel?> onLevelSelected;
  final LogTag? selectedTag;
  final ValueChanged<LogTag?> onTagSelected;

  const LogFilterChips({
    super.key,
    required this.selectedLevel,
    required this.onLevelSelected,
    required this.selectedTag,
    required this.onTagSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Фильтр по уровню
          Wrap(
            spacing: 6,
            children: [
              FilterChip(
                label: const Text('ALL'),
                selected: selectedLevel == null,
                onSelected: (_) => onLevelSelected(null),
              ),
              ...LogLevel.values.map((level) {
                return FilterChip(
                  label: Text(level.label),
                  selected: selectedLevel == level,
                  onSelected: (_) => onLevelSelected(level),
                  backgroundColor: level.color.withOpacity(0.1),
                  selectedColor: level.color.withOpacity(0.3),
                );
              }).toList(),
            ],
          ),
          const SizedBox(height: 8),
          // Фильтр по тегу
          Wrap(
            spacing: 6,
            children: [
              FilterChip(
                label: const Text('ALL'),
                selected: selectedTag == null,
                onSelected: (_) => onTagSelected(null),
              ),
              ...LogTag.values.map((tag) {
                return FilterChip(
                  label: Text(tag.label),
                  selected: selectedTag == tag,
                  onSelected: (_) => onTagSelected(tag),
                );
              }).toList(),
            ],
          ),
        ],
      ),
    );
  }
}
