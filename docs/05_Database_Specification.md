## 05_Database_Specification.md

---

**Version:** 13.1
**Last Updated:** 2026-08-02

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
- **Current Version:** 3
- **Packages:** `sqflite`, `sqflite_common_ffi` (desktop/testing)
- **Использование:** Android/iOS → sqflite, Desktop/test → sqflite_common_ffi

---

## Безопасность данных

### Локальное хранение

- Все данные хранятся в локальной SQLite-базе
- Файл базы данных находится в директории приложения, доступ к которой имеют только приложение и пользователь
- Рекомендуется: шифрование БД (SQLCipher) в будущем для защиты чувствительных данных

### Чувствительные данные

- Фотографии чеков — хранятся в файловой системе, доступны только приложению
- API-ключи — хранятся в `secrets.dart` (не в БД), не синхронизируются
- Логи — хранятся в `logs.txt`, содержат техническую информацию, но не чувствительные данные

### Очистка данных

- Фотографии чеков удаляются автоматически по истечении срока хранения (настраивается в UI)
- Логи ограничены 2000 записей (старые удаляются)
- При удалении счёта — операции остаются или удаляются? ❓ Требуется решение

---

## Database Structure

Локальное хранилище SQLite. Таблицы на 2026-08-02:

| Таблица | Назначение | Статус |
| --------- | ------------ | -------- |
| `accounts` | Счета пользователя | ✅ Реализовано |
| `operations` | Финансовые операции | ✅ Реализовано |
| `receipts` | Чеки | ✅ Реализовано |
| `receipt_items` | Товары в чеках | ✅ Реализовано |
| `card_color_settings` | Настройки цветов карточек | ✅ Реализовано |
| `embeddings` | Векторные представления для поиска | ✅ Реализовано |
| `memory_notes` | Заметки для индексации | ✅ Реализовано |
| `categories` | Категории товаров | 📅 Планируется |
| `budget_periods` | Бюджетные периоды | 📅 Планируется |
| `budget_items` | План по категориям | 📅 Планируется |
| `debts` | Долги | 📅 Планируется |
| `debt_payments` | История погашений | 📅 Планируется |
| `recurring_payments` | Регулярные платежи | 📅 Планируется |
| `purchase_plans` | Планы покупок | 📅 Планируется |
| `custom_field_definitions` | Определения пользовательских полей | 📅 Планируется |
| `custom_field_values` | Значения пользовательских полей | 📅 Планируется |
| `settings` | Пользовательские настройки | ❌ Не реализовано |
| `receipt_drafts` | Черновики чеков | ❌ Не реализовано |

---

## Связи (текущие)

```
receipts.id → receipt_items.receiptId (One-to-Many)
receipts.id → operations.receiptId (One-to-One)
accounts.id → operations.accountId (One-to-Many)
```

---

## Database Rules

### General

- SQLite: хранение, получение, связи, целостность.
- ❌ SQLite не делает: финансовые расчёты, изменение баланса, бизнес-решения.

### Foreign Keys

- `PRAGMA foreign_keys = ON`
- Каскадное удаление: `receipt_items.receiptId → receipts.id`

### Transactions

- Связанные операции — атомарно.
- `BEGIN → INSERT receipts → INSERT receipt_items → INSERT operations → COMMIT`
- При ошибке → `ROLLBACK`

### Data Flow

```
Model → Repository → SQLite → Repository → UI
```

### Data Integrity

- **Проверка существования таблицы:** перед выполнением операций с `embeddings` проверяется наличие таблицы через `sqlite_master`
- **Автоматическая очистка битых записей:** при инициализации `SqliteVectorSearchService` выполняется очистка записей с `LENGTH(vector) % 4 != 0`
- **Асинхронная очистка во время поиска:** при обнаружении битого вектора во время поиска он удаляется асинхронно, не блокируя операцию
- **Очистка через UI:** кнопка в MemoryScreen для ручной очистки с подтверждением
- **Корректное выравнивание:** BLOB векторов сохраняются через `Uint8List.fromList()` для гарантии правильного выравнивания
- **Валидация текста:** пустые тексты и тексты короче 3 символов не отправляются в API и не сохраняются

---

## Таблицы (существующие)

### accounts

| Поле | Тип | Описание |
| ------ | ----- | ---------- |
| id | TEXT PK | UUID |
| name | TEXT NOT NULL | Название |
| balance | REAL NOT NULL DEFAULT 0 | Текущий баланс |
| initialBalance | REAL NOT NULL DEFAULT 0 | Начальный баланс |
| isMain | INTEGER NOT NULL DEFAULT 0 | 1 = основной |
| type | TEXT NOT NULL DEFAULT 'other' | card, cash, credit, other, custom1-5 |
| position | INTEGER DEFAULT 0 | Порядок сортировки |

**Связи:** `accounts.id → operations.accountId` (One-to-Many)

---

### operations

| Поле | Тип | Описание |
| ------ | ----- | ---------- |
| id | TEXT PK | UUID |
| accountId | TEXT | FK → accounts.id |
| type | TEXT NOT NULL | income / expense / transfer / debt_repayment |
| amount | REAL NOT NULL | Сумма |
| comment | TEXT | Комментарий |
| date | TEXT NOT NULL | ISO 8601 |
| shop | TEXT | Магазин / контрагент |
| article | TEXT | Статья расхода/дохода |
| categoryId | TEXT | Категория (кэш) |
| paymentType | TEXT | Способ оплаты |
| receiptId | TEXT | FK → receipts.id |
| debtId | TEXT | FK → debts.id (для погашений) |
| regularity | TEXT | Регулярность |
| workDay | INTEGER | Рабочий день (0/1) |
| plannedAmount | REAL | Плановая сумма |
| processed | INTEGER DEFAULT 0 | Флаг обработки |

**Связи:**

- `operations.receiptId → receipts.id` (Many-to-One)
- `operations.accountId → accounts.id` (Many-to-One)
- `operations.debtId → debts.id` (Many-to-One)

---

### receipts

| Поле | Тип | Описание |
| ------ | ----- | ---------- |
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

**Связи:**

- `receipts.id → receipt_items.receiptId` (One-to-Many)
- `receipts.id → operations.receiptId` (One-to-One)

**Удаление:** транзакционное. `receipt_items` удаляются каскадно.

---

### receipt_items

| Поле | Тип | Описание |
| ------ | ----- | ---------- |
| id | TEXT PK | UUID |
| receiptId | TEXT NOT NULL | FK → receipts.id |
| name | TEXT NOT NULL | Название товара |
| quantity | REAL NOT NULL | Количество |
| unit | TEXT | Единица измерения |
| price | REAL NOT NULL | Цена за единицу |
| total | REAL NOT NULL | Итог (quantity × price) |
| priceBeforeDiscount | REAL | Цена до скидки |
| comment | TEXT | Комментарий |
| category | TEXT | Категория товара (текст, будет заменено на categoryId) |

**Связи:** `receipt_items.receiptId → receipts.id` (Many-to-One, CASCADE).

**При обновлении товара:**

1. `UPDATE receipt_items`
2. Пересчёт суммы чека
3. Обновление `receipts.amount` и `operations.amount`

---

### card_color_settings

| Поле | Тип | Описание |
| ------ | ----- | ---------- |
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

Одна запись с `id='default'`. Сохранение через `CardColorSettingsRepository`.

---

### embeddings

Хранит векторные представления (эмбеддинги) для различных источников.

| Поле | Тип | Описание |
| ------ | ----- | ---------- |
| id | TEXT | PRIMARY KEY |
| sourceType | TEXT | Тип источника (receipt, memory_note, obsidian_note, ...) |
| sourceId | TEXT | Стабильный идентификатор источника |
| content | TEXT | Текст, по которому строится эмбеддинг |
| vector | BLOB | Вектор в формате Float32Array → Uint8List |
| model | TEXT | Модель эмбеддинга |
| embeddingVersion | INTEGER | Версия для миграции |
| createdAt | TEXT | ISO 8601 |
| updatedAt | TEXT | ISO 8601 |
| sourceUpdatedAt | TEXT | Время последнего обновления источника |
| embeddingUpdatedAt | TEXT | Время последнего обновления эмбеддинга |
| metadata | TEXT | JSON с метаданными |

**Индексы:**

- `idx_embeddings_source` ON (`sourceType`, `sourceId`)
- `idx_embeddings_updated` ON (`updatedAt`)

---

### memory_notes

| Поле | Тип | Описание |
| ------ | ----- | ---------- |
| id | TEXT | PRIMARY KEY |
| title | TEXT | Заголовок заметки |
| content | TEXT | Текст заметки |
| category | TEXT | Категория (опционально) |
| createdAt | TEXT | ISO 8601 |
| updatedAt | TEXT | ISO 8601 |

**Индексы:**

- `idx_memory_notes_category` ON (`category`)

---

## Новые таблицы (планируемые)

### categories

| Поле | Тип | Описание |
| ------ | ----- | ---------- |
| id | TEXT PK | UUID |
| name | TEXT NOT NULL | Название категории |
| parentId | TEXT | FK → categories.id (иерархия) |
| color | TEXT | Цвет для UI |
| icon | TEXT | Иконка |
| isDefault | INTEGER | 1 — системная категория |
| createdAt | TEXT | ISO 8601 |
| updatedAt | TEXT | ISO 8601 |

**Индексы:**

- `idx_categories_parent` ON (`parentId`)
- `idx_categories_name` ON (`name`)

---

### budget_periods

| Поле | Тип | Описание |
| ------ | ----- | ---------- |
| id | TEXT PK | UUID |
| name | TEXT | Название (опционально) |
| startDate | TEXT NOT NULL | ISO 8601 |
| endDate | TEXT NOT NULL | ISO 8601 |
| status | TEXT NOT NULL | active / archived |
| createdAt | TEXT | ISO 8601 |

**Индексы:**

- `idx_budget_periods_dates` ON (`startDate`, `endDate`)
- `idx_budget_periods_status` ON (`status`)

---

### budget_items

| Поле | Тип | Описание |
| ------ | ----- | ---------- |
| id | TEXT PK | UUID |
| periodId | TEXT NOT NULL | FK → budget_periods.id |
| categoryId | TEXT NOT NULL | FK → categories.id |
| plannedAmount | REAL NOT NULL | Плановая сумма |
| spentAmount | REAL | Вычисляется, опционально для кэша |

**Индексы:**

- `idx_budget_items_period` ON (`periodId`)
- `idx_budget_items_category` ON (`categoryId`)

---

### debts

| Поле | Тип | Описание |
| ------ | ----- | ---------- |
| id | TEXT PK | UUID |
| counterparty | TEXT NOT NULL | Кому / от кого |
| amount | REAL NOT NULL | Сумма |
| currency | TEXT | Валюта (по умолчанию RUB) |
| type | TEXT NOT NULL | owed_to_me / i_owe |
| date | TEXT NOT NULL | ISO 8601 |
| dueDate | TEXT | ISO 8601 (срок) |
| status | TEXT NOT NULL | active / partial / closed / overdue |
| originalAmount | REAL | Для истории |
| comment | TEXT | |
| createdAt | TEXT | ISO 8601 |
| updatedAt | TEXT | ISO 8601 |

**Индексы:**

- `idx_debts_status` ON (`status`)
- `idx_debts_due_date` ON (`dueDate`)
- `idx_debts_counterparty` ON (`counterparty`)

---

### debt_payments

| Поле | Тип | Описание |
| ------ | ----- | ---------- |
| id | TEXT PK | UUID |
| debtId | TEXT NOT NULL | FK → debts.id |
| amount | REAL NOT NULL | Сумма погашения |
| date | TEXT NOT NULL | ISO 8601 |
| comment | TEXT | |
| operationId | TEXT | FK → operations.id (связь с операцией) |

**Индексы:**

- `idx_debt_payments_debt` ON (`debtId`)
- `idx_debt_payments_date` ON (`date`)

---

### recurring_payments

| Поле | Тип | Описание |
| ------ | ----- | ---------- |
| id | TEXT PK | UUID |
| name | TEXT NOT NULL | |
| amount | REAL NOT NULL | |
| categoryId | TEXT | FK → categories.id |
| accountId | TEXT | FK → accounts.id |
| startDate | TEXT | ISO 8601 |
| endDate | TEXT | ISO 8601 (опционально) |
| frequency | TEXT | monthly / weekly / yearly |
| dayOfMonth | INTEGER | День списания |
| isActive | INTEGER | 1 / 0 |
| createdAt | TEXT | ISO 8601 |
| updatedAt | TEXT | ISO 8601 |

**Индексы:**

- `idx_recurring_payments_active` ON (`isActive`)
- `idx_recurring_payments_next_date` ON (`startDate`)

---

### purchase_plans

| Поле | Тип | Описание |
| ------ | ----- | ---------- |
| id | TEXT PK | UUID |
| name | TEXT NOT NULL | |
| targetAmount | REAL NOT NULL | |
| currentAmount | REAL | Вычисляется |
| deadline | TEXT | ISO 8601 |
| categoryId | TEXT | FK → categories.id |
| priority | TEXT | low / medium / high |
| comment | TEXT | |
| photoPath | TEXT | |
| link | TEXT | |
| status | TEXT | active / achieved / archived |
| createdAt | TEXT | ISO 8601 |
| updatedAt | TEXT | ISO 8601 |

**Индексы:**

- `idx_purchase_plans_status` ON (`status`)
- `idx_purchase_plans_deadline` ON (`deadline`)

---

### custom_field_definitions

| Поле | Тип | Описание |
| ------ | ----- | ---------- |
| id | TEXT PK | UUID |
| entityType | TEXT NOT NULL | operation / receipt / receiptItem / memoryNote |
| fieldName | TEXT NOT NULL | Название поля |
| fieldType | TEXT NOT NULL | text / number / date / boolean / select / multiselect |
| options | TEXT | JSON-массив для select/multiselect |
| isRequired | INTEGER | 0 / 1 |
| defaultValue | TEXT | JSON-значение по умолчанию |
| position | INTEGER | Порядок отображения |
| createdAt | TEXT | ISO 8601 |
| updatedAt | TEXT | ISO 8601 |

**Индексы:**

- `idx_custom_field_def_entity` ON (`entityType`)

---

### custom_field_values

| Поле | Тип | Описание |
| ------ | ----- | ---------- |
| id | TEXT PK | UUID |
| entityId | TEXT NOT NULL | ID сущности (operation.id, receipt.id, ...) |
| definitionId | TEXT NOT NULL | FK → custom_field_definitions.id |
| value | TEXT NOT NULL | JSON-значение (универсальное) |
| updatedAt | TEXT | ISO 8601 |

**Индексы:**

- `idx_custom_field_values_entity` ON (`entityId`)
- `idx_custom_field_values_definition` ON (`definitionId`)

**Ограничения:**

- `UNIQUE(entityId, definitionId)` — одна запись на сущность и определение.

---

### settings (планируется)

| Поле | Тип | Описание |
| ------ | ----- | ---------- |
| key | TEXT PK | Ключ настройки |
| value | TEXT | Значение (JSON или строка) |
| updatedAt | TEXT | ISO 8601 |

**Примеры настроек:**

- `photo_retention_days` → `"7"` (срок хранения фото)
- `swipe_to_delete` → `"true"` (удаление свайпом)
- `default_operation_mode` → `"all_accounts"` (режим истории)
- `ai_model` → `"openai/gpt-4o-mini"` (AI-модель)
- `auto_indexing` → `"true"` (автоиндексация)
- `semantic_search_limit` → `"10"` (количество результатов)

---

### receipt_drafts (планируется)

| Поле | Тип | Описание |
| ------ | ----- | ---------- |
| id | TEXT PK | UUID |
| createdAt | TEXT | ISO 8601 |
| updatedAt | TEXT | ISO 8601 |
| status | TEXT | draft / processing / completed / failed |
| photoPaths | TEXT | JSON-массив путей к фото |
| parsedData | TEXT | JSON с результатами AI |
| receiptId | TEXT | FK → receipts.id (после завершения) |
| error | TEXT | Сообщение об ошибке |

**Индексы:**

- `idx_receipt_drafts_status` ON (`status`)
- `idx_receipt_drafts_created` ON (`createdAt`)

---

## Изменения в существующих таблицах

### receipt_items (миграция)

| Изменение | Описание |
|-----------|----------|
| `category` (TEXT) | → заменяется на `categoryId` (TEXT, FK → categories.id) |
| `category` сохраняется | для обратной совместимости (переходный период) |

### operations (миграция)

| Изменение | Описание |
| ----------- | ---------- |
| Добавляется `debtId` | TEXT, FK → debts.id — для операций погашения |
| Добавляется `categoryId` | TEXT, FK → categories.id — опционально, для быстрого доступа |
| `type` | Добавляются значения `transfer` и `debt_repayment` |

---

## Индексы (полный список)

| Индекс | Таблица | Поля |
| -------- | --------- | ------ |
| `idx_embeddings_source` | embeddings | (sourceType, sourceId) |
| `idx_embeddings_updated` | embeddings | (updatedAt) |
| `idx_memory_notes_category` | memory_notes | (category) |
| `idx_categories_parent` | categories | (parentId) |
| `idx_categories_name` | categories | (name) |
| `idx_budget_periods_dates` | budget_periods | (startDate, endDate) |
| `idx_budget_periods_status` | budget_periods | (status) |
| `idx_budget_items_period` | budget_items | (periodId) |
| `idx_budget_items_category` | budget_items | (categoryId) |
| `idx_debts_status` | debts | (status) |
| `idx_debts_due_date` | debts | (dueDate) |
| `idx_debts_counterparty` | debts | (counterparty) |
| `idx_debt_payments_debt` | debt_payments | (debtId) |
| `idx_debt_payments_date` | debt_payments | (date) |
| `idx_recurring_payments_active` | recurring_payments | (isActive) |
| `idx_recurring_payments_next_date` | recurring_payments | (startDate) |
| `idx_purchase_plans_status` | purchase_plans | (status) |
| `idx_purchase_plans_deadline` | purchase_plans | (deadline) |
| `idx_custom_field_def_entity` | custom_field_definitions | (entityType) |
| `idx_custom_field_values_entity` | custom_field_values | (entityId) |
| `idx_custom_field_values_definition` | custom_field_values | (definitionId) |
| `idx_receipt_drafts_status` | receipt_drafts | (status) |
| `idx_receipt_drafts_created` | receipt_drafts | (createdAt) |

---

## Database Methods (DatabaseHelper)

| Метод | Назначение |
| ------- | ------------ |
| `insertAccount()` | Добавление счёта |
| `updateAccount()` | Обновление счёта |
| `deleteAccount()` | Удаление (запрещено для основного) |
| `getAccounts()` | Все счета |
| `insertOperation()` | Добавление операции |
| `getOperations()` | Все операции |
| `getOperationsByAccount()` | По счёту |
| `deleteOperation()` | Удаление |
| `updateOperationByReceiptId()` | Обновление по чеку |
| `insertReceipt()` | Добавление чека |
| `updateReceipt()` | Обновление чека |
| `deleteReceipt()` | Удаление (транзакционно) |
| `getReceipts()` | Все чеки |
| `getReceiptById()` | По ID |
| `insertReceiptItem()` | Добавление товара |
| `updateReceiptItem()` | Обновление товара |
| `getReceiptItems()` | Товары чека |
| `recalculateReceiptAmount()` | Пересчёт суммы чека |
| `updateOperationAmount()` | Обновление суммы операции |
| `insertReceiptWithItems()` | Транзакционное сохранение |

Методы изменения данных используют транзакции (`deleteReceipt`, `insertReceiptWithItems`).

---

## ID Rules

Все PK — TEXT (UUID). Поддержка UUID, импорт, гибкость.
Примеры: `REC-...`, `ITEM-...`, `OP-...`

---

## Миграции

**Версия БД:** 3

### Миграция v1 → v2 (план)

1. Создать таблицы:
   - `categories`
   - `budget_periods`
   - `budget_items`
   - `debts`
   - `debt_payments`
   - `recurring_payments`
   - `purchase_plans`

2. Добавить поля:
   - `operations.debtId`
   - `operations.categoryId`

3. Перенести текстовые категории из `receipt_items.category` в `categories` (авто-создание)
4. Заполнить `receipt_items.categoryId` ссылками на новые категории

### Миграция v2 → v3 (план)

1. Создать таблицы:
   - `custom_field_definitions`
   - `custom_field_values`
   - `settings`
   - `receipt_drafts`

2. Добавить индексы

---

## Current Database State

### ✅ Реализовано

- SQLite подключена
- Таблицы: `accounts`, `operations`, `receipts`, `receipt_items`, `card_color_settings`, `embeddings`, `memory_notes`
- Связи: чек→товары (1:M), чек→операция (1:1), счёт→операции (1:M)
- Транзакционное сохранение
- Обновление товаров + перерасчёт чека
- Система основного счёта
- Настройки цветов
- Хранение эмбеддингов (BLOB)
- Хранение заметок для индексации

### 🟡 Не реализовано

- Удаление отдельных товаров через UI
- Управление категориями (отдельная таблица)
- Таблица `settings` (пользовательские настройки)
- Таблица `receipt_drafts` (черновики чеков)
- Таблицы бюджета, долгов, планов покупок
- Таблицы пользовательских полей
- Отдельная БД для векторов (`memory_database.dart` пуст)
- Шифрование БД (SQLCipher)

---

## Future Structure

```
Receipt → ReceiptItem → Category
    ↓
Operation → Account → FinancialState
    ↓
BudgetPeriod → BudgetItem
    ↓
Debt → DebtPayment
    ↓
RecurringPayment (авто-создание операций)
PurchasePlan (цели накопления)
    ↓
CustomFieldDefinition → CustomFieldValue → (Operation / Receipt / ReceiptItem / MemoryNote)
```

**Главный принцип:** SQLite хранит факты. SQLite не принимает финансовые решения.
