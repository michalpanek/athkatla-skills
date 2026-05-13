---
name: ts-review
description: Opinionated TypeScript / JavaScript code review. Auto-detects the project's stack (Next.js, React, Drizzle, next-safe-action, Zod, Tailwind, Vitest, etc.) and applies ONLY rules for tools actually in use. Works for single-repo or monorepo. Single agent walks every applicable section sequentially.
when_to_use: User explicitly invokes /ts-review. Do NOT auto-apply on edits, file saves, or generic "review my code" requests — this skill is opt-in only.
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
- `CLAUDE.md` (root and any nested) — project conventions
- `.claude/rules/` — additional coding standards
- Existing test files — current testing patterns
- Any spec artifact for the current change (see Step 4 below)

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

## Step 4 — Holistic Pass (Standards + Spec axes)

@../../checklists/ts/holistic-pass.md

## Step 5 — Severity guidelines

@../../checklists/ts/severity-guidelines.md

## Step 6 — Report

Group findings by severity (CRITICAL > HIGH > MEDIUM > LOW). Number sequentially. Tag each with its domain (e.g. `[Architecture]`, `[Type Safety]`, `[UI]`, `[Holistic]`, `[Spec]`). For each finding: file path and line number, rule violated, suggested fix.

End with PASS / FAIL verdict. FAIL if any CRITICAL or HIGH finding (including `[Spec]`-tagged).

## Step 7 — Validation (if not already run)

After review, suggest running on changed files:
- Project formatter (Prettier / Biome)
- Project linter with `--max-warnings 0`
- Project type checker (`tsc --noEmit` or `pnpm typecheck`)
