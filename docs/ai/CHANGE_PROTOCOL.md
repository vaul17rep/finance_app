# CHANGE PROTOCOL

Назначение:

Правила синхронизации документации после изменений кода.

Документация является частью системы.

После каждого изменения необходимо определить затронутые документы.

---

# General Rule

Любое изменение должно пройти проверку:

1. Код изменён.
2. Определены затронутые области.
3. Проверены связанные документы.
4. После успешного Code Review документация обновлена Knowledge Manager.
5. Изменение записано в историю.

---

# Change Impact Map

## Architecture Change

Проверить:

- docs/02_Architecture.md
- docs/12_Documentation_System.md
- docs/13_AI_Team_Workflow.md

---

## Domain Change

Проверить:

- docs/03_Domain_Model.md
- docs/04_Financial_Rules.md

---

## Database Change

Проверить:

- docs/05_Database_Specification.md
- docs/03_Domain_Model.md

---

## Feature Change

Проверить:

- docs/07_Functional_Requirements.md
- docs/01_Current_State.md

---

## AI Workflow Change

Проверить:

- docs/06_AI_System.md
- docs/13_AI_Team_Workflow.md
- docs/ai/*

---

## Major Project Change

Проверить:

- docs/00_Master_Documentation.md
- docs/08_Project_History.md
- docs/09_Development_Log.md
- docs/10_Roadmap

---

# Responsibility

Developer:

Сообщает какие файлы изменены.

Reviewer:

Проверяет соответствие.

Knowledge Manager:

Обновляет документацию.

---

# Completion Criteria

Изменение считается завершённым только если:

☐ Код обновлён

☐ Тесты пройдены

☐ Документы проверены

☐ История обновлена

☐ Context Layer синхронизирован

Статус:

DONE
