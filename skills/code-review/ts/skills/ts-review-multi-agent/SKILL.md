---
name: ts-review-multi-agent
description: Opinionated TypeScript / JavaScript code review using 6 parallel subagents. Auto-detects the project's stack (Next.js, React, Drizzle, next-safe-action, Zod, Tailwind, Vitest, etc.) and applies ONLY rules for tools actually in use. Works for single-repo or monorepo. Use for large PRs spanning multiple domains.
when_to_use: User explicitly invokes /ts-review-multi-agent. Do NOT auto-apply on edits or generic "review my code" requests — this skill is opt-in only.
argument-hint: "[optional: file path or diff range, e.g. HEAD~3..HEAD]"
disable-model-invocation: true
---

# TypeScript / JavaScript Code Review (multi-agent)

Dispatch 6 parallel subagents. Four follow strict scoped checklists; a fifth holistic agent reviews the entire changeset without a checklist to catch emergent issues; a sixth reviews through the clean-code lens using the `clean-code` skill. Aggregate findings into one severity-grouped report. **First detect the project's stack and only apply rules for tools actually present — all subagents respect the same skip-rules.**

## Step 0 — Detect stack

@../../checklists/ts/00-stack-detection.md

Print the stack summary before continuing. Include the same stack-summary + skip-rules verbatim in the prompts of agents 1-5 (the `{STACK_SUMMARY}` slot) so they apply consistent skip logic. Agent 6 reviews stack-agnostic clean-code concerns and does not receive it.

## Step 1 — Gather changes

```bash
git diff --name-only HEAD
git status --short
git diff HEAD
```

If `$ARGUMENTS` is provided, treat as diff range or file list. Otherwise default to uncommitted changes on `HEAD`.

Filter to `.ts`, `.tsx`, `.js`, `.jsx`. If no files match, report "No TypeScript files to review" and stop.

## Step 2 — Dispatch 6 subagents IN PARALLEL

All 6 in a single message with parallel `Agent` tool calls.

Each scoped agent (1-4) receives:
- The agent-group checklist (referenced below)
- The severity guidelines
- The changed-files list and full diff
- The "Scoped Subagent Prompt Template" at the end of this file (agent 5 uses the holistic prompt from `@../../checklists/ts/holistic-pass.md` instead; agent 6 uses the "Clean-Code Subagent Prompt Template")

### Agent 1 — Architecture & Data
Scope: Architecture & Layering, Server Actions (next-safe-action), Drizzle ORM & Database, Schema & Validation (Zod), Data Fetching & Caching, Database Operations, Next.js App Router.
Checklist:
@../../checklists/ts/01-architecture-data.md

### Agent 2 — Type Safety & Code Quality
Scope: Error Handling, TypeScript Type Safety, Code Style, Naming Precision.
Checklist:
@../../checklists/ts/02-type-safety-code-quality.md

### Agent 3 — UI & Components
Scope: React Component Patterns, Semantic HTML & Accessibility, Tailwind & CSS, Data Table Patterns.
Checklist:
@../../checklists/ts/03-ui-components.md

### Agent 4 — Cross-cutting
Scope: Authentication & Authorization, Logging, Tests, PR & Commit Standards.
Checklist:
@../../checklists/ts/04-cross-cutting.md

### Agent 5 — Holistic Review (no checklist)
Scope: cross-file consistency, design coherence, integration points, subtle bugs, spec fidelity.
Prompt template + axes definition + spec-discovery guidance:
@../../checklists/ts/holistic-pass.md

### Agent 6 — Clean Code (uses the clean-code skill)
Scope: readability and maintainability only — intention-revealing naming, self-explanatory code instead of comments, declarative/functional patterns over nested if/else, clear code structure, small focused functions and files, DRY.
Prompt template: see "Clean-Code Subagent Prompt Template" at the end of this file.
Expected overlap with Agent 2's Naming Precision / Code Style items is fine; aggregation keeps both.

### Severity guidelines (all agents)
@../../checklists/ts/severity-guidelines.md

### Conflict resolutions (context for all agents)
@../../checklists/ts/conflict-resolutions.md

## Step 3 — Aggregate results

After all 6 agents return:
1. Collect findings from all agents (including `[Holistic]`, `[Spec]`, and `[Clean Code]` insights)
2. Number sequentially starting from 1
3. Group by severity: CRITICAL > HIGH > MEDIUM > LOW
4. Tag each finding with its domain in brackets. Preserve `[Holistic]`, `[Spec]`, `[Structure]`, and `[Clean Code]` tags verbatim.
5. Do NOT aggressively deduplicate. When in doubt, INCLUDE the finding.
6. Keep both versions when a holistic finding overlaps with a checklist finding.

## Step 4 — Final verdict

End with PASS / FAIL. FAIL if any CRITICAL or HIGH finding, including `[Spec]`-tagged.

## Scoped Subagent Prompt Template

Use this when constructing each scoped subagent's prompt. Replace `{AGENT_GROUP_NAME}`, `{STACK_SUMMARY}`, `{CHECKLIST}`, `{CHANGED_FILES}`, and `{DIFF}`.

```
You are a specialized TypeScript/React code reviewer focusing EXCLUSIVELY on: {AGENT_GROUP_NAME}.

STRICT SCOPING: Review ONLY against the checklist items provided below. Do NOT review items outside your assigned scope. Other agents are handling those sections.

## Stack Summary & Skip Rules
{STACK_SUMMARY}

## Changed Files
{CHANGED_FILES}

## Full Diff
{DIFF}

## Your Checklist
{CHECKLIST}

## Severity Guidelines
<inline content of @../../checklists/ts/severity-guidelines.md>

## Instructions
1. Read each changed/new TypeScript file in full (not just the diff).
2. Check EVERY applicable checklist item against EVERY changed file.
3. For each finding, report:
   - Severity (CRITICAL / HIGH / MEDIUM / LOW)
   - Domain tag in brackets matching checklist section name
   - File path and line number
   - Issue description referencing the specific checklist rule
   - Suggested fix
4. Group findings by severity.
5. If no issues found in your scope, report "No issues found in {AGENT_GROUP_NAME}".

Structural red flags (beyond your checklist): if a change in your files clearly worsens structure — sprawls a file well past ~1000 lines, bolts a special-case branch onto an unrelated flow, or adds a wrapper / abstraction that only relocates complexity — note it briefly tagged `[Structure]`, even though it is outside your scoped items. Keep this to genuine structural problems, not style; the holistic agent owns the deep structural pass.
```

## Clean-Code Subagent Prompt Template

Use this for Agent 6. Replace `{CHANGED_FILES}` and `{DIFF}`.

```
You are a clean-code reviewer focusing EXCLUSIVELY on code clarity and maintainability. You do NOT review stack-specific rules, architecture, security, or tests — other agents own those.

First, invoke the `clean-code` skill via the Skill tool and apply its standards and severity rubric to the changed files. If the skill is not available, apply this fallback checklist instead:
- Intention-revealing names for variables, functions, types, files. Flag vague names (data, info, temp, handle, process) and misleading names.
- Self-explanatory code instead of comments. A comment explaining WHAT the code does is a naming/structure smell; comments only earn their place stating constraints the code cannot express.
- Declarative / functional style over imperative nesting: early returns over nested if/else chains, map/filter/reduce over index loops where it reads better, no flag-argument branching.
- Clear structure: one responsibility per function and file; related logic colocated; no grab-bag utils additions.
- Size: flag functions over ~50 lines and files over ~800 lines, or any function/file the change makes meaningfully harder to follow.
- DRY: duplicated or near-identical blocks introduced or extended by this change.

## Changed Files
{CHANGED_FILES}

## Full Diff
{DIFF}

## Severity Guidelines
<inline content of @../../checklists/ts/severity-guidelines.md>

## Instructions
1. Read each changed/new file in full (not just the diff).
2. Judge only what this change introduces or worsens; do not demand refactors of untouched legacy code.
3. For each finding, report:
   - Severity (CRITICAL / HIGH / MEDIUM / LOW)
   - Tag `[Clean Code]`
   - File path and line number
   - Issue description naming the violated principle
   - Suggested fix (show the cleaner version when short)
4. Group findings by severity.
5. If no issues found, report "No issues found in Clean Code".
```
