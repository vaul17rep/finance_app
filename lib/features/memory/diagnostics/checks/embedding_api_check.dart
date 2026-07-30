import '../../services/embedding_service.dart';
import '../diagnostic_check.dart';
import '../diagnostic_result.dart';
import '../diagnostic_severity.dart';

class EmbeddingApiCheck implements DiagnosticCheck {
  final EmbeddingService _embeddingService;

  EmbeddingApiCheck(this._embeddingService);

  @override
  String get name => 'Получение эмбеддинга для запроса';

  @override
  String get description =>
      'Проверяет, может ли EmbeddingService получить вектор для текста';

  // features/memory/diagnostics/checks/embedding_api_check.dart

  @override
  Future<DiagnosticResult> run() async {
    final start = DateTime.now();

    try {
      final testText = 'Тестовый запрос для диагностики поиска';
      final vector = await _embeddingService.getEmbeddingVector(testText);

      final durationMs = DateTime.now().difference(start).inMilliseconds;

      if (vector.isEmpty) {
        return DiagnosticResult(
          checkName: name,
          description: description,
          severity: DiagnosticSeverity.fail,
          message: 'Получен пустой вектор для тестового запроса',
          recommendation:
              'Проверьте EmbeddingService: API-ключ, модель, соединение',
          durationMs: durationMs,
        );
      }

      return DiagnosticResult(
        checkName: name,
        description: description,
        severity: DiagnosticSeverity.pass,
        message:
            'Вектор получен (размерность: ${vector.length}) за ${durationMs}мс',
        affectedCount: vector.length,
        durationMs: durationMs,
      );
    } catch (e) {
      final durationMs = DateTime.now().difference(start).inMilliseconds;
      return DiagnosticResult(
        checkName: name,
        description: description,
        severity: DiagnosticSeverity.fail,
        message: 'Не удалось получить эмбеддинг: $e',
        recommendation: 'Проверьте подключение к OpenRouter, API-ключ и модель',
        durationMs: durationMs,
      );
    }
  }
}
