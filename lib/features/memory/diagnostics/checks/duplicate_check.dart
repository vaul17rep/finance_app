import 'package:sqflite/sqflite.dart';

import '../diagnostic_check.dart';
import '../diagnostic_result.dart';
import '../diagnostic_severity.dart';

class DuplicateCheck implements DiagnosticCheck {
  final Database _database;

  DuplicateCheck(this._database);

  @override
  String get name => 'Дубликаты эмбеддингов';

  @override
  String get description =>
      'Проверяет наличие дублирующихся записей по (sourceType, sourceId, content)';

  @override
  Future<DiagnosticResult> run() async {
    final start = DateTime.now();

    try {
      final result = await _database.rawQuery(
        '''
        SELECT sourceType, sourceId, content, COUNT(*) as count
        FROM embeddings
        GROUP BY sourceType, sourceId, content
        HAVING COUNT(*) > 1
        ''',
      );

      final duplicates = result.length;

      final durationMs =
          DateTime.now().difference(start).inMilliseconds;

      final metrics = {
        'duplicates': duplicates,
      };

      if (duplicates == 0) {
        return DiagnosticResult(
          checkName: name,
          description: description,
          severity: DiagnosticSeverity.pass,
          message: 'Дубликаты не найдены',
          durationMs: durationMs,
          metrics: metrics,
        );
      }

      final samples = result.take(5).map((row) {
        return '${row['sourceType']}/${row['sourceId']} '
            '(${row['count']} копий)';
      }).toList();

      return DiagnosticResult(
        checkName: name,
        description: description,
        severity: DiagnosticSeverity.warn,
        message: 'Найдено $duplicates дублирующихся записей',
        affectedCount: duplicates,
        samples: samples,
        recommendation:
            'Дубликаты могут быть результатом повторной индексации. '
            'Рекомендуется запустить очистку дубликатов.',
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
        message: 'Ошибка при проверке: $e',
        durationMs: durationMs,
      );
    }
  }
}