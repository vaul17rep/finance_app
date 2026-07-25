import 'dart:async';
import 'package:flutter/material.dart';

import '/data/services/receipt_creation_service.dart';

class ReceiptFloatingButton extends StatefulWidget {
  final VoidCallback onCreated;

  const ReceiptFloatingButton({super.key, required this.onCreated});

  @override
  State<ReceiptFloatingButton> createState() => _ReceiptFloatingButtonState();
}

class _ReceiptFloatingButtonState extends State<ReceiptFloatingButton> {
  bool active = false;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    // Активируем кнопку при инициализации на 4 секунды
    wakeUp(duration: const Duration(seconds: 4));
  }

  void wakeUp({Duration duration = const Duration(seconds: 2)}) {
    setState(() {
      active = true;
    });

    timer?.cancel();

    timer = Timer(duration, () {
      if (mounted) {
        setState(() {
          active = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: active ? 1 : 0.25,
      child: GestureDetector(
        onTapDown: (_) {
          wakeUp();
        },
        child: Material(
          elevation: active ? 8 : 2,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              wakeUp();
              await ReceiptCreationService.createReceipt(context);
              widget.onCreated();
            },
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primary,
              ),
              child: Icon(
                Icons.receipt_long,
                size: 21,
                color: colorScheme.onPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
}
