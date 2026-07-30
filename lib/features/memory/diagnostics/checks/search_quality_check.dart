import '../../services/semantic_search_service.dart';
import '../diagnostic_check.dart';
import '../diagnostic_result.dart';
import '../diagnostic_severity.dart';
import '../test_cases/search_test_cases.dart';

class SearchQualityCheck implements DiagnosticCheck {
  final SemanticSearchService _searchService;

  SearchQualityCheck(this._searchService);

  @override
  String get name => 'Качество поиска';

  @override
  String get description => 'Проверяет, находит ли поиск ожидаемые результаты';

  bool _containsExpected(dynamic result, SearchTestCase testCase) {
    final expected = testCase.expectedContentSubstring ?? '';

    if (result == null || expected.isEmpty) {
      return false;
    }

    final content = result.content ?? '';
    if (content.isEmpty) {
      return false;
    }

    return content.toLowerCase().contains(expected.toLowerCase());
  }

  @override
  Future<DiagnosticResult> run() async {
    final start = DateTime.now();

    try {
      int top1Success = 0;
      int top3Success = 0;
      int total = 0;
      final failures = <String>[];

      for (final testCase in searchTestCases) {
        total++;
        final results = await _searchService.search(
          testCase.query,
          limit: 10,
          minSimilarity: 0.0,
        );

        final foundTop1 =
            results.isNotEmpty && _containsExpected(results.first, testCase);

        if (foundTop1) {
          top1Success++;
          top3Success++;
          continue;
        }

        final top3 = results.take(3).toList();
        final foundTop3 = top3.any((r) => _containsExpected(r, testCase));

        if (foundTop3) {
          top3Success++;
        } else {
          if (failures.length < 5) {
            final content = results.isNotEmpty
                ? (results.first.content ?? '')
                : '';

            final foundText = content.isNotEmpty
                ? content.substring(
                    0,
                    content.length > 50 ? 50 : content.length,
                  )
                : 'нет результатов';
            failures.add(
              'Запрос: "${testCase.query}" → ожидалось: "${testCase.expectedContentSubstring}", '
              'найдено: "$foundText..."',
            );
          }
        }
      }

      final top1Accuracy = total > 0 ? top1Success / total : 0;
      final top3Accuracy = total > 0 ? top3Success / total : 0;

      final durationMs = DateTime.now().difference(start).inMilliseconds;

      if (total == 0) {
        return DiagnosticResult(
          checkName: name,
          description: description,
          severity: DiagnosticSeverity.warn,
          message: 'Нет тестовых кейсов для проверки качества',
          durationMs: durationMs,
        );
      }

      if (top3Accuracy >= 0.8) {
        return DiagnosticResult(
          checkName: name,
          description: description,
          severity: DiagnosticSeverity.pass,
          message:
              'Качество поиска хорошее: Top-1: ${(top1Accuracy * 100).toStringAsFixed(0)}%, '
              'Top-3: ${(top3Accuracy * 100).toStringAsFixed(0)}%',
          durationMs: durationMs,
        );
      } else if (top3Accuracy >= 0.5) {
        return DiagnosticResult(
          checkName: name,
          description: description,
          severity: DiagnosticSeverity.warn,
          message:
              'Качество поиска среднее: Top-1: ${(top1Accuracy * 100).toStringAsFixed(0)}%, '
              'Top-3: ${(top3Accuracy * 100).toStringAsFixed(0)}%',
          samples: failures,
          recommendation:
              'Проверьте настройки поиска, модель эмбеддингов и качество индексации',
          durationMs: durationMs,
        );
      } else {
        return DiagnosticResult(
          checkName: name,
          description: description,
          severity: DiagnosticSeverity.fail,
          message:
              'Качество поиска низкое: Top-1: ${(top1Accuracy * 100).toStringAsFixed(0)}%, '
              'Top-3: ${(top3Accuracy * 100).toStringAsFixed(0)}%',
          samples: failures,
          recommendation:
              'Срочно проверьте индексацию, модель эмбеддингов и чанкинг',
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
