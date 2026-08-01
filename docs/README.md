# LifeOS

Personal Life Operating System.

LifeOS is a long-term personal management system designed around structured data, domain rules, AI integration, and knowledge preservation.

The repository is currently named `finance_app`, but the project has expanded beyond finance into a broader LifeOS architecture.

---

# Project Philosophy

The project follows several core principles:

- Documentation is part of the system.
- Code, architecture, and documentation must remain synchronized.
- Business rules must have a single source of truth.
- Changes must preserve architectural integrity.
- AI tools are used as development team members with defined responsibilities.

---

# Architecture Overview

The system follows a layered architecture:


Presentation

↓

Application

↓

Domain

↓

Repository

↓

Data


Main architectural rules:

- Operation is the source of truth for financial data.
- AI does not modify user data directly.
- UI does not access the database directly.
- Financial logic belongs to the Domain layer.
- One fact must have one source of truth.

---

# Repository Structure


lib/

├── core/
│ Shared infrastructure components
│
├── domain/
│ Business logic and financial rules
│
├── data/
│ Database, repositories, external services
│
├── features/
│ User-facing application features
│
└── models/
Data models


---

# Documentation

Project documentation is stored in:


docs/


Main documents:

| Document | Purpose |
|---|---|
| `00_Master_Documentation.md` | Main project overview |
| `01_Current_State.md` | Current system state |
| `02_Architecture.md` | System architecture |
| `03_Domain_Model.md` | Domain entities and rules |
| `04_Financial_Rules.md` | Financial logic |
| `05_Database_Specification.md` | Database design |
| `06_AI_System.md` | AI subsystem |
| `07_Functional_Requirements.md` | Functional requirements |
| `08_Project_History.md` | Project evolution |
| `09_Development_Log.md` | Development history |
| `10_Roadmap.md` | Future plans |
| `11_Development_Guidelines.md` | Development rules |
| `12_Documentation_System.md` | Documentation principles |
| `13_AI_Team_Workflow.md` | AI-assisted development workflow |

---

# AI Development Workflow

The project uses multiple AI roles.

Workflow:


IDEA

↓

Context Analysis

↓

Architect Brief

↓

Principal Architect Review

↓

Implementation Specification

↓

Development

↓

Code Review

↓

Documentation Update

↓

DONE


AI roles:

- System Architect — architecture analysis and planning.
- Principal Architect — independent architecture review.
- Developer — implementation.
- Reviewer — code quality and architecture verification.
- Knowledge Manager — documentation synchronization.

AI-specific documentation:


docs/ai/


contains:

- project context;
- AI roles;
- workflow rules;
- documentation map;
- code map;
- change protocol;
- AI prompts.

---

# Development Rules

Before implementing changes:

1. Understand the current architecture.
2. Check affected documentation.
3. Prepare an implementation plan.
4. Confirm architectural compatibility.

After implementing changes:

1. Review code.
2. Update documentation.
3. Record changes in development history.

---

# Documentation First

Documentation is not a separate activity.

Every significant change must answer:

- Did architecture change?
- Did domain rules change?
- Did database structure change?
- Did AI behavior change?
- Did roadmap or project history change?

---

# Current Status

The project is under active development.

The repository contains:

- application source code;
- architecture documentation;
- AI development workflow;
- project history;
- future roadmap.

---

# Getting Started

For understanding the project, read in order:

1. `docs/00_Master_Documentation.md`
2. `docs/01_Current_State.md`
3. `docs/02_Architecture.md`
4. `docs/03_Domain_Model.md`
5. `docs/13_AI_Team_Workflow.md`

For AI agents:

Start with:


docs/ai/PROJECT_CONTEXT.md


Then use:


docs/ai/DOCUMENTATION_MAP.md
docs/ai/CODE_MAP.md


---

# Project Principle

> The goal is not only to build software.
> The goal is to build a system that can preserve its knowledge and evolve safely over time.