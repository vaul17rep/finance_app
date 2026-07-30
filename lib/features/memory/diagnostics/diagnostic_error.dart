class DiagnosticError {
  final String checkName;
  final String errorMessage;
  final StackTrace? stackTrace;

  DiagnosticError({
    required this.checkName,
    required this.errorMessage,
    this.stackTrace,
  });
}
