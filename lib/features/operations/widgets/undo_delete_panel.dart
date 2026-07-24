import 'package:flutter/material.dart';

class UndoDeleteItem {
  final String title;
  final VoidCallback onUndo;

  UndoDeleteItem({required this.title, required this.onUndo});
}

class UndoDeletePanel extends StatelessWidget {
  final List<UndoDeleteItem> items;

  const UndoDeletePanel({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),

      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),

        borderRadius: BorderRadius.circular(18),

        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),

      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: items.map((item) {
            return InkWell(
              onTap: item.onUndo,

              child: Container(
                height: 44,

                padding: const EdgeInsets.symmetric(horizontal: 16),

                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,

                        maxLines: 1,

                        overflow: TextOverflow.ellipsis,

                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    Text(
                      'Отменить',

                      style: TextStyle(
                        color: Colors.red.shade300,

                        fontSize: 14,

                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
