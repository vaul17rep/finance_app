import '../diagnostic_report.dart';
import '../diagnostic_result.dart';
import '../diagnostic_severity.dart';

class MarkdownReportGenerator {
  String generate(DiagnosticReport report) {
    final buffer = StringBuffer();

    buffer.writeln('# Memory Diagnostic Report');
    buffer.writeln();
    buffer.writeln('## Metadata');
    buffer.writeln('| Field | Value |');
    buffer.writeln('|-------|-------|');
    buffer.writeln('| Diagnostic Version | ${report.diagnosticVersion} |');
    buffer.writeln('| App Version | ${report.appVersion} |');
    buffer.writeln('| Embedding Model | ${report.embeddingModel} |');
    buffer.writeln('| Database Schema | v${report.dbSchemaVersion} |');
    buffer.writeln('| Date | ${_formatDateTime(report.timestamp)} |');
    buffer.writeln('| Total Duration | ${report.totalDurationMs} ms |');
    buffer.writeln();

    buffer.writeln('## Summary');
    buffer.writeln('| Status | Count |');
    buffer.writeln('|--------|-------|');
    buffer.writeln('| ✅ PASS | ${report.passCount} |');
    buffer.writeln('| ⚠️ WARN | ${report.warnCount} |');
    buffer.writeln('| ❌ FAIL | ${report.failCount} |');
    buffer.writeln('| 💥 ERROR | ${report.errorCount} |');
    buffer.writeln();

    buffer.writeln('## Health Score');
    buffer.writeln('**Score: ${report.metrics.healthScore}/100**');
    buffer.writeln();

    buffer.writeln('## Metrics');
    buffer.writeln('| Metric | Value |');
    buffer.writeln('|--------|-------|');
    buffer.writeln('| Total Embeddings | ${report.metrics.totalEmbeddings} |');
    buffer.writeln(
      '| By Source Type | ${_formatMap(report.metrics.bySourceType)} |',
    );
    buffer.writeln('| Empty Vectors | ${report.metrics.emptyVectors} |');
    buffer.writeln('| Invalid Vectors | ${report.metrics.invalidVectors} |');
    buffer.writeln(
      '| Vector Dimension | ${report.metrics.avgDimension} (avg) |',
    );
    buffer.writeln('| Duplicates | ${report.metrics.duplicates} |');
    buffer.writeln('| Stale Embeddings | ${report.metrics.staleEmbeddings} |');
    buffer.writeln(
      '| Top-1 Accuracy | ${(report.metrics.top1Accuracy * 100).toStringAsFixed(1)}% |',
    );
    buffer.writeln(
      '| Top-3 Accuracy | ${(report.metrics.top3Accuracy * 100).toStringAsFixed(1)}% |',
    );
    buffer.writeln(
      '| Avg Cosine Similarity | ${report.metrics.avgCosineSimilarity.toStringAsFixed(3)} |',
    );
    buffer.writeln(
      '| Avg Search Time | ${report.metrics.avgSearchTimeMs} ms |',
    );
    buffer.writeln();

    buffer.writeln('## Detailed Results');
    for (final result in report.results) {
      buffer.writeln(
        '### ${_severityIcon(result.severity)} ${result.checkName}',
      );
      buffer.writeln('- **Description:** ${result.description}');
      buffer.writeln('- **Message:** ${result.message}');
      if (result.affectedCount > 0) {
        buffer.writeln('- **Affected:** ${result.affectedCount} items');
      }
      if (result.samples.isNotEmpty) {
        buffer.writeln('- **Examples:**');
        for (final sample in result.samples.take(5)) {
          buffer.writeln('  - `${sample}`');
        }
      }
      if (result.recommendation != null) {
        buffer.writeln('- **Recommendation:** ${result.recommendation}');
      }
      buffer.writeln('- **Duration:** ${result.durationMs} ms');
      buffer.writeln();
    }

    if (report.errors.isNotEmpty) {
      buffer.writeln('## Errors');
      for (final error in report.errors) {
        buffer.writeln('- **${error.checkName}:** ${error.errorMessage}');
      }
      buffer.writeln();
    }

    if (report.metrics.healthScore < 60) {
      buffer.writeln(
        '## ⚠️ Health Score is low (${report.metrics.healthScore}/100)',
      );
      buffer.writeln('Please review the FAIL and WARN results above.');
    }

    return buffer.toString();
  }

  String _formatDateTime(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';

  String _formatMap(Map<String, int> map) =>
      map.entries.map((e) => '${e.key}: ${e.value}').join(', ');

  String _severityIcon(DiagnosticSeverity severity) {
    switch (severity) {
      case DiagnosticSeverity.pass:
        return '✅';
      case DiagnosticSeverity.warn:
        return '⚠️';
      case DiagnosticSeverity.fail:
        return '❌';
      case DiagnosticSeverity.error:
        return '💥';
    }
  }
}
