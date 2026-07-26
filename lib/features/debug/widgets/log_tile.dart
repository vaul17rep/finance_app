import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/debug/log_entry.dart';

class LogTile extends StatelessWidget {
  final LogEntry entry;

  const LogTile({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final color = entry.level.color;
    return InkWell(
      onLongPress: () {
        // Копирование отдельной записи
        Clipboard.setData(ClipboardData(text: entry.toFormattedString()));
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Запись скопирована')));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: color, width: 4)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Индикатор уровня
            Container(
              width: 4,
              height: 20,
              color: color,
              margin: const EdgeInsets.only(right: 8),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Верхняя строка: уровень, тег, время
                  Row(
                    children: [
                      Text(
                        entry.level.label,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: color,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          entry.tag.label,
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        entry.timestamp.toString().substring(0, 19),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  // Сообщение
                  Text(entry.message, style: const TextStyle(fontSize: 13)),
                  // Дополнительные данные
                  if (entry.extra != null && entry.extra!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        entry.extra!.entries
                            .map((e) => '${e.key}: ${e.value}')
                            .join(', '),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Иконка копирования (по желанию, но long press уже есть)
            IconButton(
              icon: const Icon(Icons.copy, size: 16),
              onPressed: () {
                Clipboard.setData(
                  ClipboardData(text: entry.toFormattedString()),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Запись скопирована')),
                );
              },
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}
