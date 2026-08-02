## 02_Architecture.md

---

**Version:** 10.1
**Last Updated:** 2026-08-02

---

## Назначение

Источник истины по технической архитектуре LifeOS. Как устроена система и почему именно так.

---

## Область ответственности

### Отвечает за

- Техническую архитектуру, слои, модули, паттерны
- Структуру Flutter-проекта и правила зависимостей
- Взаимодействие компонентов
- Архитектурные решения и их причины

### НЕ отвечает за

- Текущее состояние → [[01_Current_State]]
- Бизнес-сущности → [[03_Domain_Model]]
- Финансовую логику → [[04_Financial_Rules]]
- Структуру хранения → [[05_Database_Specification]]
- AI и систему знаний → [[06_AI_System]]
- Пользовательские сценарии → [[07_Functional_Requirements]]

---

## Главный архитектурный принцип

Разделение ответственности между слоями:

```
Presentation Layer
↓
Application Logic Layer
↓
Domain Layer
↓
Repository Layer
↓
Data Layer
↓
External Services
```

**Цель:** изменение одного компонента не требует переписывать остальные.

Архитектурные решения принимаются System Architect и утверждаются Principal Architect. Изменения архитектуры в процессе разработки возможны только через IMPLEMENTATION BLOCKER. Процесс описан в [[11_Development_Guidelines]].

---

## Основные принципы

### Принцип 1 — Разделение UI и логики

UI: отображение, действия пользователя, состояние экрана.
❌ UI не делает: расчёт баланса, работу с SQLite, вызовы AI, финансовые правила.

### Принцип 2 — Операции — источник истины

❌ `Карта Сбер = 15000` и менять число
✅ `Доход +50000 → Расход -5000 → Перевод -3000 → Расчёт состояния`

### Принцип 3 — Бизнес-логика независима от технологий

Domain Layer не знает про Flutter, SQLite, AI API. Только сущности, правила, операции.

### Принцип 4 — Repository — граница между логикой и данными

❌ `Screen → SQLite` или `Widget → OpenRouter API`
✅ `Application Logic → Repository → Data Source → Database`

### Принцип 5 — AI — внешний инструмент

AI: распознавание, преобразование, помощь при вводе.
❌ AI не владеет финансовыми данными, не меняет состояния напрямую.

### Принцип 6 — Account — финансовый объект пользователя

Баланс формируется через операции, а не хранится числом.
✅ `Account → Operations → Financial Rules → Financial State`

### Принцип 7 — Модульная организация (Feature-based)

Функциональность в `lib/features/`. Каждый модуль независим: экраны, виджеты, сервисы, при необходимости — свои репозитории.

### Принцип 8 — Приватность по умолчанию

Все данные хранятся локально. Внешние вызовы (AI API, будущие интеграции) производятся только с явного согласия пользователя и только для выполнения конкретной функции. Данные не передаются третьим лицам.

### Принцип 9 — Бесплатная работающая версия

Все основные функции приложения полностью бесплатны. Приложение функционально без покупок. Платными могут быть только расширенные возможности (аналитика, интеграции, улучшенный AI), которые не влияют на базовую функциональность.

### Принцип 10 — Пользовательские поля как метаданные (НОВОЕ)

Пользовательские поля не являются частью финансовой модели. Они хранятся в отдельных таблицах и привязываются к сущностям через полиморфную связь. Это позволяет:

- Не менять основную схему БД при добавлении новых полей
- Гибко настраивать UI под нужды пользователя
- Сохранять финансовую логику чистой
- Поля не влияют на расчёт баланса, бюджета, долгов

---

## High Level Architecture

```
USER
↓
Presentation Layer (features/screens, widgets)
↓
Application Logic Layer (services, usecases, feature-specific logic)
↓
Domain Layer (entities, core calculators)
↓
Repository Layer (data/repositories, feature-specific repositories)
↓
Data Layer (database, models, local storage)
↓
Database / External Services
```

---

## Архитектурные уровни

### 1. Presentation Layer

**Где:** `lib/features/`, `lib/screens/`, `lib/core/widgets/`
**Содержит:** Screens, Widgets, UI Components, провайдеры состояния.
**Можно:** отображать данные, обрабатывать действия, обновлять интерфейс.
**Нельзя:** финансовые расчёты, SQLite, прямые вызовы AI.

### 2. Application Logic Layer

**Где:** `domain/usecases/`, `features/*/services/`, `data/services/`
**Содержит:** FinancialCalculator, FinancialService, ai_key_manager, сервисы фич, background_manager.
**Можно:** выполнять сценарии, координировать вызовы, управлять процессами.
**Нельзя:** UI, прямое хранение данных, структура SQLite.

### 2.5 Debug Layer (инфраструктурный)

**Где:** `core/debug/`, `features/debug/`
**Содержит:** `DebugLogger` (синглтон), `LogEntry`, экран и виджеты для просмотра логов.
**Ответственность:** сбор, хранение и отображение диагностической информации. Это единая точка входа для всей диагностики в приложении.

**Важное архитектурное решение:**
Все новые диагностические подсистемы (например, `MemoryDiagnosticService`) используют **только** `DebugLogger`.  
Они не создают собственных UI для отображения результатов и не хранят логи отдельно.

**Поток диагностики:**

```
DiagnosticButton (UI) → MemoryDiagnosticService → DiagnosticCheck[] → DebugLogger → DebugLogScreen
```

**Не является:** бизнес-логикой, не влияет на финансовые данные.

### 3. Domain Layer

**Где:** `lib/domain/`
**Содержит:** `entities/financial_state.dart`, `usecases/financial_calculator.dart`, `usecases/financial_service.dart`.
**Планируется:** Receipt Engine, Operation Engine, State Engine, History Engine, Analytics Engine.
**Не зависит от:** Flutter, SQLite, AI, внешних сервисов.

**FinancialState Entity:**
Вычисленный результат: состояние Account, итоговые значения.
Источник истины: `Account → Operations → Financial Rules → FinancialState`.

### 4. Repository Layer

**Где:** `data/repositories/` (общие) + `features/*/repositories/` (специализированные).
**Задача:** скрыть детали хранения от бизнес-логики.
**Можно:** CRUD, объединение источников, преобразование между слоями.
**Нельзя:** финансовые решения, расчёт балансов, изменение состояний.

Общие репозитории: `account`, `card_color_settings`, `operation`, `receipt`.
Специализированные:

- Система знаний: `embedding`, `markdown`, `memory`
- **Пользовательские поля (новое):** `custom_field` — управление определениями и значениями

### 5. Data Layer

**Структура:**

- `data/database/` — `database_helper.dart` (основная БД), `memory_database.dart` (система знаний)
- `data/services/` — `openrouter_service`, `photo_storage_service`, `receipt_creation_service`, `background_manager/`
- `lib/models/` — DTO: `account`, `operation`, `receipt`, `receipt_item`, `parsed_receipt`, `receipt_result`, `card_color_settings`, `category`, `operation_type`, `custom_field_definition`, `custom_field_value`

**Модели vs Entities:**
Модели (`lib/models/`) — транспорт данных (DTO). Entities (`domain/entities/`) — бизнес-результат.
Модели не содержат бизнес-логики, только структуру и сериализацию.

**Background Manager:**

- `BackgroundTask` — описание задачи с прогрессом.
- `BackgroundTaskManager` — планировщик.
- `TaskMonitorFloating` — плавающий виджет мониторинга.

**Система знаний (Memory):**

- `features/memory/services/` – `embedding_service.dart` (получение векторов через OpenRouter), `indexing_service.dart` (управление индексацией), `sqlite_vector_search_service.dart` (поиск по косинусному сходству), `vector_search_service.dart` (абстракция)
- `features/memory/repositories/` – `embedding_repository.dart` (CRUD для эмбеддингов), `memory_note_repository.dart` (CRUD для заметок)
- `core/preferences/app_settings.dart` – настройки автоиндексации, модели эмбеддингов

**Пользовательские поля (новое):**

- `features/custom_fields/` — модуль управления пользовательскими полями
- `CustomFieldService` — логика работы с полями (валидация, преобразование)
- `CustomFieldRepository` — доступ к определениям и значениям

### 6. External Services Layer

- `OpenRouterService` — AI API
- `AiKeyManager` — ключи и лимиты
- `PhotoStorageService`, `PhotoCleanupService` — работа с файлами
- Сервисы системы знаний: `ChunkingService`, `EmbeddingService`, `IndexingService`, `MarkdownChunkParser`, `SemanticSearchService`, `VectorSimilarityService`

❌ Сервисы не принимают бизнес-решений и не меняют финансовые состояния.

---

## Конфиденциальность и безопасность

### Приватность данных

**Локальное хранение:**

- Все финансовые данные хранятся в локальной SQLite-базе на устройстве пользователя
- Фотографии чеков хранятся в локальной файловой системе
- Логи хранятся локально (файл `logs.txt`)
- Настройки хранятся локально (SQLite или SharedPreferences)

**Внешние вызовы (AI):**

- OpenRouter API используется для распознавания чеков и создания эмбеддингов
- Данные не сохраняются на стороне провайдера дольше, чем необходимо для обработки запроса
- API-ключи хранятся в зашифрованном виде

**Будущие интеграции (требуют отдельного согласия):**

- Синхронизация с облаком (Google Drive, iCloud) — только с явного согласия
- Интеграция с внешними сервисами (Telegram, Email, Google Drive) — только с явного согласия
- Экспорт данных — только по запросу пользователя

**Аудит:**

- Все внешние вызовы логируются с указанием того, какие данные отправляются
- Пользователь имеет доступ к логам (через экран Debug Logs)

---

## Модель распространения

### Бесплатная версия (полностью функциональна)

- Основной учёт (операции, счета, чеки)
- Базовое распознавание чеков (ограниченное количество)
- Базовые настройки
- Локальное хранение всех данных
- Базовый поиск по заметкам (семантический, с ограничениями)
- Система знаний (Obsidian + внутренние заметки) — базовый функционал
- **Бюджетные периоды (план/факт)**
- **Долги и планы покупок**
- **Пользовательские поля (до 5 полей на сущность)**

### Платная версия (дополнительный комфорт)

- Расширенное AI-распознавание (больше запросов, лучшие модели)
- Расширенная аналитика (графики, отчёты, прогнозы, Data Quality Score)
- Интеграции (Google Drive, Telegram, Email, PDF, голосовые заметки)
- Синхронизация между устройствами
- Расширенная система знаний (глубокий анализ, связи, инсайты)
- **Безлимитные пользовательские поля**
- Приоритетная поддержка

**Принцип:** Платная версия не создаёт ощущение, что бесплатная сломана или неполноценна. Бесплатная версия — это полноценный продукт, платная — премиум-класс.

---

## Структура Flutter проекта

Актуальное дерево: (при его изменении обязательно обновить)

```
lib/
├── main.dart
├── secrets.dart
├── core/
│   ├── debug/                 DebugLogger, LogEntry
│   ├── preferences/           AppSettings, ColorSettingsNotifier
│   ├── theme/                 AppColors, AppDimensions, AppIcons, AppTextStyles, AppTheme, ThemeNotifier
│   ├── utils/                 AccountNameUtils, CustomPageScrollPhysics, DateUtils
│   └── widgets/               Базовые виджеты
├── data/
│   ├── database/              database_helper.dart, memory_database.dart
│   ├── repositories/          Account, Operation, Receipt, CardColorSettings
│   └── services/              CategoryService, DataNormalizerService, OpenRouter, PhotoCleanup, PhotoStorage, ReceiptCreation
│       └── background_manager/ BackgroundTask, BackgroundTaskManager, widgets/TaskMonitorFloating
├── domain/
│   ├── entities/              FinancialState
│   └── usecases/              FinancialCalculator, FinancialService
├── features/
│   ├── accounts/              AccountsScreen, AccountDetailsScreen, widgets/ (AccountCard, CreateAccountDialog, SelectAccountDialog)
│   ├── ai/                    AiKeyManager, AiLimitException, AiProfile, AiProfiles
│   ├── custom_fields/         НОВЫЙ МОДУЛЬ — модели, репозитории, сервисы, экраны, виджеты
│   ├── debug/                 DebugLogScreen, widgets/ (LogFilterChips, LogTile)
│   ├── home/                  HomeScreen, widgets/ (AccountsCarousel, HomeAppBar, HomeOverview, OperationHistoryList, ReceiptFloatingButton)
│   ├── memory/                Модели, репозитории, сервисы, экраны, виджеты, утилиты
│   │   ├── diagnostics/       Диагностика памяти (проверки, калькуляторы, генераторы, виджеты)
│   │   ├── models/            EmbeddingModel, MemoryChunk, MemoryNote, MemorySearchResult, MemorySource, ObsidianNote
│   │   ├── providers/         Провайдеры состояния
│   │   ├── repositories/      Embedding, Markdown, MemoryNote, Memory
│   │   ├── screens/           MemoryScreen
│   │   ├── services/          Chunking, Embedding, Indexing, MarkdownChunkParser, ObsidianReader, SemanticSearch, SqliteVectorSearch, VectorSearch, VectorSimilarity
│   │   ├── utils/             EmbeddingUtils, MarkdownUtils, VectorUtils
│   │   └── widgets/           IndexingProgress, SearchBar, SearchResultTile
│   ├── navigation/            MainNavigation
│   ├── operations/            AddOperationScreen, OperationsScreen, OperationDetailsScreen, widgets/ (OperationTile, UndoDeletePanel)
│   ├── receipts/              EditReceiptItemScreen, EditReceiptScreen, ReceiptsScreen, ReceiptDetailsScreen
│   ├── settings/              CardColorsSettingsScreen, SettingsScreen
│   └── widgets/               Общие виджеты фич
└── models/                    DTO: Account, CardColorSettings, Category, Operation, OperationType, ParsedReceipt, Receipt, ReceiptItem, ReceiptResult, CustomFieldDefinition, CustomFieldValue
```

---

### Описание директорий

- **core/** — базовые переиспользуемые компоненты: отладка, настройки, тема, утилиты, атомарные виджеты.
- **data/** — технический слой: БД, репозитории, сервисы (категории, нормализация данных, AI-клиент, фото, чеки, фон).
- **domain/** — чистая бизнес-логика. Сущности и use cases.
- **features/** — самодостаточные модули: accounts, ai, **custom_fields (новое)**, debug, home, memory, navigation, operations, receipts, settings, widgets.
- **models/** — общие DTO без бизнес-логики.

---

## Основные архитектурные потоки

### Чтение/запись данных

```
UI → Application Logic → Repository → DatabaseHelper → SQLite
```

### AI (распознавание чеков)

```
Image → OpenRouterService → ParsedReceipt → Receipt + ReceiptItem → Repository → SQLite → Operation → FinancialService/Calculator → FinancialState
```

### Система знаний (индексация и поиск)

```
Источник (Obsidian/заметки) → Чтение → Чанкинг → Эмбеддинги → Хранение → Индексация → Поиск → Результаты
```

### Пользовательские поля (новое)

```
UI → CustomFieldService → CustomFieldRepository → SQLite (custom_field_definitions, custom_field_values)
```

**Отображение полей в формах:**

```
EntityForm → CustomFieldService.getDefinitions(entityType) → рендер полей → сохранение значений
```

**Фильтрация по полям:**

```
EntityList → CustomFieldService.buildFilterQuery(field, value) → Repository → SQLite
```

Управляется через сервисы, отображается в UI с прогрессом через BackgroundManager.

---

## Управление состоянием

Технология финализируется (вероятно, Riverpod). Сейчас — провайдеры внутри фич.
Поток: `User Action → Controller/Service → Repository → Data Source → State Update → UI Refresh`

---

## Архитектурные паттерны

- **Repository Pattern** — общие (`data/repositories/`) + специализированные (`features/*/repositories/`)
- **Service Pattern** — изоляция внешних возможностей
- **Feature-based модульность** — изоляция фич, полный стек в каждой при необходимости

---

## Архитектурные решения

**Решение 1 — Переход к модульной структуре features/**
Вместо единого `screens/` — изолированные модули.
Причина: навигация по коду, снижение связанности, параллельная разработка.
Риск: дублирование кода → общие `core/` и `features/widgets/`.

**Решение 2 — Абстракция VectorSearchService**
Вместо жёсткой привязки к одному движку введён интерфейс `VectorSearchService`. Первичная реализация – `SqliteVectorSearchService` с хранением векторов в BLOB и вычислением косинусного сходства в памяти. Это позволяет в будущем заменить движок на `sqlite-vec` или другой без изменения остального кода.

**Решение 3 — Хранение векторов в BLOB**
Векторы хранятся в виде `Float32Array → Uint8List → BLOB`. Это экономит место и ускоряет загрузку по сравнению с JSON-строкой.

**Решение 4 — Хранение логов в текстовом файле**
Логи хранятся в `logs.txt` в директории документов приложения. Формат человекочитаемый, лимит 2000 записей.

**Решение 5 — Источник Obsidian как часть системы знаний**
Obsidian Vault интегрирован как источник данных для векторного поиска. В будущем планируется переход к универсальной системе знаний с абстракцией `KnowledgeSource`.

**Решение 6 — Приватность по умолчанию**
Все данные локальные. Внешние вызовы только с согласия пользователя и только для конкретных функций.

**Решение 7 — Бесплатная работающая версия**
Приложение полностью функционально без покупок. Платные функции — расширения, а не необходимая часть.

**Решение 8 — Пользовательские поля как метаданные (НОВОЕ)**
Пользовательские поля не являются частью финансовой модели. Они хранятся в отдельных таблицах и привязываются к сущностям через полиморфную связь. Это позволяет:

- Не менять основную схему БД при добавлении новых полей
- Гибко настраивать UI под нужды пользователя
- Сохранять финансовую логику чистой

---

## Система знаний (Memory) — архитектурная концепция

Memory — это универсальная система знаний, работающая с любыми источниками информации.

**Архитектурный принцип:**

- Абстракция источника: `KnowledgeSource` — интерфейс для подключения новых источников (Obsidian, внутренние заметки, PDF, Telegram, Google Drive, Email, голосовые заметки, изображения и др.)
- Единый индекс: все источники индексируются в общую систему эмбеддингов
- Универсальный поиск: семантический поиск работает по всем источникам одновременно

**Текущая реализация:**

- Начальная реализация: Obsidian + внутренние заметки (через MemoryNote)
- **Инкрементальная индексация** — проверка `sourceUpdatedAt` перед переиндексацией
- **Пакетная обработка** — пачки по 30 файлов, пауза 100 мс, параллельность 5
- **Прогресс в UI** — колбэк `onProgress` в `indexObsidian()`
- **Очистка битых эмбеддингов** — кнопка в MemoryScreen с проверкой таблицы
- **Фильтрация служебных папок** — `.trash`, `.obsidian`, `.git`, `.stversions`
- **Копирование диагностики** — кнопка в диалоге для копирования отчёта
- В будущем: расширение через `KnowledgeSource` без изменения ядра

**Исправление битых BLOB:**

- `vectorToBlob()` и `blobToVector()` создают копии данных через `Uint8List.fromList()`
- Это гарантирует правильное выравнивание в памяти (смещение кратно 4)
- Устранены ошибки `RangeError: Offset must be a multiple of BYTES_PER_ELEMENT (4)`

---

## Технический долг

- [ ] Не завершён Domain Layer — отсутствуют Engine-компоненты (Receipt, Operation, State, History, Analytics). Логика временно в сервисах.
- [ ] Не финализирован State Management — смесь подходов, нужна унификация.
- [ ] Репозитории внутри `features/memory/` — допустимы, но требуют мониторинга.
- [ ] `screens/settings_screen.dart` — перенести в `features/settings/`.
- [ ] Memory требует перехода к универсальной системе знаний (абстракция `KnowledgeSource`).
- [ ] Отсутствует Receipt Draft — требуется для объединения нескольких фото в один чек.
- [ ] Требуется аудит внешних вызовов для гарантии конфиденциальности.
- [ ] **Модуль custom_fields требует реализации (планируется в Phase 11).**
