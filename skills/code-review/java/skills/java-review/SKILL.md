---
name: java-review
description: Single-agent Java or Kotlin Spring Boot code review. Detects the project's stack, applies only the relevant rules, then runs clean-code and test-value passes.
argument-hint: "[optional: file path or diff range, e.g. HEAD~3..HEAD]"
disable-model-invocation: true
---

# Java Spring Boot Code Review (single-agent)

Walk every checklist section sequentially against the changed code and report findings grouped by severity. **First detect the project's stack and only apply rules for tools actually present.**

## Step 0 — Detect stack

@../../checklists/java/00-stack-detection.md

Print the stack summary before continuing. All subsequent steps respect the skip-rules from Step 0.

## Step 1 — Gather changes

Choose the change source:

- **Committed changes.** `$ARGUMENTS` is a commit range `A..B`, for example `HEAD~3..HEAD`. Run `git diff --name-only A..B` and `git diff A..B`. Read each file at commit `B` with `git show B:<path>`. The working tree can differ from `B`, so do not read it. Set `{FILE_SOURCE}` to "commit `B` (`git show B:<path>`)".
- **Local changes.** `$ARGUMENTS` is empty or a file list. Run `git diff --name-only HEAD`, `git status --short` and `git diff HEAD`. These show staged, unstaged and untracked files. Read each file from the working tree. Set `{FILE_SOURCE}` to "the working tree".

Print the change source before you filter.

Filter to `.java`, `.kt`, `.kts` and `.groovy` (Spock specs). Keep test resource files (`src/test/resources/**`) in view: the Test Value gate needs the fixtures. If no file matches, report "No Java or Kotlin files to review" and stop.

If a `.kt` or `.kts` file matches, read `@../../checklists/java/kotlin-reading.md`. Apply every checklist rule to Kotlin files through it. Print the count before Step 2: "Reviewing N Java, M Kotlin, K Groovy files".

## Step 2 — Load project context

Read these if they exist:
- `CLAUDE.md` and `AGENTS.md` (root and any nested) — project conventions
- Every file in `.claude/rules/` and `.agents/rules/`, and each project skill or doc they route to for Java code, naming, tests, or review
- Existing test files (e.g. integration test base classes) — current testing patterns
- Any spec artifact for the current change (see Step 5 below)

A project rule wins over a checklist item when they conflict. Move to Step 3 once every existing item above has been read.

## Step 3 — Walk the checklist

Apply every applicable item from each section against every changed file. Read each changed file in full from `{FILE_SOURCE}` (Step 1), not only the diff hunks.

### Architecture, Spring Config, Package Placement, Configuration, Dependencies
@../../checklists/java/01-architecture-spring-config.md

### Entity & Persistence, Migrations, JPA, DTOs/Records, Mappers, Identity, Enums
@../../checklists/java/02-data-layer-persistence.md

### Code Style, Naming, Optional/Type Patterns, Validation, Exception Handling
@../../checklists/java/03-code-quality-type-safety.md

### Logging, Messaging, Async, Scheduled Jobs, SOAP, Email, Tests, PR/Commit Standards
@../../checklists/java/04-cross-cutting-concerns.md

## Step 4 — Clean-Code Pass (clarity, maintainability, test value)

Apply this checklist to every changed file. Use the Step 6 severity guidelines. The `athkatla-skills:clean-code` skill covers TypeScript only, so do not invoke it:
@../../checklists/java/clean-code.md

Then run the Test Value gate on every new test in the change. A test that fails the gate gets only the removal finding: drop its Step 3 test-style findings.
@../../checklists/java/test-value.md

Run the comment review scan on every comment line the change adds or edits, tests included. Implementer agents add comments in bulk, so expect many.
@../../../clean-code/skills/clean-code/references/comments.md

Check every new or renamed method name against the "Methods start with a verb" item in Naming Precision (Step 3, `03-code-quality-type-safety.md`). Reviewers report this miss often.

Tag findings `[Clean Code]` or `[Test Value]`.

## Step 5 — Holistic Pass (Standards + Spec axes)

@../../checklists/java/holistic-pass.md

## Step 6 — Severity guidelines

@../../checklists/java/severity-guidelines.md

## Step 7 — Report

Group findings by severity (CRITICAL > HIGH > MEDIUM > LOW). Number sequentially. Tag each with its domain (e.g. `[Architecture]`, `[Spring Boot]`, `[JPA]`, `[Exception Handling]`, `[Clean Code]`, `[Test Value]`, `[Holistic]`, `[Spec]`). For each finding: file path and line number, rule violated, suggested fix.

End with PASS / FAIL verdict. FAIL if any CRITICAL or HIGH finding (including `[Spec]`-tagged).
