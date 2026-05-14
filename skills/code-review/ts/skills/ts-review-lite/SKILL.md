---
name: ts-review-lite
description: Fast, single-pass TypeScript / JavaScript code review on uncommitted changes. Compressed sibling of `ts-review` — same domains, fewer items, designed to fit inside ~80 model turns. Use for local pre-commit sanity checks, CI runs on budget-constrained models, or a quick second pass after fixing obvious issues. For final pre-merge review on a high-risk PR, use the full `ts-review` skill instead.
when_to_use: User explicitly invokes /ts-review-lite. Triggers include "fast review", "lite TS review", "quick TS sanity check", "budget review of TS changes". Do NOT auto-apply on edits, file saves, or generic "review my code" requests — this skill is opt-in only.
argument-hint: "[optional: file path or diff range, e.g. HEAD~3..HEAD]"
disable-model-invocation: true
---

# TypeScript / JavaScript Code Review — LITE (single-agent, fast)

Compressed sibling of `ts-review`. Same domains, fewer items, single-pass execution. Targets ~20-min wallclock and ~3-4× fewer model turns vs the full review.

## When to Use

- Local pre-commit / pre-PR sanity check, faster feedback than the full review
- CI review where the full skill blows the token / time budget
- A quick second pass after applying obvious fixes, before running the full review on a final "ship-ready" pass

## When NOT to Use

- Final pre-merge review on a high-risk PR — use full `ts-review`
- Non-TS/JS code — use the language-specific reviewer (`java-review` for Java, etc.)
- Pure CSS/HTML, config-only, generated migration files

## Execution Model (CRITICAL — read first)

To stay under ~80 model turns:

1. **One discovery batch.** Run `git diff --name-only HEAD`, `git status --short`, `git diff HEAD` in a single response.
2. **One read batch.** Issue ALL `Read` tool calls for changed `.ts`/`.tsx`/`.js`/`.jsx` files in a single parallel batch. Do not interleave reads with analysis.
3. **One in-head pass.** After reads return, walk every applicable checklist item against every file in a single reasoning pass. Do not re-open files.
4. **One report.** Emit findings as a single markdown report grouped by severity. No iterative refinement.

If the diff includes >25 changed TS files, stop and tell the user to narrow scope (path filter, base ref) rather than try to finish a degraded review.

## Step 0 — Detect stack (light pass)

@../../checklists/ts/00-stack-detection.md

Print the stack summary once at the top of the report. Skip checklist items whose tools are NOT in the detected set.

## Pre-Review Context (load once, in the same batch as reads)

- `CLAUDE.md` (root) — project conventions
- `AGENTS.md` if present
- `.claude/rules/` — any project-specific rule files
- Any `CLAUDE.md` nested in a changed feature folder

## Compressed Checklist (apply ALL applicable items)

### 1. Architecture & Data (server actions, ORM, validation, error handling)

- DB-access wrapper (`executeQuery` or equivalent) on every DB call; never raw try/catch around `db.*` in repositories or actions.
- Server actions go through an authenticated action client (`next-safe-action` or equivalent) with role-based authz.
- Domain-specific error type (e.g. `ActionError`) thrown with context object `{ action, resourceId }` — never bare `Error`.
- ORM conventions: monetary amounts as INTEGER cents; UUID PKs; centralized timestamp spread; ISO-string timestamps (`.toISOString()`).
- Migrations: never hand-edited. Schema changes paired with the project's migration generator.
- Zod (or detected validation lib) at all system boundaries (forms, API routes, URL params). Types derived via `z.infer` / schema-driven factories — no duplicate manual types.
- `unstableCache` (or detected cache wrapper) + cache tags on every query function; cache keys include all query params.
- No silent error swallow (`catch { return null }`); use the project's structured logger. No `console.log`; `console.error` only for true errors.

### 2. TypeScript Type Safety

- No `any`. No `as SomeType` / `as unknown as Type` double casts. No non-null `!`.
- No `ReturnType<typeof fn>` — derive from schema or define a real type.
- Inline types over named `interface` / `type` declarations unless shared cross-file.
- Discriminated unions over boolean flags for variants (`{ status: 'success', data } | { status: 'error', error }`).
- Exhaustive `switch` with `value satisfies never` default.
- `Record<string, never>` for empty objects; `Record<string, unknown>` for unknown objects.
- `Array<T>` (not `T[]`); `ReadonlyArray<T>` where appropriate.
- `import type` for type-only imports.
- No suppressions (`@ts-ignore`, `@ts-expect-error`, `eslint-disable`) without an inline justification + ticket reference (Jira / Linear / GitHub Issue).

### 3. Code Style

- Arrow functions only. Never `function` declarations.
- `async`/`await` only. Never `.then()` / `.catch()` / `.finally()`.
- Named exports only. No `export default`.
- Early returns over nested `if/else`. Always brace `if`.
- Immutability: no `let` where `const` + composition works; no `.push()` / `.shift()` / spread-mutate-in-`reduce`. `.map()` callbacks pure.
- Declarative over imperative — `map` / `filter` / `reduce` / `some` / `flat`, not `for` loops.
- `map` only when you use the return value; otherwise `forEach`.
- No `index.ts` / barrel files.
- No `console.log` in committed code.
- Function with 3+ args → object parameter (`fn({ a, b, c })`).

### 4. React / Next.js

- Functional components only. Props destructured in signature. Prefer `Readonly<Props>`.
- Import named React types (`import { FC }`), not `React.FC` / `React.*` namespace.
- No inline lambdas in JSX when they cause re-renders on memoized children — extract to const.
- No component definitions inside other components.
- `useId()` for label↔input / form↔button binding. Every `<label htmlFor="x">` has a matching `id="x"`.
- `useWatch()` (or detected form-state lib equivalent) for reactive form values, not `useState(form.getValues(...))`.
- Cleanup all `window` / `document` listeners in effect teardown.
- No `index` as list `key`. Use a stable id. Never `key={Math.random()}`.
- Loading state: `isExecuting` for disable, `isPending` for spinner.
- Dirty-check (`Object.keys(form.formState.dirtyFields).length > 0`) before destructive discard.
- Confirmation dialog for destructive actions.

### 5. Naming

- Components `PascalCase`, functions `camelCase`, constants `UPPER_SNAKE_CASE` (primitives only — object/maps `camelCase`).
- Custom hooks `use*` prefix; no `useGet*`.
- Callbacks named for the action (`submitForm`, `deleteItem`) — no `handle*` prefix. Callback props `on{Event}` (`onDelete`, `onSelect`).
- Domain-qualified IDs (`customerId`, `orderId`), never bare `id` when multiple entities are in scope.
- Acronyms: first letter only capitalized (`ApiResponse`, `userId`).
- Boolean names positive, no "not" (`isValid`, not `isInvalid` unless that IS the domain).
- No `I` prefix on types, no `Type` / `Interface` suffix.

### 6. Tests (only if test files in diff)

- Co-located: `Button.tsx` → `Button.test.tsx`.
- Public API, not implementation details.
- Realistic data; reuse fixtures over re-inventing.
- No shared mutable state across tests; use per-test fixtures.

## Severity Mapping

| Severity | What counts |
|---|---|
| CRITICAL | Security holes, data loss, broken auth, raw `any` on external boundary, missing validation on user input, DB-access wrapper bypassed in a path that hits prod DB. |
| HIGH | Pattern violations that break project conventions and will be flagged in human review: `console.log`, `.then()` / `.catch()`, missing DB-access wrapper, `as SomeType` cast, default export, `function` declaration, mutation, `useEffect` with uncleaned listener, `index` key. |
| MEDIUM | Style / structure: `interface` declarations, missing braces, naming violations, missing `useId`, sub-component defined inside parent, missing early return. |
| LOW | Cosmetic: shorthand object syntax, magic numbers, redundant wrappers, full names in lambdas. |

## Output Format

Single markdown report, in order:

1. **Stack detected** — one-line bullet list of frameworks identified.
2. **Files reviewed** — `n` files, listed.
3. **Findings** — grouped by severity (CRITICAL → HIGH → MEDIUM → LOW). Each finding:
   ```
   - [`{SEVERITY}` · {domain}] `path:line` — {rule violated}
     {1-sentence explanation}
     Fix: {1-line concrete suggestion, or short code block if non-trivial}
   ```
4. **Verdict** — `✅ PASS` or `❌ FAIL` (FAIL iff any CRITICAL or HIGH).
5. **Next steps** — if PASS, suggest running the project's validators (typecheck, format, lint, test scripts detected in Step 0). If FAIL, list the top 3 fixes by impact.

Do NOT post inline PR comments from this skill — that is the CI workflow's job. This skill outputs to stdout / chat for local review.

## Common Mistakes While Running This Skill

- **Reading files one at a time instead of in parallel batch.** This is the #1 cause of turn-cap exhaustion. Issue all `Read` calls in the same response.
- **Re-opening files between checklist sections.** Hold the full text in working context after the read batch.
- **Drilling into framework-internal files** (`node_modules`, `.next/`, generated migrations). Filter the diff first.
- **Producing inline patch suggestions for every LOW finding.** LOW gets a one-liner only.
- **Falling back to the full skill mid-run.** If diff is too big, stop and report; do not switch skills.

## Quick Reference (most commonly violated items)

| Smell | Fix |
|---|---|
| `console.log(...)` | structured logger (e.g. `getLogger().error(...)`) or remove |
| `.then(...).catch(...)` | `try { await ... } catch (e) { ... }` with DB-access wrapper |
| `: any` | real type, generic, or `unknown` + Zod parse |
| `export default ...` | `export const ...` |
| `function foo()` | `const foo = () =>` |
| `interface Props {...}` | inline `(props: { a: string, b: number })` |
| `let x = ...; if (cond) x = ...` | `const x = cond ? ... : ...` |
| `array.map((_, i) => <Row key={i} />)` | use stable id |
| `useEffect(() => { window.addEventListener(...) }, [])` | return cleanup function |
| `handleSubmit` | `submitForm` |
| missing DB-access wrapper in a repository function | wrap the DB call |
