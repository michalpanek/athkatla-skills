---
name: java-review
description: Single-agent Java Spring Boot code review. Detects the project's stack, applies only the relevant rules, then runs clean-code and test-value passes.
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

Filter to `.java` and `.groovy` (Spock specs). Keep test resource files (`src/test/resources/**`) in view: the Test Value gate needs the fixtures. If no `.java` or `.groovy` files changed, report "No Java files to review" and stop.

## Step 2 — Load project context

Read these if they exist:
- `CLAUDE.md` (root and any nested) — project conventions
- `.claude/rules/java.md` — additional Java/Spring Boot standards
- Existing test files (e.g. integration test base classes) — current testing patterns
- Any spec artifact for the current change (see Step 5 below)

Move to Step 3 once every existing item above has been read.

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

## Step 4 — Clean-Code Pass (clarity, maintainability, test value)

Invoke `athkatla-skills:clean-code` via the Skill tool. Apply its standards and severity rubric to every changed file. If the skill is not available, apply this fallback:
@../../checklists/java/clean-code.md

Then run the Test Value gate on every new test in the change. A test that fails the gate gets only the removal finding: drop its Step 3 test-style findings.
@../../checklists/java/test-value.md

Check every new or renamed method name against the "Methods start with a verb" item in Naming Precision (Step 3, `03-code-quality-type-safety.md`). Reviewers report this miss often.

Tag findings `[Clean Code]` or `[Test Value]`.

## Step 5 — Holistic Pass (Standards + Spec axes)

@../../checklists/java/holistic-pass.md

## Step 6 — Severity guidelines

@../../checklists/java/severity-guidelines.md

## Step 7 — Report

Group findings by severity (CRITICAL > HIGH > MEDIUM > LOW). Number sequentially. Tag each with its domain (e.g. `[Architecture]`, `[Spring Boot]`, `[JPA]`, `[Exception Handling]`, `[Clean Code]`, `[Test Value]`, `[Holistic]`, `[Spec]`). For each finding: file path and line number, rule violated, suggested fix.

End with PASS / FAIL verdict. FAIL if any CRITICAL or HIGH finding (including `[Spec]`-tagged).
