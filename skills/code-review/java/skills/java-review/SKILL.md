---
name: java-review
description: Opinionated Java code review (Spring Boot-focused). Auto-detects the project's stack (Spring Boot starters, JPA, Lombok, Vavr, Resilience4j, Spock, RabbitMQ, etc.) and applies ONLY rules for tools actually in use. Works for single-module or multi-module Maven/Gradle projects. Step 0 stack detection verifies Spring Boot presence — non-Spring-Boot Java projects get a heads-up before review. Single agent walks every applicable section sequentially.
when_to_use: User explicitly invokes /java-review. Do NOT auto-apply on edits, file saves, or generic "review my code" requests — this skill is opt-in only.
argument-hint: "[optional: file path or diff range, e.g. HEAD~3..HEAD]"
disable-model-invocation: true
---

# Java Spring Boot Code Review (single-agent)

Walk every checklist section sequentially against the changed code and report findings grouped by severity. **First detect the project's stack and only apply rules for tools actually present.**

## Step 0 — Detect stack

@../../checklists/java/00-stack-detection.md

Print the stack summary before continuing. All subsequent steps respect the skip-rules from Step 0.

## Step 1 — Gather changes

```bash
git diff --name-only HEAD
git status --short
git diff HEAD
```

If `$ARGUMENTS` is provided, treat it as the diff range or file list to review. Otherwise default to uncommitted changes on `HEAD`.

Filter to `.java`. If no Java files changed, report "No Java files to review" and stop.

## Step 2 — Load project context

Read these if they exist:
- `CLAUDE.md` (root and any nested) — project conventions
- `.claude/rules/java.md` — additional Java/Spring Boot standards
- Existing test files (e.g. integration test base classes) — current testing patterns
- Any spec artifact for the current change (see Step 4 below)

## Step 3 — Walk the checklist

Apply every applicable item from each section against every changed file. Read entire changed files (not just the diff hunks).

### Architecture, Spring Config, Package Placement, Configuration, Dependencies
@../../checklists/java/01-architecture-spring-config.md

### Entity & Persistence, Migrations, JPA, DTOs/Records, Mappers, Identity, Enums
@../../checklists/java/02-data-layer-persistence.md

### Code Style, Naming, Optional/Type Patterns, Validation, Exception Handling
@../../checklists/java/03-code-quality-type-safety.md

### Logging, Messaging, Async, Scheduled Jobs, SOAP, Email, Tests, PR/Commit Standards
@../../checklists/java/04-cross-cutting-concerns.md

## Step 4 — Holistic Pass (Standards + Spec axes)

@../../checklists/java/holistic-pass.md

## Step 5 — Severity guidelines

@../../checklists/java/severity-guidelines.md

## Step 6 — Report

Group findings by severity (CRITICAL > HIGH > MEDIUM > LOW). Number sequentially. Tag each with its domain (e.g. `[Architecture]`, `[Spring Boot]`, `[JPA]`, `[Exception Handling]`, `[Holistic]`, `[Spec]`). For each finding: file path and line number, rule violated, suggested fix.

End with PASS / FAIL verdict. FAIL if any CRITICAL or HIGH finding (including `[Spec]`-tagged).
