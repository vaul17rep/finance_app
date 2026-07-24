import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ExitConfirmScope extends StatelessWidget {
  final Widget child;

  const ExitConfirmScope({super.key, required this.child});

  Future<bool> _confirmExit(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,

      builder: (context) {
        return AlertDialog(
          title: const Text('Выйти из приложения?'),

          content: const Text('Вы действительно хотите закрыть приложение?'),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },

              child: const Text('Отмена'),
            ),

            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },

              child: const Text('Выйти'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,

      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldExit = await _confirmExit(context);

        if (shouldExit) {
          SystemNavigator.pop();
        }
      },

      child: child,
    );
  }
}
