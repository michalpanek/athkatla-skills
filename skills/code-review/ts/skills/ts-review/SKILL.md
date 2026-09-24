---
name: ts-review
description: Opinionated TypeScript / JavaScript code review. Detects the project's stack and applies only the rules that fit. Single agent walks every checklist section sequentially.
argument-hint: "[optional: file path or diff range, e.g. HEAD~3..HEAD]"
disable-model-invocation: true
---

# TypeScript / JavaScript Code Review (single-agent)

Walk every checklist section sequentially against the changed code and report findings grouped by severity. **First detect the project's stack and only apply rules for tools actually present.**

## Step 0 — Detect stack

@../../checklists/ts/00-stack-detection.md

Print the stack summary before continuing. All subsequent steps respect the skip-rules from Step 0.

## Step 1 — Gather changes

```bash
git diff --name-only HEAD
git status --short
git diff HEAD
```

If `$ARGUMENTS` is provided, treat it as the diff range or file list to review. Otherwise default to uncommitted changes on `HEAD`.

Filter to `.ts`, `.tsx`, `.js`, `.jsx`. If no TypeScript/React files changed, report "No TypeScript files to review" and stop.

## Step 2 — Load project context

Read these if they exist:
- `CLAUDE.md` and `AGENTS.md` (root and any nested) — project conventions
- Every file in `.claude/rules/` and `.agents/rules/`, and each project skill or doc they route to for TypeScript, React, naming, tests, or review
- Existing test files — current testing patterns
- Any spec artifact for the current change (see Step 5 below)

A project rule wins over a checklist item when they conflict. Move to Step 3 once every existing item above has been read.

## Step 3 — Walk the checklist

Apply every applicable item from each section against every changed file. Read entire changed files (not just the diff hunks).

### Architecture, Data, Server Actions
@../../checklists/ts/01-architecture-data.md

### Type Safety, Code Style, Naming
@../../checklists/ts/02-type-safety-code-quality.md

### UI Components, Accessibility, Tailwind
@../../checklists/ts/03-ui-components.md

### Auth, Logging, Tests, PR/Commit Standards
@../../checklists/ts/04-cross-cutting.md

### Conflict Resolutions (project conventions vs general TS best-practices)
@../../checklists/ts/conflict-resolutions.md

## Step 4 — Clean-Code Pass (clarity, maintainability)

Invoke `athkatla-skills:clean-code` via the Skill tool. Apply its standards and severity rubric to every changed file. Judge only what this change introduces or worsens. If the skill is not available, apply this fallback:
@../../checklists/ts/clean-code.md

Then run the comment review scan on every comment line the change adds or edits, tests included. Implementer agents add comments in bulk, so expect many.
@../../../clean-code/skills/clean-code/references/comments.md

Tag findings `[Clean Code]`.

## Step 5 — Holistic Pass (Standards + Spec axes)

@../../checklists/ts/holistic-pass.md

## Step 6 — Severity guidelines

@../../checklists/ts/severity-guidelines.md

## Step 7 — Report

Group findings by severity (CRITICAL > HIGH > MEDIUM > LOW). Number sequentially. Tag each with its domain (e.g. `[Architecture]`, `[Type Safety]`, `[UI]`, `[Clean Code]`, `[Holistic]`, `[Spec]`). For each finding: file path and line number, rule violated, suggested fix.

End with PASS / FAIL verdict. FAIL if any CRITICAL or HIGH finding (including `[Spec]`-tagged).

## Step 8 — Validation (if not already run)

After review, suggest running on changed files:
- Project formatter (Prettier / Biome)
- Project linter with `--max-warnings 0`
- Project type checker (`tsc --noEmit` or `pnpm typecheck`)
