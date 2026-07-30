import 'package:sqflite/sqflite.dart';
import '../diagnostic_check.dart';
import '../diagnostic_result.dart';
import '../diagnostic_severity.dart';

class CountCheck implements DiagnosticCheck {
  final Database _database;

  CountCheck(this._database);

  @override
  String get name => 'Количество эмбеддингов';

  @override
  String get description =>
      'Подсчёт общего количества и распределение по типам источников';

  @override
  Future<DiagnosticResult> run() async {
    final start = DateTime.now();

    try {
      // Общее количество эмбеддингов
      final totalResult = await _database.rawQuery(
        'SELECT COUNT(*) as count FROM embeddings',
      );

      final total = totalResult.first['count'] as int? ?? 0;

      // Распределение по типам источников
      final typeResult = await _database.rawQuery(
        'SELECT sourceType, COUNT(*) as count '
        'FROM embeddings '
        'GROUP BY sourceType',
      );

      final bySourceType = <String, int>{};

      for (final row in typeResult) {
        final type = row['sourceType'] as String? ?? 'unknown';
        final count = row['count'] as int? ?? 0;

        bySourceType[type] = count;
      }

      final durationMs = DateTime.now().difference(start).inMilliseconds;

      final metrics = {'totalEmbeddings': total, 'bySourceType': bySourceType};

      if (total == 0) {
        return DiagnosticResult(
          checkName: name,
          description: description,
          severity: DiagnosticSeverity.warn,
          message:
              'В базе данных нет эмбеддингов. Возможно, индексация ещё не запускалась.',
          affectedCount: 0,
          recommendation:
              'Запустите индексацию чеков или заметок в настройках.',
          durationMs: durationMs,
          metrics: metrics,
        );
      }

      final details = bySourceType.entries
          .map((e) => '${e.key}: ${e.value}')
          .join(', ');

      return DiagnosticResult(
        checkName: name,
        description: description,
        severity: DiagnosticSeverity.pass,
        message: 'Всего $total эмбеддингов ($details)',
        affectedCount: total,
        durationMs: durationMs,
        metrics: metrics,
      );
    } catch (e) {
      final durationMs = DateTime.now().difference(start).inMilliseconds;

      return DiagnosticResult(
        checkName: name,
        description: description,
        severity: DiagnosticSeverity.error,
        message: 'Ошибка при подсчёте эмбеддингов: $e',
        durationMs: durationMs,
      );
    }
  }
}
