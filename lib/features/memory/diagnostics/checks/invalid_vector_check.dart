import 'dart:typed_data';

import 'package:sqflite/sqflite.dart';

import '../../utils/vector_utils.dart';
import '../diagnostic_check.dart';
import '../diagnostic_result.dart';
import '../diagnostic_severity.dart';

class InvalidVectorCheck implements DiagnosticCheck {
  final Database _database;

  static const int _sampleLimit = 100;

  InvalidVectorCheck(this._database);

  @override
  String get name => 'Некорректные векторы';

  @override
  String get description =>
      'Проверяет, можно ли декодировать BLOB в Float32Array';

  @override
  Future<DiagnosticResult> run() async {
    final start = DateTime.now();

    try {
      final result = await _database.rawQuery(
        'SELECT id, sourceType, sourceId, vector '
        'FROM embeddings LIMIT $_sampleLimit',
      );

      int invalidCount = 0;

      final samples = <String>[];

      for (final row in result) {
        final vectorBlob = row['vector'] as Uint8List?;

        if (vectorBlob == null || vectorBlob.isEmpty) {
          continue;
        }

        try {
          final vector = blobToVector(vectorBlob);

          if (vector.isEmpty) {
            invalidCount++;

            if (samples.length < 5) {
              samples.add(
                '${row['sourceType']}/${row['sourceId']} '
                '(пустой массив)',
              );
            }
          }
        } catch (e) {
          invalidCount++;

          if (samples.length < 5) {
            samples.add(
              '${row['sourceType']}/${row['sourceId']} '
              '(ошибка: $e)',
            );
          }
        }
      }

      final durationMs =
          DateTime.now().difference(start).inMilliseconds;

      final totalChecked = result.length;

      final errorRate =
          totalChecked > 0 ? invalidCount / totalChecked : 0;

      final metrics = {
        'invalidVectors': invalidCount,
        'checkedVectors': totalChecked,
      };

      if (invalidCount == 0) {
        return DiagnosticResult(
          checkName: name,
          description: description,
          severity: DiagnosticSeverity.pass,
          message:
              'Все векторы в выборке корректны '
              '(проверено $totalChecked записей)',
          durationMs: durationMs,
          metrics: metrics,
        );
      }

      final severity = errorRate > 0.2
          ? DiagnosticSeverity.fail
          : DiagnosticSeverity.warn;

      return DiagnosticResult(
        checkName: name,
        description: description,
        severity: severity,
        message:
            'Найдено $invalidCount некорректных векторов '
            'из $totalChecked проверенных '
            '(${(errorRate * 100).toStringAsFixed(0)}%)',
        affectedCount: invalidCount,
        samples: samples,
        recommendation: errorRate > 0.2
            ? 'Массовая проблема с векторами. '
                'Требуется переиндексация всех данных.'
            : 'Некорректные записи можно удалить '
                'и переиндексировать',
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