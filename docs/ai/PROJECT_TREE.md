# PROJECT TREE

Версия:

1.0

Назначение:

Этот документ описывает структуру проекта LifeOS.

Используется AI-агентами как навигационная карта.

PROJECT_TREE не заменяет анализ исходного кода.

Если структура проекта отличается от описанной:

AI обязан проверить фактическое состояние репозитория.

---

# Repository Root

finance_app/

Основные области:

finance_app

├── docs/
├── lib/
├── test/
├── assets/
├── configuration files
└── project files

---

# Documentation

Location:

docs/

Назначение:

Хранение проектной документации.

Содержит:

- архитектуру;
- требования;
- историю;
- AI workflow;
- правила разработки.

Структура:

docs/

├── 00_Master_Documentation.md
├── 01_Current_State.md
├── 02_Architecture.md
├── 03_Domain_Model.md
├── 04_Financial_Rules.md
├── 05_Database_Specification.md
├── 06_AI_System.md
├── 07_Functional_Requirements.md
├── 08_Project_History.md
├── 09_Development_Log.md
├── 10_Roadmap.md
├── 11_Development_Guidelines.md
├── 12_Documentation_System.md
├── 13_AI_Team_Workflow.md
└── ai/

---

# AI Context Layer

Location:

docs/ai/

Назначение:

Контекст для AI-агентов.

Содержит:

docs/ai/

├── PROJECT_CONTEXT.md
├── AI_ROLES.md
├── WORKFLOW.md
├── DOCUMENTATION_MAP.md
├── CODE_MAP.md
├── PROJECT_TREE.md
├── CHANGE_PROTOCOL.md
└── prompts/

---

# AI Prompts

Location:

docs/ai/prompts/

Назначение:

Специализированные инструкции для AI-ролей.

Содержит:

prompts/

├── system_architect.md
├── principal_architect.md
├── implementation_specification.md
├── developer.md
├── code_reviewer.md
├── knowledge_manager_plan.md
└── knowledge_manager_done.md

---

# Source Code

Location:

lib/

Назначение:

Основной код приложения.

Архитектурное разделение:

lib/

├── domain/
├── data/
├── features/
└── shared/

---

# Domain Layer

Location:

lib/domain/

Ответственность:

Бизнес-логика системы.

Содержит:

- сущности;
- правила;
- расчёты;
- ограничения.

Пример ответственности:

Финансовая операция.

Категория расходов.

Расчёт баланса.

Не содержит:

- UI;
- database implementation;
- внешние сервисы.

---

# Data Layer

Location:

lib/data/

Ответственность:

Работа с данными.

Содержит:

- repositories;
- database;
- storage;
- external data sources.

Не содержит:

- бизнес-решения;
- пользовательские сценарии.

---

# Feature Layer

Location:

lib/features/

Ответственность:

Пользовательские сценарии.

Содержит:

- отдельные функции приложения;
- состояния;
- взаимодействие компонентов.

Feature может использовать:

- Domain;
- Data.

Feature не является источником истины.

---

# Shared Components

Location:

lib/shared/

Ответственность:

Общие компоненты.

Может содержать:

- utilities;
- common widgets;
- shared services.

Ограничение:

Shared не должен превращаться в место хранения всей логики.

---

# Tests

Location:

test/

Назначение:

Проверка корректности системы.

Типы тестов:

test/

├── domain/
├── data/
├── features/
└── integration/

---

# Assets

Location:

assets/

Назначение:

Статические ресурсы.

Например:

- изображения;
- файлы;
- локальные данные.

---

# Navigation Rules For AI

## Если задача про бизнес-правила

Смотреть:

1. PROJECT_CONTEXT.md
2. Domain Model
3. Financial Rules
4. lib/domain/

---

## Если задача про хранение данных

Смотреть:

1. Database Specification
2. Architecture
3. lib/data/

---

## Если задача про пользовательскую функцию

Смотреть:

1. Functional Requirements
2. Current State
3. lib/features/

---

## Если задача меняет архитектуру

Смотреть:

1. Architecture
2. Domain Model
3. CODE_MAP
4. Исходный код

---

## Если задача меняет AI Workflow

Смотреть:

1. AI System
2. AI Team Workflow
3. docs/ai/

---

# AI Safety Rules

Если файл или модуль неизвестен:

НЕ предполагать его существование.

Запрещено создавать утверждения:

- "этот класс находится здесь";
- "этот сервис уже существует";
- "этот метод реализован";

Проверять:

- фактический репозиторий;
- документацию;
- историю изменений.

---

# Update Rule

Если структура проекта изменилась:

необходимо обновить:

☐ PROJECT_TREE.md

☐ CODE_MAP.md

☐ DOCUMENTATION_MAP.md (если изменились документы)

☐ Development Log
