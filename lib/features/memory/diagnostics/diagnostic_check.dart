import 'diagnostic_result.dart';

abstract class DiagnosticCheck {
  String get name;
  String get description;
  Future<DiagnosticResult> run();
}
