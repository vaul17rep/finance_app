# CODE MAP

Назначение:

Карта исходного кода проекта.

Используется AI-агентами для понимания структуры системы.

---

# Architecture Overview

Проект разделён на слои:

- Domain Layer
- Data Layer
- Feature Layer
- UI Layer

---

# Domain Layer

Location:

lib/domain/

Responsibility:

Содержит бизнес-модель системы.

Включает:

- финансовые сущности;
- правила;
- расчёты;
- ограничения.

Allowed:

- бизнес-логика;
- domain entities;
- value objects.

Forbidden:

- UI зависимости;
- прямой доступ к базе данных;
- внешние сервисы.

---

# Data Layer

Location:

lib/data/

Responsibility:

Работа с хранением и получением данных.

Включает:

- repositories;
- database;
- services.

Allowed:

- реализация хранения;
- преобразование данных.

Forbidden:

- бизнес-решения;
- пользовательские сценарии.

---

# Feature Layer

Location:

lib/features/

Responsibility:

Пользовательские сценарии.

Включает:

- feature logic;
- orchestration;
- состояния.

Allowed:

- взаимодействие слоёв;
- сценарии пользователя.

Forbidden:

- хранение истины;
- дублирование domain logic.

---

# UI Layer

Location:

lib/

Responsibility:

Отображение и взаимодействие пользователя.

UI должен:

- показывать данные;
- отправлять действия.

UI не должен:

- считать финансовые правила;
- хранить бизнес-логику.

---

# Dependency Direction

Правильное направление:

UI

↓

Features

↓

Domain

↑

Data

---

# AI Rule

Если структура кода неизвестна:

AI обязан запросить доступ к фактическому коду.

Запрещено придумывать:

- классы;
- файлы;
- методы;
- зависимости.
