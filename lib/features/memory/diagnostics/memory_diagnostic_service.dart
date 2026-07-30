import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'diagnostic_check.dart';
import 'diagnostic_report.dart';
import 'diagnostic_result.dart';
import 'diagnostic_error.dart';
import 'diagnostic_metrics.dart';
import 'diagnostic_version.dart';
import 'calculators/health_score_calculator.dart';
import 'generators/markdown_report_generator.dart';
import '../../../core/debug/debug_logger.dart';

import 'package:sqflite/sqflite.dart';
import 'checks/connection_check.dart';
import 'checks/count_check.dart';
import 'checks/empty_vector_check.dart';
import 'checks/invalid_vector_check.dart';
import 'checks/dimension_check.dart';
import 'checks/duplicate_check.dart';
import 'checks/stale_check.dart';
import 'checks/chunking_check.dart';
import 'checks/embedding_api_check.dart';
import 'checks/similarity_check.dart';
import 'checks/search_quality_check.dart';
import 'checks/performance_check.dart';

import '../services/embedding_service.dart';
import '../services/chunking_service.dart';
import '../services/semantic_search_service.dart';
import '../services/vector_similarity_service.dart';

class MemoryDiagnosticService {
  final List<DiagnosticCheck> _checks = [];
  final HealthScoreCalculator _healthCalculator = HealthScoreCalculator();
  final MarkdownReportGenerator _reportGenerator = MarkdownReportGenerator();

  // features/memory/diagnostics/memory_diagnostic_service.dart

  static Future<MemoryDiagnosticService> createWithAllChecks({
    required Database database,
    required EmbeddingService embeddingService,
    required ChunkingService chunkingService,
    required SemanticSearchService searchService,
    required VectorSimilarityService similarityService,
  }) async {
    final service = MemoryDiagnosticService();

    service.registerAll([
      ConnectionCheck(database),
      CountCheck(database),
      EmptyVectorCheck(database),
      InvalidVectorCheck(database),
      DimensionCheck(
        database,
        expectedDimension: await _getExpectedDimension(embeddingService),
      ),
      DuplicateCheck(database),
      StaleCheck(database),
      ChunkingCheck(chunkingService),
      EmbeddingApiCheck(embeddingService),
      SimilarityCheck(similarityService),
      SearchQualityCheck(searchService),
      PerformanceCheck(searchService),
    ]);

    return service;
  }

  static Future<int> _getExpectedDimension(EmbeddingService service) async {
    try {
      final vector = await service.getEmbeddingVector('test');
      return vector.length;
    } catch (_) {
      return 1536; // fallback
    }
  }

  void register(DiagnosticCheck check) {
    _checks.add(check);
  }

  void registerAll(List<DiagnosticCheck> checks) {
    _checks.addAll(checks);
  }

  Future<DiagnosticReport> runDiagnostics() async {
    DebugLogger().logMemory(
      'Начата диагностика памяти',
      extra: {'checks': _checks.length},
    );
    final startTime = DateTime.now();
    final results = <DiagnosticResult>[];
    final errors = <DiagnosticError>[];
    final metricData = <String, dynamic>{};
    int totalEmbeddings = 0;
    Map<String, int> bySourceType = {};
    int emptyVectors = 0;
    int invalidVectors = 0;
    int avgDimension = 1536;
    int minDimension = 1536;
    int maxDimension = 1536;
    int duplicates = 0;
    int staleEmbeddings = 0;
    double top1Accuracy = 0.0;
    double top3Accuracy = 0.0;
    double avgCosineSimilarity = 0.0;
    int avgSearchTimeMs = 0;

    for (final check in _checks) {
      try {
        DebugLogger().logMemory(
          'Запуск проверки: ${check.name}',
          level: LogLevel.debug,
        );
        final result = await check.run();
        results.add(result);

        DebugLogger().logMemory(
          '${result.severity.name.toUpperCase()}: ${result.checkName}',
          extra: {
            'message': result.message,
            'durationMs': result.durationMs,
            'affected': result.affectedCount,
          },
        );

        // Агрегируем метрики из результатов
        // TODO: реализовать агрегацию метрик из результатов проверок
      } catch (e, stack) {
        errors.add(
          DiagnosticError(
            checkName: check.name,
            errorMessage: e.toString(),
            stackTrace: stack,
          ),
        );

        DebugLogger().logMemory(
          'Ошибка проверки: ${check.name}',
          level: LogLevel.error,
          error: e,
          stackTrace: stack,
        );
      }
    }

    final endTime = DateTime.now();
    final totalDurationMs = endTime.difference(startTime).inMilliseconds;

    // TODO: собрать реальные метрики из результатов проверок
    final metrics = DiagnosticMetrics(
      totalEmbeddings: totalEmbeddings,
      bySourceType: bySourceType,
      emptyVectors: emptyVectors,
      invalidVectors: invalidVectors,
      avgDimension: avgDimension,
      minDimension: minDimension,
      maxDimension: maxDimension,
      duplicates: duplicates,
      staleEmbeddings: staleEmbeddings,
      top1Accuracy: top1Accuracy,
      top3Accuracy: top3Accuracy,
      avgCosineSimilarity: avgCosineSimilarity,
      avgSearchTimeMs: avgSearchTimeMs,
      healthScore: _healthCalculator.calculate(
        DiagnosticMetrics(
          totalEmbeddings: totalEmbeddings,
          bySourceType: bySourceType,
          emptyVectors: emptyVectors,
          invalidVectors: invalidVectors,
          avgDimension: avgDimension,
          minDimension: minDimension,
          maxDimension: maxDimension,
          duplicates: duplicates,
          staleEmbeddings: staleEmbeddings,
          top1Accuracy: top1Accuracy,
          top3Accuracy: top3Accuracy,
          avgCosineSimilarity: avgCosineSimilarity,
          avgSearchTimeMs: avgSearchTimeMs,
          healthScore: 0,
        ),
      ),
    );

    final report = DiagnosticReport(
      timestamp: DateTime.now(),
      diagnosticVersion: DiagnosticVersion.version,
      appVersion: await DiagnosticVersion.getAppVersion(),
      embeddingModel: DiagnosticVersion.embeddingModel,
      dbSchemaVersion: DiagnosticVersion.dbSchemaVersion,
      results: results,
      errors: errors,
      metrics: metrics,
      totalDurationMs: totalDurationMs,
    );

    // Сохраняем отчёт в файл
    await _saveReport(report);

    DebugLogger().logMemory(
      'Диагностика завершена',
      extra: {
        'healthScore': metrics.healthScore,
        'durationMs': totalDurationMs,
        'pass': report.passCount,
        'warn': report.warnCount,
        'fail': report.failCount,
        'errors': report.errorCount,
      },
    );

    return report;
  }

  Future<void> _saveReport(DiagnosticReport report) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final diagnosticDir = Directory('${dir.path}/diagnostics');
      if (!await diagnosticDir.exists()) {
        await diagnosticDir.create(recursive: true);
      }

      final markdown = _reportGenerator.generate(report);
      final reportPath =
          '${diagnosticDir.path}/memory_diagnostic_${DateTime.now().toIso8601String().replaceAll(':', '-')}.md';
      await File(reportPath).writeAsString(markdown);
    } catch (e) {
      // Не даём ошибке сохранения убить диагностику
    }
  }
}
