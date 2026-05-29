---
name: ts-review-multi-agent
description: Opinionated TypeScript / JavaScript code review using 5 parallel subagents. Auto-detects the project's stack (Next.js, React, Drizzle, next-safe-action, Zod, Tailwind, Vitest, etc.) and applies ONLY rules for tools actually in use. Works for single-repo or monorepo. Use for large PRs spanning multiple domains.
when_to_use: User explicitly invokes /ts-review-multi-agent. Do NOT auto-apply on edits or generic "review my code" requests — this skill is opt-in only.
argument-hint: "[optional: file path or diff range, e.g. HEAD~3..HEAD]"
disable-model-invocation: true
---

# TypeScript / JavaScript Code Review (multi-agent)

Dispatch 5 parallel subagents. Four follow strict scoped checklists; a fifth holistic agent reviews the entire changeset without a checklist to catch emergent issues. Aggregate findings into one severity-grouped report. **First detect the project's stack and only apply rules for tools actually present — all subagents respect the same skip-rules.**

## Step 0 — Detect stack

@../../checklists/ts/00-stack-detection.md

Print the stack summary before continuing. Include the same stack-summary + skip-rules verbatim in every subagent prompt so all 5 agents apply consistent skip logic.

## Step 1 — Gather changes

```bash
git diff --name-only HEAD
git status --short
git diff HEAD
```

If `$ARGUMENTS` is provided, treat as diff range or file list. Otherwise default to uncommitted changes on `HEAD`.

Filter to `.ts`, `.tsx`, `.js`, `.jsx`. If no files match, report "No TypeScript files to review" and stop.

## Step 2 — Dispatch 5 subagents IN PARALLEL

All 5 in a single message with parallel `Agent` tool calls.

Each scoped agent (1-4) receives:
- The agent-group checklist (referenced below)
- The severity guidelines
- The changed-files list and full diff
- The scoped subagent prompt template (in `@../../checklists/ts/holistic-pass.md` for the holistic prompt; for scoped agents, use the inline template at the end of this file)

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

### Severity guidelines (all agents)
@../../checklists/ts/severity-guidelines.md

### Conflict resolutions (context for all agents)
@../../checklists/ts/conflict-resolutions.md

## Step 3 — Aggregate results

After all 5 agents return:
1. Collect findings from all agents (including `[Holistic]` and `[Spec]` insights)
2. Number sequentially starting from 1
3. Group by severity: CRITICAL > HIGH > MEDIUM > LOW
4. Tag each finding with its domain in brackets. Preserve `[Holistic]` and `[Spec]` tags verbatim.
5. Do NOT aggressively deduplicate. When in doubt, INCLUDE the finding.
6. Keep both versions when a holistic finding overlaps with a checklist finding.

## Step 4 — Final verdict

End with PASS / FAIL. FAIL if any CRITICAL or HIGH finding, including `[Spec]`-tagged.

## Scoped Subagent Prompt Template

Use this when constructing each scoped subagent's prompt. Replace `{AGENT_GROUP_NAME}`, `{CHECKLIST}`, `{CHANGED_FILES}`, and `{DIFF}`.

```
You are a specialized TypeScript/React code reviewer focusing EXCLUSIVELY on: {AGENT_GROUP_NAME}.

STRICT SCOPING: Review ONLY against the checklist items provided below. Do NOT review items outside your assigned scope. Other agents are handling those sections.

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
