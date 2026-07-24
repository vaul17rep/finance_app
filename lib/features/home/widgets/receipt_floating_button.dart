import 'dart:async';
import 'package:flutter/material.dart';

import '/core/theme/app_colors.dart';
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

  void wakeUp() {
    setState(() {
      active = true;
    });

    timer?.cancel();

    timer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          active = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),

      opacity: active ? 1 : 0.25,

      child: GestureDetector(
        onTapDown: (_) {
          wakeUp();
        },

        child: FloatingActionButton(
          heroTag: 'receipt',

          elevation: active ? 8 : 2,

          backgroundColor: Colors.transparent,

          onPressed: () async {
            wakeUp();

            await ReceiptCreationService.createReceipt(context);

            widget.onCreated();
          },

          child: Container(
            width: 56,
            height: 56,

            decoration: BoxDecoration(
              shape: BoxShape.circle,

              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,

                colors: [
                  AppColors.card.withOpacity(0.9),
                  AppColors.card.withOpacity(0.4),
                ],
              ),
            ),

            child: const Icon(Icons.receipt_long, size: 21),
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
