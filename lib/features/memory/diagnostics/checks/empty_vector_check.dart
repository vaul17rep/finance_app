import 'package:sqflite/sqflite.dart';

import '../diagnostic_check.dart';
import '../diagnostic_result.dart';
import '../diagnostic_severity.dart';

class EmptyVectorCheck implements DiagnosticCheck {
  final Database _database;

  EmptyVectorCheck(this._database);

  @override
  String get name => 'Пустые векторы';

  @override
  String get description =>
      'Проверяет записи с пустым или NULL вектором';

  @override
  Future<DiagnosticResult> run() async {
    final start = DateTime.now();

    try {
      final result = await _database.rawQuery(
        '''
        SELECT COUNT(*) as count
        FROM embeddings
        WHERE vector IS NULL OR LENGTH(vector) = 0
        ''',
      );

      final count = result.first['count'] as int? ?? 0;

      final durationMs =
          DateTime.now().difference(start).inMilliseconds;

      final metrics = {
        'emptyVectors': count,
      };

      if (count == 0) {
        return DiagnosticResult(
          checkName: name,
          description: description,
          severity: DiagnosticSeverity.pass,
          message: 'Пустые векторы не найдены',
          durationMs: durationMs,
          metrics: metrics,
        );
      }

      final samplesResult = await _database.rawQuery(
        '''
        SELECT id, sourceType, sourceId
        FROM embeddings
        WHERE vector IS NULL OR LENGTH(vector) = 0
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
        severity: DiagnosticSeverity.fail,
        message:
            'Найдено $count записей с пустым вектором',
        affectedCount: count,
        samples: samples,
        recommendation:
            'Удалите эти записи или переиндексируйте источники',
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