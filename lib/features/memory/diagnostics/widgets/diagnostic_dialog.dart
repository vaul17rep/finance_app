import 'package:flutter/material.dart';
import '../diagnostic_report.dart';
import '../diagnostic_severity.dart';

class DiagnosticDialog extends StatelessWidget {
  final DiagnosticReport report;

  const DiagnosticDialog({Key? key, required this.report}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final status = report.metrics.healthScore >= 80
        ? '✅ Отлично'
        : report.metrics.healthScore >= 60
        ? '⚠️ Требует внимания'
        : '❌ Требует исправления';

    return AlertDialog(
      title: const Text('Диагностика памяти'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Health Score: ${report.metrics.healthScore}/100'),
          const SizedBox(height: 8),
          Text('Статус: $status'),
          const SizedBox(height: 8),
          Text('✅ PASS: ${report.passCount}'),
          Text('⚠️ WARN: ${report.warnCount}'),
          Text('❌ FAIL: ${report.failCount}'),
          Text('💥 ERRORS: ${report.errorCount}'),
          const SizedBox(height: 16),
          Text('Отчёт сохранён в: diagnostics/'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Закрыть'),
        ),
      ],
    );
  }
}
