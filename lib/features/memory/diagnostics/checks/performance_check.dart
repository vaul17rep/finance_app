import '../../services/semantic_search_service.dart';
import '../diagnostic_check.dart';
import '../diagnostic_result.dart';
import '../diagnostic_severity.dart';

class PerformanceCheck implements DiagnosticCheck {
  final SemanticSearchService _searchService;

  PerformanceCheck(this._searchService);

  @override
  String get name => 'Скорость поиска';

  @override
  String get description => 'Измеряет время выполнения поисковых запросов';

  // features/memory/diagnostics/checks/performance_check.dart

  @override
  Future<DiagnosticResult> run() async {
    final start = DateTime.now();
    final times = <int>[];
    final query = 'тестовый запрос для измерения скорости';

    try {
      for (int i = 0; i < 5; i++) {
        final queryStart = DateTime.now();
        await _searchService.search(query, limit: 10, minSimilarity: 0.0);
        final queryDuration = DateTime.now()
            .difference(queryStart)
            .inMilliseconds;
        times.add(queryDuration);
      }

      final avgTime = times.isNotEmpty
          ? (times.reduce((a, b) => a + b) / times.length).round()
          : 0;
      final maxTime = times.isNotEmpty
          ? times.reduce((a, b) => a > b ? a : b)
          : 0;
      final minTime = times.isNotEmpty
          ? times.reduce((a, b) => a < b ? a : b)
          : 0;

      final durationMs = DateTime.now().difference(start).inMilliseconds;

      if (avgTime < 100) {
        return DiagnosticResult(
          checkName: name,
          description: description,
          severity: DiagnosticSeverity.pass,
          message:
              'Скорость поиска отличная: среднее ${avgTime}мс (min: ${minTime}мс, max: ${maxTime}мс)',
          affectedCount: times.length,
          durationMs: durationMs,
        );
      } else if (avgTime < 500) {
        return DiagnosticResult(
          checkName: name,
          description: description,
          severity: DiagnosticSeverity.pass,
          message:
              'Скорость поиска хорошая: среднее ${avgTime}мс (min: ${minTime}мс, max: ${maxTime}мс)',
          affectedCount: times.length,
          durationMs: durationMs,
        );
      } else if (avgTime < 1000) {
        return DiagnosticResult(
          checkName: name,
          description: description,
          severity: DiagnosticSeverity.warn,
          message:
              'Скорость поиска средняя: среднее ${avgTime}мс (min: ${minTime}мс, max: ${maxTime}мс)',
          recommendation:
              'Рассмотрите оптимизацию: индексы, размер базы, кэширование',
          durationMs: durationMs,
        );
      } else {
        return DiagnosticResult(
          checkName: name,
          description: description,
          severity: DiagnosticSeverity.fail,
          message:
              'Скорость поиска низкая: среднее ${avgTime}мс (min: ${minTime}мс, max: ${maxTime}мс)',
          recommendation:
              'Требуется оптимизация: проверьте индексы SQLite, размер базы, количество эмбеддингов',
          durationMs: durationMs,
        );
      }
    } catch (e) {
      final durationMs = DateTime.now().difference(start).inMilliseconds;
      return DiagnosticResult(
        checkName: name,
        description: description,
        severity: DiagnosticSeverity.error,
        message: 'Ошибка при проверке: $e',
        durationMs: durationMs,
      );
    }
  }
}
