**Version:** 13.0
**Last Updated:** 2026-07-31

---

## Назначение

Источник истины по структуре хранения данных LifeOS. Как данные хранятся.

---

## Область ответственности

### Описывает
- БД, таблицы, поля, связи, индексы, миграции
- Правила хранения и методы базы

### НЕ описывает
- Финансовую логику, расчёт балансов, бюджет, бизнес-правила, AI, пользовательские сценарии

**Связанные документы:**
- Бизнес-сущности → [[03_Domain_Model]]
- Финансовая логика → [[04_Financial_Rules]]
- Архитектура → [[02_Architecture]]

---

## Database Information

- **Database:** SQLite
- **Current Version:** 1 (database_helper.dart)
- **Packages:** sqflite, sqflite_common_ffi (desktop/testing)
- **Использование:** Android/iOS → sqflite, Desktop/test → sqflite_common_ffi

---

## Безопасность данных

### Локальное хранение
- Все данные хранятся в локальной SQLite-базе
- Файл базы данных находится в директории приложения, доступ к которой имеют только приложение и пользователь
- Рекомендуется: шифрование БД (SQLCipher) в будущем для защиты чувствительных данных

### Чувствительные данные
- Фотографии чеков — хранятся в файловой системе, доступны только приложению
- API-ключи — хранятся в secrets.dart (не в БД), не синхронизируются
- Логи — хранятся в logs.txt, содержат техническую информацию, но не чувствительные данные

### Очистка данных
- Фотографии чеков удаляются автоматически по истечении срока хранения (настраивается в UI)
- Логи ограничены 2000 записей (старые удаляются)
- При удалении счёта — операции остаются или удаляются? ❓ Требуется решение

---

## Database Structure

Локальное хранилище SQLite. Таблицы на 2026-07-30:

| Таблица | Назначение | Статус |
|---------|------------|--------|
| accounts | Счета пользователя | ✅ Реализовано |
| operations | Финансовые операции | ✅ Реализовано |
| receipts | Чеки | ✅ Реализовано |
| receipt_items | Товары в чеках | ✅ Реализовано |
| card_color_settings | Настройки цветов карточек | ✅ Реализовано |
| embeddings | Векторные представления для поиска | ✅ Реализовано |
| memory_notes | Заметки для индексации | ✅ Реализовано |
| settings | Пользовательские настройки | ❌ Не реализовано |
| receipt_drafts | Черновики чеков | ❌ Не реализовано |

---

## Связи

receipts.id → receipt_items.receiptId (One-to-Many)
receipts.id → operations.receiptId (One-to-One, текущая)
accounts.id → operations.accountId (One-to-Many)

---

## Database Rules

### General
SQLite: хранение, получение, связи, целостность.
SQLite не делает: финансовые расчёты, изменение баланса, бизнес-решения.

### Foreign Keys
PRAGMA foreign_keys = ON. Каскадное удаление: receipt_items.receiptId → receipts.id.

### Transactions
Связанные операции — атомарно.
BEGIN → INSERT receipts → INSERT receipt_items → INSERT operations → COMMIT
При ошибке → ROLLBACK

### Data Flow
Model → Repository → SQLite → Repository → UI

### Data Integrity

- **Проверка существования таблицы:** перед выполнением операций с `embeddings` проверяется наличие таблицы через `sqlite_master`
- **Автоматическая очистка битых записей:** при инициализации `SqliteVectorSearchService` выполняется очистка записей с `LENGTH(vector) % 4 != 0`
- **Асинхронная очистка во время поиска:** при обнаружении битого вектора во время поиска он удаляется асинхронно, не блокируя операцию
- **Очистка через UI:** кнопка в MemoryScreen для ручной очистки с подтверждением
- **Корректное выравнивание:** BLOB векторов сохраняются через `Uint8List.fromList()` для гарантии правильного выравнивания
- **Валидация текста:** пустые тексты и тексты короче 3 символов не отправляются в API и не сохраняются

---

## Tables

### accounts
Счета пользователя.

| Поле | Тип | Описание |
|------|-----|----------|
| id | TEXT PK | UUID |
| name | TEXT NOT NULL | Название |
| balance | REAL NOT NULL DEFAULT 0 | Текущий баланс |
| initialBalance | REAL NOT NULL DEFAULT 0 | Начальный баланс |
| isMain | INTEGER NOT NULL DEFAULT 0 | 1 = основной |
| type | TEXT NOT NULL DEFAULT 'other' | card, cash, credit, other, custom1-5 |
| position | INTEGER DEFAULT 0 | Порядок сортировки |

Связи: accounts.id → operations.accountId (One-to-Many)

### operations
Финансовые операции. Источник изменения финансового состояния.

| Поле | Тип | Описание |
|------|-----|----------|
| id | TEXT PK | UUID |
| accountId | TEXT | FK → accounts.id |
| type | TEXT NOT NULL | income / expense |
| amount | REAL NOT NULL | Сумма |
| comment | TEXT | Комментарий |
| date | TEXT NOT NULL | ISO 8601 |
| shop | TEXT | Магазин / контрагент |
| article | TEXT | Статья расхода/дохода |
| categoryId | TEXT | Категория |
| paymentType | TEXT | Способ оплаты |
| receiptId | TEXT | FK → receipts.id |
| regularity | TEXT | Регулярность |
| workDay | INTEGER | Рабочий день (0/1) |
| plannedAmount | REAL | Плановая сумма |
| processed | INTEGER DEFAULT 0 | Флаг обработки |

Связи:
- operations.receiptId → receipts.id (Many-to-One)
- operations.accountId → accounts.id (Many-to-One)

### receipts
Чеки.

| Поле | Тип | Описание |
|------|-----|----------|
| id | TEXT PK | UUID |
| date | TEXT NOT NULL | Дата покупки (ISO 8601) |
| time | TEXT | Время покупки |
| shop | TEXT NOT NULL | Название магазина |
| address | TEXT | Адрес |
| paymentType | TEXT | Способ оплаты |
| amount | REAL NOT NULL | Общая сумма |
| photoPath | TEXT | Путь к фото |
| status | TEXT NOT NULL | "new", "processed" |
| comment | TEXT | Комментарий |

Связи:
- receipts.id → receipt_items.receiptId (One-to-Many)
- receipts.id → operations.receiptId (One-to-One, текущая)

Удаление: транзакционное. receipt_items удаляются каскадно.

### receipt_items
Товары внутри чека.

| Поле | Тип | Описание |
|------|-----|----------|
| id | TEXT PK | UUID |
| receiptId | TEXT NOT NULL | FK → receipts.id |
| name | TEXT NOT NULL | Название товара |
| quantity | REAL NOT NULL | Количество |
| unit | TEXT | Единица измерения |
| price | REAL NOT NULL | Цена за единицу |
| total | REAL NOT NULL | Итог (quantity × price) |
| priceBeforeDiscount | REAL | Цена до скидки |
| comment | TEXT | Комментарий |
| category | TEXT | Категория товара |

Связи: receipt_items.receiptId → receipts.id (Many-to-One, CASCADE).

При обновлении товара: UPDATE receipt_items → пересчёт суммы чека → обновление receipts.amount и operations.amount.

### card_color_settings
Настройки цветов карточек (светлая/тёмная тема, 8 типов счетов + 5 custom).

| Поле | Тип | Описание |
|------|-----|----------|
| id | TEXT PK | 'default' |
| cardLightStart/End | INTEGER | Карты, светлая |
| cashLightStart/End | INTEGER | Наличные, светлая |
| creditLightStart/End | INTEGER | Кредитные, светлая |
| otherLightStart/End | INTEGER | Прочие, светлая |
| cardDarkStart/End | INTEGER | Карты, тёмная |
| cashDarkStart/End | INTEGER | Наличные, тёмная |
| creditDarkStart/End | INTEGER | Кредитные, тёмная |
| otherDarkStart/End | INTEGER | Прочие, тёмная |
| custom1Name | TEXT DEFAULT '' | Имя custom1 |
| custom1LightStart/End | INTEGER | custom1, светлая |
| ... (custom1-5) | | |

Одна запись с id='default'. Сохранение через CardColorSettingsRepository.

### embeddings

Хранит векторные представления (эмбеддинги) для различных источников (чеки, заметки и др.).

| Поле | Тип | Описание |
|------|-----|----------|
| id | TEXT | PRIMARY KEY |
| sourceType | TEXT | Тип источника (receipt, memory_note, obsidian_note, ...) |
| sourceId | TEXT | Стабильный идентификатор источника (для Obsidian — хеш пути) |
| content | TEXT | Текст, по которому строится эмбеддинг (чанк для больших документов) |
| vector | BLOB | Вектор в формате Float32Array → Uint8List |
| model | TEXT | Модель эмбеддинга |
| embeddingVersion | INTEGER | Версия для миграции при смене модели |
| createdAt | TEXT | ISO 8601 |
| updatedAt | TEXT | ISO 8601 |
| sourceUpdatedAt | TEXT | Время последнего обновления источника |
| embeddingUpdatedAt | TEXT | Время последнего обновления эмбеддинга |
| metadata | TEXT | JSON с метаданными |

**Поля metadata (для Obsidian):**

| Поле | Тип | Описание |
|------|-----|----------|
| path | string | Физический путь к файлу (для обратной совместимости) |
| title | string | Заголовок документа |
| migrationId | string | Временный идентификатор миграции (служебное, удаляется после миграции) |
| chunkIndex | int | Порядковый номер чанка (для чанкированных документов) |
| totalChunks | int | Общее количество чанков (для чанкированных документов) |
| parentTitle | string | Заголовок родительского документа (для чанков) |

**Индексы:**
- idx_embeddings_source ON (sourceType, sourceId)
- idx_embeddings_updated ON (updatedAt)
### memory_notes
Хранит пользовательские заметки для индексации и поиска.

| Поле | Тип | Описание |
|------|-----|----------|
| id | TEXT | PRIMARY KEY |
| title | TEXT | Заголовок заметки |
| content | TEXT | Текст заметки |
| category | TEXT | Категория (опционально) |
| createdAt | TEXT | ISO 8601 |
| updatedAt | TEXT | ISO 8601 |

**Индексы:**
- idx_memory_notes_category ON (category)

### settings (планируется)
Хранит пользовательские настройки.

| Поле | Тип | Описание |
|------|-----|----------|
| key | TEXT PK | Ключ настройки |
| value | TEXT | Значение (JSON или строка) |
| updatedAt | TEXT | ISO 8601 |

**Примеры настроек:**
- photo_retention_days → "7" (срок хранения фото)
- swipe_to_delete → "true" (удаление свайпом вкл/выкл)
- default_operation_mode → "all_accounts" (режим истории по умолчанию)
- ai_model → "openai/gpt-4o-mini" (выбранная AI-модель)
- auto_indexing → "true" (автоиндексация вкл/выкл)
- semantic_search_limit → "10" (количество результатов поиска)

### receipt_drafts (планируется)
Черновики чеков для объединения нескольких фото.

| Поле | Тип | Описание |
|------|-----|----------|
| id | TEXT PK | UUID |
| createdAt | TEXT | ISO 8601 |
| updatedAt | TEXT | ISO 8601 |
| status | TEXT | draft, processing, completed, failed |
| photoPaths | TEXT | JSON-массив путей к фото (порядок важен) |
| parsedData | TEXT | JSON с результатами AI (если есть) |
| receiptId | TEXT | FK → receipts.id (после завершения) |
| error | TEXT | Сообщение об ошибке (если failed) |

**Индексы:**
- idx_receipt_drafts_status ON (status)
- idx_receipt_drafts_created ON (createdAt)

### products
Хранит базовую информацию о продуктах питания. Создаётся вручную или при импорте из ReceiptItem.

| Поле | Тип | Описание |
|------|-----|----------|
| id | TEXT PK | UUID |
| name | TEXT NOT NULL | Название продукта |
| category | TEXT | Категория (овощи, мясо, бакалея и т.д.) |
| calories | REAL | Калорийность на единицу (ккал) |
| proteins | REAL | Белки (г) |
| fats | REAL | Жиры (г) |
| carbohydrates | REAL | Углеводы (г) |
| unit | TEXT NOT NULL | Единица измерения (шт, г, мл, порция) |
| sourceType | TEXT | Источник создания (manual, receipt) |
| sourceId | TEXT | ID чека, если создан из ReceiptItem |
| createdAt | TEXT | ISO 8601 |
| updatedAt | TEXT | ISO 8601 |

**Индексы:**
- idx_products_name ON (name)
- idx_products_category ON (category)
- idx_products_source ON (sourceType, sourceId)

**Пояснение по полям:**

- `sourceType` и `sourceId` позволяют в будущем автоматически создавать продукты из чеков и отслеживать их происхождение.
- `unit` — единица измерения. Важно, чтобы она совпадала с единицей в `InventoryItem`.

### inventory_items
Хранит текущие остатки продуктов. Количество пересчитывается на основе FoodEntry.

| Поле | Тип | Описание |
|------|-----|----------|
| id | TEXT PK | UUID |
| productId | TEXT NOT NULL UNIQUE | FK → products.id |
| quantity | REAL NOT NULL | Текущий остаток в единицах продукта |
| unit | TEXT NOT NULL | Единица измерения (совпадает с product.unit) |
| updatedAt | TEXT NOT NULL | Время последнего обновления остатка |

**Связи:**
- inventory_items.productId → products.id (One-to-One, CASCADE).

**Важно:** `productId` имеет `UNIQUE`, потому что у одного продукта может быть только один текущий остаток.
### meals
Группирует продукты в приёмы пищи.

| Поле | Тип | Описание |
|------|-----|----------|
| id | TEXT PK | UUID |
| name | TEXT NOT NULL | Название приёма (Завтрак, Обед, Ужин, Перекус) |
| date | TEXT NOT NULL | ISO 8601 |
| time | TEXT | Время приёма (ISO 8601) |
| totalCalories | REAL | Сумма калорий всех продуктов (вычисляется) |
| totalCost | REAL | Стоимость всех продуктов (вычисляется) |
| comment | TEXT | Комментарий |
| createdAt | TEXT | ISO 8601 |
| updatedAt | TEXT | ISO 8601 |

**Индексы:**
- idx_meals_date ON (date)

**Пояснение:** `totalCalories` и `totalCost` вычисляются на основе связанных `FoodEntry`, а не хранятся статически. Это соответствует принципу «не хранить вычисляемые значения».


### food_entries
Запись о части продукта, использованной в приёме пищи или отдельно. Является источником истины для *обоих* состояний: что было съедено и что осталось/выброшено.

| Поле | Тип | Описание |
|------|-----|----------|
| id | TEXT PK | UUID |
| productId | TEXT NOT NULL | FK → products.id |
| mealId | TEXT | FK → meals.id (если в составе приёма, иначе NULL) |
| quantity | REAL NOT NULL | Общее количество продукта, задействованное в событии |
| unit | TEXT NOT NULL | Единица измерения |
| **consumptionState** | **TEXT NOT NULL** | **"eaten", "remaining", "wasted"** |
| pricePerUnit | REAL | Цена за единицу (из чека) |
| totalPrice | REAL | Итоговая стоимость (quantity * pricePerUnit) |
| calories | REAL | Калорийность (quantity * product.calories) |
| timestamp | TEXT NOT NULL | ISO 8601 |
| sourceType | TEXT | Источник (manual, receipt) |
| sourceId | TEXT | ID чека, если импортирован |
| comment | TEXT | Комментарий |

**Связи:**
- food_entries.productId → products.id (Many-to-One)
- food_entries.mealId → meals.id (Many-to-One)

**Индексы:**
- idx_food_entries_product ON (productId)
- idx_food_entries_meal ON (mealId)
- idx_food_entries_state ON (consumptionState)
- idx_food_entries_timestamp ON (timestamp)

**Ключевое поле:** `consumptionState`. Оно определяет, куда идёт эта часть продукта:
- `eaten` → в журнал питания
- `remaining` → в инвентарь
- `wasted` → в статистику потерь

### Примечание по логике инвентаря:
Текущий остаток продукта (inventory_items.quantity) вычисляется как сумма всех `food_entries.quantity`, где `consumptionState = 'remaining'`. Это делает `food_entries` источником истины и гарантирует, что журнал питания и инвентарь всегда согласованы. `InventoryItem` служит кэшем для быстрого доступа к текущему остатку.

---

## Database Methods (DatabaseHelper)

| Метод | Назначение |
|-------|------------|
| insertAccount() | Добавление счёта |
| updateAccount() | Обновление счёта |
| deleteAccount() | Удаление (запрещено для основного) |
| getAccounts() | Все счета |
| insertOperation() | Добавление операции |
| getOperations() | Все операции |
| getOperationsByAccount() | По счёту |
| deleteOperation() | Удаление |
| updateOperationByReceiptId() | Обновление по чеку |
| insertReceipt() | Добавление чека |
| updateReceipt() | Обновление чека |
| deleteReceipt() | Удаление (транзакционно) |
| getReceipts() | Все чеки |
| getReceiptById() | По ID |
| insertReceiptItem() | Добавление товара |
| updateReceiptItem() | Обновление товара |
| getReceiptItems() | Товары чека |
| recalculateReceiptAmount() | Пересчёт суммы чека |
| updateOperationAmount() | Обновление суммы операции |
| insertReceiptWithItems() | Транзакционное сохранение |

Методы изменения данных используют транзакции (deleteReceipt, insertReceiptWithItems).

---

## ID Rules

Все PK — TEXT (UUID). Поддержка UUID, импорт, гибкость.
Примеры: REC-..., ITEM-..., OP-...

---

## Indexes

Пока не определены. Планируются для: дата операций, категории, магазины, receiptId.

---

## Migrations

**Версия БД:** 1. Создаётся через onCreate, миграции не применялись.
При изменениях схемы — скрипты обновления.

---

## Current Database State

### Реализовано
- SQLite подключена
- Таблицы: accounts, operations, receipts, receipt_items, card_color_settings, embeddings, memory_notes
- Связи: чек→товары (1:M), чек→операция (1:1), счёт→операции (1:M)
- Транзакционное сохранение
- Обновление товаров + перерасчёт чека
- Система основного счёта
- Настройки цветов
- Хранение эмбеддингов (BLOB)
- Хранение заметок для индексации

### Не реализовано
- Удаление отдельных товаров через UI
- Управление категориями (отдельная таблица)
- Таблица settings (пользовательские настройки)
- Таблица receipt_drafts (черновики чеков)
- Отдельная БД для векторов (memory_database.dart пуст)
- Шифрование БД (SQLCipher)

---

## Future Structure

Receipt → ReceiptItem → Operation → Account → FinancialState → StateHistory → Analytics

**Главный принцип:** SQLite хранит факты. SQLite не принимает финансовые решения.

---