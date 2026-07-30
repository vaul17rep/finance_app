import 'diagnostic_severity.dart';

class DiagnosticResult {
  final String checkName;
  final String description;
  final DiagnosticSeverity severity;
  final String message;
  final int affectedCount;
  final List<String> samples;
  final int durationMs;
  final String? recommendation;
  final Map<String, dynamic> metrics;

  DiagnosticResult({
    required this.checkName,
    required this.description,
    required this.severity,
    required this.message,
    this.affectedCount = 0,
    this.samples = const [],
    required this.durationMs,
    this.recommendation,
    this.metrics = const {},
  });

  bool get isPass => severity == DiagnosticSeverity.pass;
  bool get isWarn => severity == DiagnosticSeverity.warn;
  bool get isFail => severity == DiagnosticSeverity.fail;
  bool get isError => severity == DiagnosticSeverity.error;
}
