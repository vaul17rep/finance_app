import '../../services/vector_similarity_service.dart';
import '../diagnostic_check.dart';
import '../diagnostic_result.dart';
import '../diagnostic_severity.dart';

class SimilarityCheck implements DiagnosticCheck {
  final VectorSimilarityService _similarityService;

  SimilarityCheck(this._similarityService);

  @override
  String get name => 'Косинусное сходство';

  @override
  String get description =>
      'Проверяет корректность вычисления косинусного сходства';

  @override
  Future<DiagnosticResult> run() async {
    final start = DateTime.now();

    try {
      final vectorA = List<double>.filled(10, 0.5);
      final vectorB = List<double>.filled(10, 0.51);
      final vectorC = List<double>.filled(10, -0.5);

      final similarityAB =
          _similarityService.cosineSimilarity(vectorA, vectorB);

      final similarityAC =
          _similarityService.cosineSimilarity(vectorA, vectorC);

      final durationMs =
          DateTime.now().difference(start).inMilliseconds;

      final metrics = {
        'avgCosineSimilarity':
            (similarityAB + similarityAC) / 2,
        'similaritySimilarVectors': similarityAB,
        'similarityDifferentVectors': similarityAC,
      };

      if (similarityAB < 0.9) {
        return DiagnosticResult(
          checkName: name,
          description: description,
          severity: DiagnosticSeverity.fail,
          message:
              'Сходство похожих векторов слишком низкое: '
              '$similarityAB (ожидалось > 0.9)',
          recommendation:
              'Проверьте реализацию cosineSimilarity '
              'в VectorSimilarityService',
          durationMs: durationMs,
          metrics: metrics,
        );
      }

      if (similarityAC > -0.5) {
        return DiagnosticResult(
          checkName: name,
          description: description,
          severity: DiagnosticSeverity.warn,
          message:
              'Сходство разных векторов неожиданно высокое: '
              '$similarityAC',
          recommendation:
              'Проверьте реализацию cosineSimilarity',
          durationMs: durationMs,
          metrics: metrics,
        );
      }

      return DiagnosticResult(
        checkName: name,
        description: description,
        severity: DiagnosticSeverity.pass,
        message:
            'Косинусное сходство вычисляется корректно '
            '(похожие: ${similarityAB.toStringAsFixed(3)}, '
            'разные: ${similarityAC.toStringAsFixed(3)})',
        durationMs: durationMs,
        metrics: metrics,
      );
    } catch (e) {
      final durationMs =
          DateTime.now().difference(start).inMilliseconds;

      return DiagnosticResult(
        checkName: name,
        description: description,
        severity: DiagnosticSeverity.error,
        message:
            'Ошибка при проверке: $e',
        durationMs: durationMs,
      );
    }
  }
}