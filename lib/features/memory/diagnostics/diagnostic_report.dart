import 'diagnostic_result.dart';
import 'diagnostic_error.dart';
import 'diagnostic_metrics.dart';

class DiagnosticReport {
  final DateTime timestamp;
  final String diagnosticVersion;
  final String appVersion;
  final String embeddingModel;
  final int dbSchemaVersion;
  final List<DiagnosticResult> results;
  final List<DiagnosticError> errors;
  final DiagnosticMetrics metrics;
  final int totalDurationMs;

  DiagnosticReport({
    required this.timestamp,
    required this.diagnosticVersion,
    required this.appVersion,
    required this.embeddingModel,
    required this.dbSchemaVersion,
    required this.results,
    required this.errors,
    required this.metrics,
    required this.totalDurationMs,
  });

  int get passCount => results.where((r) => r.isPass).length;
  int get warnCount => results.where((r) => r.isWarn).length;
  int get failCount => results.where((r) => r.isFail).length;
  int get errorCount => results.where((r) => r.isError).length;
}
