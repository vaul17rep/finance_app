import 'package:sqflite/sqflite.dart';

import '../diagnostic_check.dart';
import '../diagnostic_result.dart';
import '../diagnostic_severity.dart';

class StaleCheck implements DiagnosticCheck {
  final Database _database;

  StaleCheck(this._database);

  @override
  String get name => 'Устаревшие эмбеддинги';

  @override
  String get description =>
      'Проверяет, есть ли эмбеддинги, где sourceUpdatedAt > embeddingUpdatedAt';

  @override
  Future<DiagnosticResult> run() async {
    final start = DateTime.now();

    try {
      final result = await _database.rawQuery(
        '''
        SELECT COUNT(*) as count
        FROM embeddings
        WHERE datetime(sourceUpdatedAt) > datetime(embeddingUpdatedAt)
        ''',
      );

      final count = result.first['count'] as int? ?? 0;

      final durationMs =
          DateTime.now().difference(start).inMilliseconds;

      final metrics = {
        'staleEmbeddings': count,
      };

      if (count == 0) {
        return DiagnosticResult(
          checkName: name,
          description: description,
          severity: DiagnosticSeverity.pass,
          message: 'Устаревшие эмбеддинги не найдены',
          durationMs: durationMs,
          metrics: metrics,
        );
      }

      final samplesResult = await _database.rawQuery(
        '''
        SELECT id, sourceType, sourceId
        FROM embeddings
        WHERE datetime(sourceUpdatedAt) > datetime(embeddingUpdatedAt)
        LIMIT 5
        ''',
      );

      final samples = samplesResult.map((row) {
        return '${row['sourceType']}/${row['sourceId']} '
            '(${row['id']})';
      }).toList();

      return DiagnosticResult(
        checkName: name,
        description: description,
        severity: DiagnosticSeverity.warn,
        message:
            'Найдено $count устаревших эмбеддингов '
            '(источник обновлён после индексации)',
        affectedCount: count,
        samples: samples,
        recommendation:
            'Запустите переиндексацию для этих источников',
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