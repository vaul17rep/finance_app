import 'package:flutter/material.dart';

import '../memory_diagnostic_service.dart';
import '../../../debug/screens/debug_log_screen.dart';
import '/../../core/debug/debug_logger.dart';

class DiagnosticButton extends StatelessWidget {
  final MemoryDiagnosticService diagnosticService;

  const DiagnosticButton({super.key, required this.diagnosticService});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.medical_services),
      tooltip: 'Запустить диагностику памяти',
      onPressed: () {
        _runDiagnostic(context);
      },
    );
  }

  Future<void> _runDiagnostic(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final report = await diagnosticService.runDiagnostics();

      if (context.mounted) {
        Navigator.of(context).pop();

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const DebugLogScreen(initialTag: LogTag.memory),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка диагностики: $e')));
      }
    }
  }
}
