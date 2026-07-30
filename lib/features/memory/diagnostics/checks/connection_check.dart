import 'package:sqflite/sqflite.dart';
import '../diagnostic_check.dart';
import '../diagnostic_result.dart';
import '../diagnostic_severity.dart';

class ConnectionCheck implements DiagnosticCheck {
  final Database _database;

  ConnectionCheck(this._database);

  @override
  String get name => 'Подключение к БД';

  @override
  String get description => 'Проверяет доступность таблицы embeddings';

  @override
  Future<DiagnosticResult> run() async {
    final start = DateTime.now();

    try {
      final result = await _database.rawQuery(
        "SELECT name FROM sqlite_master "
        "WHERE type='table' AND name='embeddings'",
      );

      final durationMs = DateTime.now().difference(start).inMilliseconds;

      if (result.isNotEmpty) {
        return DiagnosticResult(
          checkName: name,
          description: description,
          severity: DiagnosticSeverity.pass,
          message: 'Таблица embeddings существует и доступна',
          durationMs: durationMs,
        );
      }

      return DiagnosticResult(
        checkName: name,
        description: description,
        severity: DiagnosticSeverity.fail,
        message: 'Таблица embeddings не найдена в базе данных',
        recommendation:
            'Запустите миграцию базы данных для создания таблицы embeddings',
        durationMs: durationMs,
      );
    } catch (e) {
      final durationMs = DateTime.now().difference(start).inMilliseconds;

      return DiagnosticResult(
        checkName: name,
        description: description,
        severity: DiagnosticSeverity.error,
        message: 'Ошибка при проверке подключения: $e',
        durationMs: durationMs,
      );
    }
  }
}
