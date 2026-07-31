import 'dart:async'; // для unawaited
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:provider/provider.dart';

import 'data/database/database_helper.dart';
import 'data/database/memory_database.dart';
import 'data/services/openrouter_service.dart';
import 'data/services/background_manager/background_task_manager.dart';
import 'data/repositories/receipt_repository.dart';
import 'features/memory/repositories/embedding_repository.dart';
import 'features/memory/repositories/memory_note_repository.dart';
import 'features/memory/services/embedding_service.dart';
import 'features/memory/services/indexing_service.dart';
import 'features/memory/services/sqlite_vector_search_service.dart';
import 'features/ai/ai_profiles.dart';
import 'core/preferences/app_settings.dart';
import 'features/memory/services/chunking_service.dart';
import 'features/memory/services/semantic_search_service.dart';
import 'features/memory/services/vector_similarity_service.dart';

import 'core/theme/app_theme.dart';
import 'features/navigation/main_navigation.dart';
import 'core/theme/theme_notifier.dart';
import 'core/preferences/color_settings_notifier.dart';
import 'core/debug/debug_logger.dart';
import 'features/memory/services/vector_search_service.dart';

const bool enableDiagnostics = bool.fromEnvironment(
  'ENABLE_DIAGNOSTICS',
  defaultValue: false,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (enableDiagnostics) {
    debugPrint('🔬 Диагностика памяти включена');
  }

  await DebugLogger().init();

  if (Platform.isWindows) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Проверяем и очищаем битые векторы
  await _checkAndCleanEmbeddings();

  await DatabaseHelper.instance.debugOperationsTable();

  // --- Инициализация зависимостей для Memory / Индексации ---
  // 1. Репозитории
  final embeddingRepository = EmbeddingRepository(MemoryDatabase.instance);
  final receiptRepository = ReceiptRepository();
  final memoryNoteRepository = MemoryNoteRepository(MemoryDatabase.instance);

  // 2. Сервисы
  final openRouterService = OpenRouterService(profile: AiProfiles.paid);
  final embeddingService = EmbeddingService(openRouterService);

  // Используем только старый движок (Инициатива A)
  final legacyVectorSearchService = SqliteVectorSearchService(
    embeddingRepository,
  );

  final chunkingService = ChunkingService();
  final vectorSimilarityService = const VectorSimilarityService();

  final semanticSearchService = SemanticSearchService(
    embeddingService: embeddingService,
    legacyService: legacyVectorSearchService,
    embeddingRepository: embeddingRepository,
    database: await MemoryDatabase.instance.database,
  );

  // 3. IndexingService (использует старый движок)
  final indexingService = IndexingService(
    embeddingService: embeddingService,
    vectorSearchService: legacyVectorSearchService,
    embeddingRepository: embeddingRepository,
    receiptRepository: receiptRepository,
    memoryNoteRepository: memoryNoteRepository,
    taskManager: BackgroundTaskManager.instance,
    embeddingModel: AppSettings.embeddingModel,
    embeddingVersion: AppSettings.embeddingVersion,
  );

  // 4. Инициализируем BackgroundTaskManager
  BackgroundTaskManager.instance.init(
    indexingService: indexingService,
    vectorSearchService: legacyVectorSearchService,
  );

  // --- Запуск приложения ---
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
        ChangeNotifierProvider(
          create: (_) => ColorSettingsNotifier()..loadSettings(),
        ),
      ],
      child: FinanceApp(
        vectorSearchService: legacyVectorSearchService,
        embeddingService: embeddingService,
        indexingService: indexingService,
        chunkingService: chunkingService,
        semanticSearchService: semanticSearchService,
        vectorSimilarityService: vectorSimilarityService,
      ),
    ),
  );
}

/// Проверяет существование таблицы embeddings и очищает битые записи.
Future<void> _checkAndCleanEmbeddings() async {
  try {
    final db = await MemoryDatabase.instance.database;

    // Проверяем существование таблицы
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='embeddings'",
    );
    if (result.isEmpty) {
      debugPrint('ℹ️ Таблица embeddings не существует, пропускаем очистку');
      return;
    }

    // Проверяем наличие колонки vector
    final columns = await db.rawQuery("PRAGMA table_info(embeddings)");
    final hasVectorColumn = columns.any((col) => col['name'] == 'vector');
    if (!hasVectorColumn) {
      debugPrint('ℹ️ Колонка vector отсутствует, пропускаем очистку');
      return;
    }

    // Удаляем битые векторы (длина не кратна 4)
    final deleted = await db.rawDelete(
      'DELETE FROM embeddings WHERE LENGTH(vector) % 4 != 0',
    );

    if (deleted > 0) {
      debugPrint('🗑️ Удалено битых эмбеддингов: $deleted');
      DebugLogger().logMemory(
        'Удалено битых эмбеддингов: $deleted',
        level: LogLevel.info,
      );
    }

    // Также удаляем старые эмбеддинги из служебных папок Obsidian
    final deletedObsidian = await db.rawDelete('''
      DELETE FROM embeddings 
      WHERE sourceType = 'obsidian_note' 
      AND (sourceId LIKE '%/.trash/%' 
        OR sourceId LIKE '%/.obsidian/%' 
        OR sourceId LIKE '%/.git/%'
        OR sourceId LIKE '%/.stversions/%')
    ''');

    if (deletedObsidian > 0) {
      debugPrint('🗑️ Удалено мусорных Obsidian эмбеддингов: $deletedObsidian');
      DebugLogger().logMemory(
        'Удалено мусорных Obsidian эмбеддингов: $deletedObsidian',
        level: LogLevel.info,
      );
    }
  } catch (e) {
    debugPrint('⚠️ Ошибка при очистке embeddings: $e');
    // Не прерываем выполнение приложения
  }
}

class FinanceApp extends StatelessWidget {
  final VectorSearchService vectorSearchService;
  final EmbeddingService embeddingService;
  final IndexingService indexingService;
  final ChunkingService chunkingService;
  final SemanticSearchService semanticSearchService;
  final VectorSimilarityService vectorSimilarityService;

  const FinanceApp({
    super.key,
    required this.vectorSearchService,
    required this.embeddingService,
    required this.indexingService,
    required this.chunkingService,
    required this.semanticSearchService,
    required this.vectorSimilarityService,
  });

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return MaterialApp(
      title: 'Мои финансы',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeNotifier.themeMode,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ru')],
      home: MainNavigation(
        vectorSearchService: vectorSearchService,
        embeddingService: embeddingService,
        indexingService: indexingService,
        chunkingService: chunkingService,
        semanticSearchService: semanticSearchService,
        vectorSimilarityService: vectorSimilarityService,
      ),
    );
  }
}
