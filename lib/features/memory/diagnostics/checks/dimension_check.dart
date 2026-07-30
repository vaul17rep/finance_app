import 'dart:typed_data';
import 'package:sqflite/sqflite.dart';

import '../../utils/vector_utils.dart';
import '../diagnostic_check.dart';
import '../diagnostic_result.dart';
import '../diagnostic_severity.dart';

class DimensionCheck implements DiagnosticCheck {
  final Database _database;
  final int _expectedDimension;

  static const int _sampleLimit = 100;

  DimensionCheck(
    this._database, {
    int? expectedDimension,
  }) : _expectedDimension = expectedDimension ?? 1536;

  @override
  String get name => 'Размерность векторов';

  @override
  String get description =>
      'Проверяет, что все векторы имеют ожидаемую размерность ($_expectedDimension)';

  @override
  Future<DiagnosticResult> run() async {
    final start = DateTime.now();

    try {
      final result = await _database.rawQuery(
        'SELECT id, sourceType, sourceId, vector '
        'FROM embeddings LIMIT $_sampleLimit',
      );

      final dimensions = <int>[];
      int invalidCount = 0;

      final samples = <String>[];

      for (final row in result) {
        final vectorBlob = row['vector'] as Uint8List?;

        if (vectorBlob == null || vectorBlob.isEmpty) {
          continue;
        }

        try {
          final vector = blobToVector(vectorBlob);
          final dim = vector.length;

          dimensions.add(dim);

          if (dim != _expectedDimension) {
            invalidCount++;

            if (samples.length < 5) {
              samples.add(
                '${row['sourceType']}/${row['sourceId']} '
                '(размерность: $dim)',
              );
            }
          }
        } catch (e) {
          invalidCount++;

          if (samples.length < 5) {
            samples.add(
              '${row['sourceType']}/${row['sourceId']} '
              '(ошибка декодирования)',
            );
          }
        }
      }

      final totalChecked = result.length;

      final durationMs =
          DateTime.now().difference(start).inMilliseconds;

      final avgDim = dimensions.isNotEmpty
          ? (dimensions.reduce((a, b) => a + b) /
                  dimensions.length)
              .round()
          : 0;

      final minDim = dimensions.isNotEmpty
          ? dimensions.reduce((a, b) => a < b ? a : b)
          : 0;

      final maxDim = dimensions.isNotEmpty
          ? dimensions.reduce((a, b) => a > b ? a : b)
          : 0;

      final metrics = {
        'avgDimension': avgDim,
        'minDimension': minDim,
        'maxDimension': maxDim,
        'invalidDimensions': invalidCount,
        'checkedVectors': totalChecked,
      };

      if (dimensions.isEmpty && totalChecked == 0) {
        return DiagnosticResult(
          checkName: name,
          description: description,
          severity: DiagnosticSeverity.warn,
          message: 'Нет данных для проверки размерности (нет эмбеддингов)',
          durationMs: durationMs,
          metrics: metrics,
        );
      }

      if (invalidCount == 0 && dimensions.isNotEmpty) {
        return DiagnosticResult(
          checkName: name,
          description: description,
          severity: DiagnosticSeverity.pass,
          message:
              'Все векторы имеют размерность $_expectedDimension '
              '(проверено $totalChecked записей)',
          affectedCount: totalChecked,
          durationMs: durationMs,
          metrics: metrics,
        );
      }

      final errorRate =
          totalChecked > 0 ? invalidCount / totalChecked : 0;

      final severity = errorRate > 0.2
          ? DiagnosticSeverity.fail
          : DiagnosticSeverity.warn;

      return DiagnosticResult(
        checkName: name,
        description: description,
        severity: severity,
        message:
            'Найдено $invalidCount векторов с неверной размерностью. '
            'Ожидается: $_expectedDimension, '
            'средняя: $avgDim, min: $minDim, max: $maxDim',
        affectedCount: invalidCount,
        samples: samples,
        recommendation:
            'Проверьте модель эмбеддингов. Возможно, используется другая модель.',
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