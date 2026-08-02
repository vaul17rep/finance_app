## 03_Domain_Model.md

---

**Version:** 3.1
**Last Updated:** 2026-08-02

---

## Назначение

Бизнес-сущности LifeOS. Какие понятия существуют внутри системы.

---

## Область ответственности

### Описывает

- Бизнес-сущности, их назначение и связи
- Смысл данных

### НЕ описывает

- Flutter-классы, SQLite, UI, техническую реализацию
- AI-процессы, конкретные расчёты
- Технические детали системы знаний → [[06_AI_System]]

**Связанные документы:**

- Финансовая логика → [[04_Financial_Rules]]
- Хранение данных → [[05_Database_Specification]]
- Архитектура → [[02_Architecture]]

---

## Общая модель системы

LifeOS построена вокруг операций. **Operation — источник истины.**

Поток данных:
Фото чека → AI → ParsedReceipt → Receipt → ReceiptResult (Receipt + Operation) → Operation → FinancialCalculator → FinancialState

---

## Статус сущностей

| Сущность | Статус | Расположение | Примечание |
| ---------- | -------- | -------------- | ------------ |
| Account | ✅ Реализовано (базово) | lib/models/account.dart | Полная настройка не реализована |
| CardColorSettings | ✅ Реализовано | lib/models/card_color_settings.dart | |
| Receipt | ✅ Реализовано | lib/models/receipt.dart | |
| ReceiptItem | ✅ Реализовано | lib/models/receipt_item.dart | |
| ParsedReceipt | ✅ Реализовано | lib/models/parsed_receipt.dart | DTO, не сохраняется |
| ReceiptResult | ✅ Реализовано | lib/models/receipt_result.dart | Транзакционная обёртка |
| Operation | ✅ Реализовано | lib/models/operation.dart | |
| OperationType | ✅ Реализовано | lib/models/operation_type.dart | |
| Category | 🔄 В разработке | lib/models/category.dart | Будет отдельная таблица |
| FinancialState | ✅ Базовая модель | lib/domain/entities/financial_state.dart | |
| BudgetPeriod | 📅 Планируется | — | Новая сущность |
| BudgetItem | 📅 Планируется | — | Новая сущность |
| Debt | 📅 Планируется | — | Новая сущность |
| DebtPayment | 📅 Планируется | — | Новая сущность |
| RecurringPayment | 📅 Планируется | — | Новая сущность |
| PurchasePlan | 📅 Планируется | — | Новая сущность |
| CustomFieldDefinition | 📅 Планируется | — | Новая сущность |
| CustomFieldValue | 📅 Планируется | — | Новая сущность |
| Rule | 📅 Планируется | — | |
| History | 📅 Планируется | — | |
| ReceiptDraft | ❌ Не реализовано | — | Новая сущность |
| Settings | ❌ Не реализовано | — | Новая сущность |
| MemoryNote | ⚠️ Будет изменено | lib/features/memory/models/memory_note.dart | Будет заменено системой знаний |
| EmbeddingModel | ✅ Реализовано | lib/features/memory/models/embedding_model.dart | Техническая модель |
| ObsidianNote | ⚠️ Будет изменено | lib/features/memory/models/obsidian_note.dart | Будет заменено системой знаний |

---

## Сущности

### 1. Account

Источник денежных средств пользователя (карта, наличные, кредитка, накопительный счёт). Владелец операций.

**Поля:** id, name, type, initialBalance, isMain, position, icon, color (→ CardColorSettings).

**Связи:** Account → много Operation. Account → одна CardColorSettings.

❌ Не хранит текущий баланс. Баланс = результат расчёта операций.

#### Полная настройка счетов

**Свободно изменяемые поля** (не влияют на операции):

- Название
- Иконка
- Цвет (через CardColorSettings)
- Описание
- Порядок (position)
- Основной счёт (isMain)

**Изменяемые с обработкой последствий** (требуют сценарий миграции):

- Тип счёта — при смене типа система проверяет операции и предлагает миграцию с предупреждением
- Начальный баланс — через корректирующую операцию, а не прямое изменение

**Неизменяемые поля:**

- ID
- Валюта (изменение валюты = создание нового счёта)

### 2. CardColorSettings

Настройки цветового оформления карточки счёта для визуальной идентификации.

**Поля:** id, accountId, backgroundColor, textColor.

**Связи:** CardColorSettings ↑ Account (один к одному).

### 3. ParsedReceipt

Промежуточная модель между AI-ответом и Receipt. Данные, извлечённые AI из чека.

**Поля:** merchant, date, totalAmount, items.

**Связи:** ParsedReceipt → ReceiptCreationService → Receipt.

DTO, не сохраняется в БД.

### 4. Receipt

Документ покупки из чека. Хранит факт покупки.

**Поля:** магазин, дата, сумма, фото, комментарий.

**Связи:** Receipt 1:N ReceiptItem. Receipt → ReceiptResult → Operation.

❌ Не является финансовой операцией, сам не меняет баланс.
❌ Не имеет категории. Категория — только у ReceiptItem.

### 5. ReceiptItem

Отдельная позиция внутри чека.

**Поля:** id, receiptId, name, categoryId, quantity, price, totalPrice, comment.

**Связи:** ReceiptItem ↑ Receipt. ReceiptItem → Category.

**Категория — обязательное поле** (или со значением по умолчанию).
Детализация покупки, не самостоятельная операция.

### 6. ReceiptResult

Транзакционная связка: результат обработки чека. Объединяет Receipt + Operation.

**Поля:** receipt, operation.

**Связи:** Receipt → ReceiptResult → Operation.

Обеспечивает атомарность: один чек → один ReceiptResult → один Receipt + одна Operation.
Не сохраняется как отдельная сущность.

### 7. Operation

**Основная финансовая сущность.** Движение денег. Все изменения системы — через операции.
Источник истины: Operation History.

**Типы (OperationType):**

- `expense` — расход
- `income` — доход
- `transfer` — перевод между счетами
- `debt_repayment` — погашение долга

**Поля:** id, type, amount, date, comment, shop, accountId, receiptId, debtId (опционально), categoryId (опционально, кэш).

**Связи:**

- Receipt: Receipt → ReceiptResult → Operation
- Account: Account → много Operation
- Debt: Debt → Operation (при погашении)
- FinancialState: Operation → FinancialCalculator → FinancialState

**Категория:** опционально, для быстрого доступа (кэш). Основной источник категорий — ReceiptItem.

**Источники создания:**

- Ручной ввод
- Receipt (фото → AI → ParsedReceipt → Receipt → ReceiptResult → Operation)
- Авто-создание из RecurringPayment
- Импорт (планируется)

### 8. Category

Классификация товаров и операций.

**Принятое решение:**

- Категория — только у ReceiptItem.
- Отдельная таблица `categories` с пользовательскими категориями.
- Авто-определение категории при распознавании чека.
- Иерархия категорий (родитель-потомок).

**Поля:** id, name, parentId, color, icon, isDefault, createdAt.

### 9. FinancialState

Вычисленное финансовое состояние пользователя.

❌ Не источник истины. Источник: Operation.
Расчёт для каждого Account отдельно: Account → Operation → FinancialCalculator → FinancialState.
Вычисляется на лету, не сохраняется в БД.

### 10. BudgetPeriod

Бюджетный период. Пользовательский (по умолчанию от зарплаты до зарплаты).

**Поля:** id, name, startDate, endDate, status (active / archived), createdAt.

### 11. BudgetItem

План по категории внутри периода.

**Поля:** id, periodId, categoryId, plannedAmount.

**Расчёт:** spentAmount вычисляется из операций по категориям за период.

### 12. Debt

Финансовая задолженность. **Отдельная сущность, не часть Financial State.**

**Поля:** id, counterparty, amount, currency, type (owed_to_me / i_owe), date, dueDate, status (active / partial / closed / overdue), originalAmount, comment, createdAt, updatedAt.

**Связи:** Debt → много DebtPayment. Debt → Operation (при погашении).

**Правила:**

- Просроченные долги не исчезают — всегда видны до ручного закрытия.
- При погашении создаётся Operation типа `debt_repayment`.

### 13. DebtPayment

История погашения долга.

**Поля:** id, debtId, amount, date, comment, operationId (FK → operations.id).

### 14. RecurringPayment

Регулярный платёж (аренда, подписки).

**Поля:** id, name, amount, categoryId, accountId, startDate, endDate (опционально), frequency (monthly/weekly/yearly), dayOfMonth, isActive.

**Правила:** при наступлении даты создаётся Operation автоматически.

### 15. PurchasePlan

План покупки с накоплением.

**Поля:** id, name, targetAmount, currentAmount (вычисляется), deadline, categoryId, priority (low/medium/high), comment, photoPath, link, status (active/achieved/archived).

### 16. CustomFieldDefinition

Определение пользовательского поля для сущности.

**Поля:**

- id (UUID)
- entityType — `operation`, `receipt`, `receiptItem`, `memoryNote`
- fieldName — название поля (отображается в UI)
- fieldType — `text`, `number`, `date`, `boolean`, `select`, `multiselect`
- options (JSON) — для select/multiselect: список значений
- isRequired — обязательно ли поле
- defaultValue (JSON) — значение по умолчанию
- position — порядок отображения
- createdAt, updatedAt

### 17. CustomFieldValue

Значение пользовательского поля для конкретной записи.

**Поля:**

- id (UUID)
- entityId — ID сущности (operation.id, receipt.id, ...)
- definitionId — FK → custom_field_definitions.id
- value (JSON) — универсальное хранение (текст, число, дата, булево, массив)
- updatedAt

**Связи:**

- CustomFieldDefinition 1:N CustomFieldValue
- CustomFieldValue → сущность (полиморфная связь через entityId + entityType)

### 18. Rule

📅 Планируется. Автоматическое правило обработки данных.
Из Legacy Google Sheets. Пример: "кредитка сбер" → Rule → Account: "Кредитка".

### 19. History

📅 Планируется. История изменений для аудита и восстановления.

### 20. ReceiptDraft

❌ Не реализовано. Черновик чека для объединения нескольких фото.

**Жизненный цикл:**
Receipt Draft (создание) → Добавление фотографий → Редактирование → Распознавание (AI) → Receipt → Operation

**Поля:** id, createdAt, updatedAt, status (draft/processing/completed/failed), photoPaths (порядок важен), parsedData (результат AI), receiptId (ссылка на финальный Receipt), error.

❌ Не является финансовой операцией. Только черновик.

---

## Концепция: Knowledge Source (система знаний)

Система знаний строится вокруг абстракции источника. Это архитектурная концепция, а не финальная модель данных.

**Назначение:** Любой источник информации, который может быть проиндексирован и найден через семантический поиск.

**Примеры источников:**

- Obsidian Vault (md файлы) — реализовано
- Внутренние заметки приложения — реализовано (будет заменено)
- PDF-документы — планируется
- Telegram-сообщения — планируется
- Google Drive-файлы — планируется
- Email-письма — планируется
- Голосовые заметки (транскрипция) — планируется
- Изображения (OCR + описание) — планируется

**Принципы:**

- Единый интерфейс для всех источников
- Каждый источник предоставляет: текст, метаданные, уникальный идентификатор
- Индексация и поиск — общие для всех источников
- Конфиденциальность: источники с чувствительными данными помечаются

---

## Конфиденциальность и чувствительные данные

Следующие данные считаются чувствительными и не должны передаваться вовне без явного согласия пользователя:

- Финансовые данные: суммы, счета, операции, категории
- Персональные данные: имена, адреса, контакты
- Фотографии чеков: могут содержать личную информацию
- Заметки: могут содержать личные мысли, планы, идеи
- История операций: полная финансовая история пользователя

**Принцип обработки:**

- Все данные хранятся локально (SQLite, файловая система)
- Внешние AI-вызовы (OpenRouter) отправляют только:
  - Для распознавания чеков: фотографию (временная отправка, не сохраняется)
  - Для эмбеддингов: текст (временная отправка, не сохраняется)
- Никакие данные не передаются третьим лицам
- API-ключи используются только для авторизации запросов

---

## Связи между сущностями

### Текущая реализованная модель

```
Account ← CardColorSettings
   ↓
Receipt → ReceiptItem → Category
   ↓
ReceiptResult → Operation (expense / income / transfer)
   ↓
FinancialState
```

### Полная модель (с планируемыми)

```
Account ← CardColorSettings
   ↓
Receipt → ReceiptItem → Category
   ↓
ReceiptResult → Operation (expense / income / transfer / debt_repayment)
   ↓                ↓
FinancialState ← BudgetPeriod → BudgetItem
   ↓
Debt ← DebtPayment
   ↓
RecurringPayment (авто-создание операций)
PurchasePlan (цели накопления)

CustomFieldDefinition
   ↓
CustomFieldValue → (Operation / Receipt / ReceiptItem / MemoryNote)
```

### С новой концепцией (система знаний)

```
Knowledge Source (Obsidian, заметки, PDF, ...)
   ↓
Индексация → Эмбеддинги → Семантический поиск
   ↓
Результаты с ссылками на источники
```

---

## Что НЕ является бизнес-сущностью

- Фото чека — источник создания Receipt (UI/ввод данных)
- AI JSON — промежуточный формат
- ParsedReceipt — DTO на границе AI и доменной модели
- ReceiptResult — транзакционная обёртка (не сохраняется)
- Баланс — результат вычисления, не объект хранения
- Технические модели системы знаний (MemoryChunk, MemorySource, MemorySearchResult) — относятся к [[06_AI_System]]

---

## Основные принципы модели

1. **Operation — источник истины**
2. **Движение денег** — все изменения через Operation
3. **Владение** — Account владеет операциями
4. **Расчётность** — FinancialState вычисляется, не хранится
5. **Документирование** — Receipt описывает покупку, не меняет финансы
6. **Детализация** — ReceiptItem детализирует покупку, не операция
7. **Транзакционность** — ReceiptResult = атомарная связка Receipt + Operation
8. **AI — инструмент ввода** — создаёт данные, не определяет логику
9. **Независимость модели** — бизнес-модель не зависит от технической реализации
10. **Приватность по умолчанию** — все данные локальные, внешние вызовы только с согласия пользователя
11. **Категория — только у ReceiptItem** — у чека категории нет
12. **Долг — отдельная сущность** — не часть Financial State
13. **Просроченное не исчезает** — всегда видно до ручного закрытия
14. **Пользовательские поля — метаданные** — не влияют на финансовую логику
15. **Бюджетный период — пользовательский** — по умолчанию от зарплаты до зарплаты

---

## Открытые вопросы

❓ Связь Receipt и Operation — может ли один чек создавать несколько операций? (Пока один к одному)
❓ Перенос FinancialState — из lib/domain/entities/ в lib/models/ при кэшировании?
❓ Модель данных для Knowledge Source — финальное название и структура
❓ Механизм изменения начального баланса — через корректирующую операцию или отдельный метод?
❓ Какие функции будут платными? — требуется чёткое разделение
❓ Нужно ли шифровать локальную БД? (SQLCipher или другая технология)

---

## Итоговая модель

**Финансовое ядро:**
Факты (фото чеков) → AI (ParsedReceipt) → Бизнес-сущности (Receipt → ReceiptResult → Operation) → Расчёты (FinancialCalculator) → Финансовое состояние (FinancialState)

**Планирование:**
BudgetPeriod + BudgetItem → План/факт по категориям → Аналитика

**Обязательства:**
Debt + DebtPayment → Погашение через Operation

**Кастомизация:**
CustomFieldDefinition + CustomFieldValue → Метаданные для любых сущностей

**Система знаний:**
Knowledge Source → Индексация → Эмбеддинги → Семантический поиск

AI ускоряет ввод. Бизнес-логика — внутри приложения. Operation — единственный источник истины для финансов. Система знаний — универсальный слой поверх всех источников информации.
