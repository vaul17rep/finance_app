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

import 'core/theme/app_theme.dart';
import 'features/navigation/main_navigation.dart';
import 'core/theme/theme_notifier.dart';
import 'core/preferences/color_settings_notifier.dart';
import 'core/debug/debug_logger.dart';
import 'features/memory/services/vector_search_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DebugLogger().init();

  if (Platform.isWindows) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await DatabaseHelper.instance.debugOperationsTable();

  // --- Инициализация зависимостей для Memory / Индексации ---
  // 1. Репозитории
  final embeddingRepository = EmbeddingRepository(MemoryDatabase.instance);
  final receiptRepository = ReceiptRepository();
  final memoryNoteRepository = MemoryNoteRepository(MemoryDatabase.instance);

  // 2. Сервисы
  final openRouterService = OpenRouterService(profile: AiProfiles.paid);
  final embeddingService = EmbeddingService(openRouterService);
  final vectorSearchService = SqliteVectorSearchService(embeddingRepository);

  // 3. IndexingService
  final indexingService = IndexingService(
    embeddingService: embeddingService,
    vectorSearchService: vectorSearchService,
    receiptRepository: receiptRepository,
    memoryNoteRepository: memoryNoteRepository,
    taskManager: BackgroundTaskManager.instance,
    embeddingModel: AppSettings.embeddingModel,
    embeddingVersion: AppSettings.embeddingVersion,
  );

  // 4. Инициализируем BackgroundTaskManager
  BackgroundTaskManager.instance.init(
    indexingService: indexingService,
    vectorSearchService: vectorSearchService,
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
        vectorSearchService: vectorSearchService,
        embeddingService: embeddingService,
        indexingService: indexingService,
      ),
    ),
  );
}

class FinanceApp extends StatelessWidget {
  final VectorSearchService vectorSearchService;
  final EmbeddingService embeddingService;
  final IndexingService indexingService;

  const FinanceApp({
    super.key,
    required this.vectorSearchService,
    required this.embeddingService,
    required this.indexingService,
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
      ),
    );
  }
}
