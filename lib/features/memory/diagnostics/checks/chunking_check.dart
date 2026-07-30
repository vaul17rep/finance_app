import '../../services/chunking_service.dart';
import '../diagnostic_check.dart';
import '../diagnostic_result.dart';
import '../diagnostic_severity.dart';

class ChunkingCheck implements DiagnosticCheck {
  final ChunkingService _chunkingService;

  ChunkingCheck(this._chunkingService);

  @override
  String get name => 'Качество чанкинга';

  @override
  String get description => 'Проверяет корректность разбиения текста на чанки';

  // features/memory/diagnostics/checks/chunking_check.dart

  @override
  Future<DiagnosticResult> run() async {
    final start = DateTime.now();

    try {
      final testTexts = [
        'Купил молоко 3.2% 1л за 89 рублей в Пятёрочке.',
        'Продукты: хлеб (45 руб), масло (120 руб), яйца (95 руб). Всего 260 руб.',
        'Очень длинный текст для проверки чанкинга. ' * 20,
        '',
      ];

      final issues = <String>[];
      int totalChunks = 0;
      int tooSmallChunks = 0;
      int tooLargeChunks = 0;

      for (final text in testTexts) {
        if (text.isEmpty) {
          final chunks = await _chunkingService.chunk(text);
          if (chunks.isNotEmpty) {
            issues.add('Пустой текст создал ${chunks.length} чанков');
          }
          continue;
        }

        final chunks = await _chunkingService.chunk(text);
        totalChunks += chunks.length;

        for (final chunk in chunks) {
          final length = chunk.content.length;
          if (length < 10 && length > 0) {
            tooSmallChunks++;
            if (issues.length < 3) {
              final preview = chunk.content.length > 30
                  ? '${chunk.content.substring(0, 30)}...'
                  : chunk.content;
              issues.add(
                'Слишком короткий чанк (${length} символов): "$preview"',
              );
            }
          }
          if (length > 1000) {
            tooLargeChunks++;
            if (issues.length < 3) {
              issues.add('Слишком большой чанк (${length} символов)');
            }
          }
        }
      }

      final durationMs = DateTime.now().difference(start).inMilliseconds;

      if (issues.isEmpty) {
        return DiagnosticResult(
          checkName: name,
          description: description,
          severity: DiagnosticSeverity.pass,
          message: 'Чанкинг работает корректно (создано $totalChunks чанков)',
          durationMs: durationMs,
        );
      }

      final severity = (tooSmallChunks + tooLargeChunks) > 5
          ? DiagnosticSeverity.warn
          : DiagnosticSeverity.pass;

      return DiagnosticResult(
        checkName: name,
        description: description,
        severity: severity,
        message:
            'Найдены проблемы в чанкинге: $tooSmallChunks слишком коротких, $tooLargeChunks слишком длинных',
        samples: issues.take(5).toList(),
        recommendation:
            'Проверьте настройки ChunkingService (chunkSize, overlap)',
        durationMs: durationMs,
      );
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
