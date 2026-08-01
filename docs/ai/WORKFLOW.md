# AI DEVELOPMENT WORKFLOW

Версия:

1.0

Назначение:

Этот документ описывает полный жизненный цикл разработки с использованием AI-агентов.

---

# Основной принцип

AI работает как команда специалистов.

Каждый этап имеет:

- входные данные;
- ответственную роль;
- результат;
- следующий этап.

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

- изучить Context Layer;
- изучить документацию;
- изучить код;
- определить влияние.

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
- найти риски;
- проверить архитектуру.

Результат:

ARCHITECT REVIEW

Возможные статусы:

Approved

Need Changes

Cannot Review

---

## Stage 4

PRODUCT DECISION

Ответственный:

Product Owner

Действия:

- принять решение;
- утвердить направление.

Результат:

APPROVED DECISION

---

## Stage 5

IMPLEMENTATION SPECIFICATION

Ответственный:

Implementation Specification Agent

Действия:

Создать:

- список изменений;
- затронутые файлы;
- план реализации;
- критерии проверки.

Результат:

IMPLEMENTATION SPECIFICATION

---

## Stage 6

DEVELOPMENT

Ответственный:

Developer

Действия:

- реализовать спецификацию;
- написать код;
- добавить тесты.

Ограничение:

Developer не меняет архитектуру.

Результат:

IMPLEMENTED CHANGE

---

## Stage 7

CODE REVIEW

Ответственный:

Reviewer

Действия:

Проверить:

- код;
- архитектуру;
- требования;
- тесты.

Результат:

CODE REVIEW

Статусы:

Approved

Changes Required

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
- историю;
- AI Context Layer.

Результат:

DOCUMENTATION SYNCHRONIZED

---

## Stage 9

DONE

Условия завершения:

☐ Код принят

☐ Review пройден

☐ Документация обновлена

☐ Context Layer синхронизирован

---

# Handoff Rules

## System Architect → Principal Architect

Передать:

- Architect Brief;
- риски;
- открытые вопросы;
- Impact Level.

---

## Principal Architect → Product Owner

Передать:

- Architecture Review;
- решение;
- рекомендации.

---

## Product Owner → Implementation

Передать:

- утверждённое решение.

---

## Implementation → Developer

Передать:

- техническую спецификацию.

---

## Reviewer → Knowledge Manager

После успешного завершения Code Review передать полный пакет изменений:

- ARCHITECT BRIEF
- ARCHITECT REVIEW
- IMPLEMENTATION SPECIFICATION
- DEVELOPMENT PLAN
- PLAN REVIEW
- IMPLEMENTATION REPORT
- CODE REVIEW

Цель:

Knowledge Manager синхронизирует документацию
на основе полного набора утверждённых артефактов.

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
- обновлять документацию задним числом без проверки.

---

# Final Principle

Код является реализацией решения.

Документация является памятью системы.

AI Context Layer является картой.

Все три должны оставаться синхронизированными.
