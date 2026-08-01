# AI DEVELOPMENT WORKFLOW

Версия:

1.0

Назначение:

Этот документ описывает полный жизненный цикл разработки с использованием AI-агентов проекта LifeOS.

---

# Основной принцип

AI работает как команда специалистов.

Каждый этап имеет:

- входные данные;
- ответственную роль;
- результат;
- следующий этап.

Каждый переход между ролями должен сохранять полный контекст задачи.

---

# Workflow Overview

## Stage 1

REQUEST

Ответственный:

Product Owner

Вход:

- идея;
- проблема;
- требование.

Результат:

TASK REQUEST

↓

---

## Stage 2

ARCHITECTURE ANALYSIS

Ответственный:

System Architect

Действия:

- изучить AI Context Layer;
- изучить документацию;
- изучить код;
- определить влияние изменения;
- подготовить архитектурное предложение.

Результат:

ARCHITECT BRIEF

Переход:

System Architect

↓

Principal Architect

---

## Stage 3

ARCHITECTURE REVIEW

Ответственный:

Principal Architect

Действия:

- проверить решение;
- найти архитектурные риски;
- проверить масштаб;
- проверить соответствие принципам проекта.

Результат:

ARCHITECT REVIEW

Возможные статусы:

- Approved
- Need Changes
- Cannot Review

Переход:

Principal Architect

↓

Product Owner

---

## Stage 4

PRODUCT DECISION

Ответственный:

Product Owner

Действия:

- принять решение;
- утвердить направление;
- выбрать вариант решения.

Результат:

APPROVED DECISION

Переход:

Product Owner

↓

Implementation Specification Agent

---

## Stage 5

IMPLEMENTATION SPECIFICATION

Ответственный:

Implementation Specification Agent

Действия:

Создать:

- технический план реализации;
- список изменений;
- затронутые компоненты;
- требования для Developer;
- критерии проверки.

Результат:

IMPLEMENTATION SPECIFICATION

Переход:

Implementation Specification Agent

↓

Developer

---

## Stage 6

DEVELOPMENT

Ответственный:

Developer

Действия:

- реализовать спецификацию;
- написать код;
- добавить тесты;
- подготовить Implementation Report.

Ограничение:

Developer не меняет архитектурные решения.

Если решение невозможно реализовать:

создаёт:

IMPLEMENTATION BLOCKER

и возвращает вопрос на архитектурный этап.

Результат:

IMPLEMENTATION REPORT

---

## Stage 7

CODE REVIEW

Ответственный:

Code Reviewer

Действия:

Проверить:

- соответствие Architecture Decision;
- соответствие Implementation Specification;
- качество кода;
- архитектурные ограничения;
- тесты;
- технический долг.

Результат:

CODE REVIEW

Статусы:

- Approved
- Needs Fix
- Blocked

---

## Stage 8

KNOWLEDGE UPDATE

Ответственный:

Knowledge Manager

Действия:

Проверить:

- архитектуру;
- доменную модель;
- базу данных;
- историю изменений;
- AI Context Layer.

Определить:

- какие документы требуют обновления;
- какие документы проверены и не требуют изменений;
- какие новые знания появились в системе.

Результат:

DOCUMENTATION UPDATED

---

## Stage 9

DONE

Условия завершения:

☐ Код реализован

☐ Code Review пройден

☐ Документация обновлена

☐ История изменений обновлена

☐ AI Context Layer синхронизирован

---

# Handoff Rules

## System Architect → Principal Architect

Передать:

- Architect Brief;
- результаты диагностики;
- Impact Level;
- открытые вопросы;
- затронутые области;
- список документов для проверки.

---

## Principal Architect → Product Owner

Передать:

- Architecture Review;
- найденные риски;
- рекомендации;
- необходимые изменения.

---

## Product Owner → Implementation Specification Agent

Передать:

- утверждённое архитектурное решение;
- выбранный вариант реализации;
- ограничения.

---

## Implementation Specification Agent → Developer

Передать:

- Implementation Specification;
- Architecture Decision;
- Definition of Done;
- ограничения;
- требования проверки.

---

## Developer → Code Reviewer

Передать:

- Implementation Report;
- список изменённых файлов;
- новые файлы;
- миграции;
- нерешённые вопросы.

---

## Code Reviewer → Knowledge Manager

После успешного завершения Code Review передать полный пакет:

- ARCHITECT BRIEF;
- ARCHITECT REVIEW;
- APPROVED DECISION;
- IMPLEMENTATION SPECIFICATION;
- IMPLEMENTATION REPORT;
- CODE REVIEW;
- список изменённых файлов.

Цель:

Knowledge Manager синхронизирует документацию на основе фактического изменения системы.

---

# Handoff Protocol

Каждый переход между ролями должен содержать:

1. Следующую роль.
2. Путь к её prompt.
3. Передаваемые артефакты.
4. Документы для изучения.
5. Цель следующего этапа.

Ответ предыдущей роли должен быть самодостаточным.

Следующий агент не должен требовать повторной передачи контекста вручную.

---

# Workflow Safety Rules

## Запрещено пропускать этапы

Нельзя:

System Architect

↓

Developer

---

## Запрещено

- принимать архитектурные решения во время кодирования;
- менять требования во время реализации;
- обновлять документацию без проверки фактического состояния системы;
- создавать новые источники истины.

---

# Final Principle

Архитектура определяет направление.

Specification определяет способ реализации.

Код является реализацией решения.

Документация является памятью системы.

AI Context Layer является картой проекта.

Все четыре слоя должны оставаться синхронизированными.
