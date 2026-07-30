import '../diagnostic_check.dart';
import '../diagnostic_result.dart';
import '../diagnostic_severity.dart';
import '../test_cases/search_test_cases.dart';
import '../../services/embedding_service.dart';
import '../../services/vector_search_service.dart';

class SearchDiagnosticCheck implements DiagnosticCheck {
  final SearchTestCase testCase;
  final VectorSearchService vectorSearchService;
  final EmbeddingService embeddingService;

  SearchDiagnosticCheck({
    required this.testCase,
    required this.vectorSearchService,
    required this.embeddingService,
  });

  @override
  String get name => 'Search: ${testCase.query}';

  @override
  String get description => 'Проверка поиска по запросу "${testCase.query}"';

  @override
  Future<DiagnosticResult> run() async {
    final stopwatch = Stopwatch()..start();

    try {
      final vector = await embeddingService.getEmbeddingBlob(testCase.query);

      final results = await vectorSearchService.search(vector, limit: 10);

      stopwatch.stop();

      if (results.isEmpty) {
        return DiagnosticResult(
          checkName: name,
          description: 'Проверка семантического поиска',
          severity: DiagnosticSeverity.fail,
          message: 'Нет результатов для запроса "${testCase.query}"',
          durationMs: stopwatch.elapsedMilliseconds,
          recommendation: 'Проверить индексацию и наличие эмбеддингов',
        );
      }

      if (testCase.expectedContentSubstring != null) {
        final expected = testCase.expectedContentSubstring!.toLowerCase();

        final found = results.any(
          (item) => item.content.toLowerCase().contains(expected),
        );

        if (!found) {
          return DiagnosticResult(
            checkName: name,
            description: 'Проверка содержимого результата',
            severity: DiagnosticSeverity.fail,
            message: 'Не найден ожидаемый текст: "$expected"',
            affectedCount: results.length,
            samples: results
                .take(3)
                .map(
                  (e) => e.content.substring(
                    0,
                    e.content.length > 50 ? 50 : e.content.length,
                  ),
                )
                .toList(),
            durationMs: stopwatch.elapsedMilliseconds,
            recommendation:
                'Проверить качество индексации или embedding модели',
          );
        }
      }

      return DiagnosticResult(
        checkName: name,
        description: 'Проверка семантического поиска',
        severity: DiagnosticSeverity.pass,
        message: 'OK',
        affectedCount: results.length,
        durationMs: stopwatch.elapsedMilliseconds,
      );
    } catch (e) {
      stopwatch.stop();

      return DiagnosticResult(
        checkName: name,
        description: 'Проверка семантического поиска',
        severity: DiagnosticSeverity.error,
        message: e.toString(),
        durationMs: stopwatch.elapsedMilliseconds,
        recommendation: 'Проверить VectorSearchService и EmbeddingService',
      );
    }
  }
}
