---
name: java-review-multi-agent
description: Opinionated Java code review (Spring Boot-focused) using 6 parallel subagents. Auto-detects the project's stack (Spring Boot starters, JPA, Lombok, Vavr, Resilience4j, Spock, RabbitMQ, etc.) and applies ONLY rules for tools actually in use. Works for single-module or multi-module Maven/Gradle projects. Use for large PRs spanning multiple domains.
when_to_use: User explicitly invokes /java-review-multi-agent. Do NOT auto-apply on edits or generic "review my code" requests — this skill is opt-in only.
argument-hint: "[optional: file path or diff range, e.g. HEAD~3..HEAD]"
disable-model-invocation: true
---

# Java Spring Boot Code Review (multi-agent)

Dispatch 6 parallel subagents. Four follow strict scoped checklists; a fifth holistic agent reviews the entire changeset without a checklist to catch emergent issues; a sixth reviews through the clean-code lens using the `clean-code` skill. Aggregate findings into one severity-grouped report. **First detect the project's stack and only apply rules for tools actually present — all subagents respect the same skip-rules.**

## Step 0 — Detect stack

@../../checklists/java/00-stack-detection.md

Print the stack summary before continuing. Include the same stack-summary + skip-rules verbatim in the prompts of agents 1-5 (the `{STACK_SUMMARY}` slot) so they apply consistent skip logic. Agent 6 reviews stack-agnostic clean-code concerns and does not receive it.

## Step 1 — Gather changes

```bash
git diff --name-only HEAD
git status --short
git diff HEAD
```

If `$ARGUMENTS` is provided, treat as diff range or file list. Otherwise default to uncommitted changes on `HEAD`.

Filter to `.java`. If no files match, report "No Java files to review" and stop.

## Step 2 — Dispatch 6 subagents IN PARALLEL

All 6 in a single message with parallel `Agent` tool calls.

Each scoped agent (1-4) receives:
- The agent-group checklist (referenced below)
- The severity guidelines
- The changed-files list and full diff
- The "Scoped Subagent Prompt Template" at the end of this file (agent 5 uses the holistic prompt from `@../../checklists/java/holistic-pass.md` instead; agent 6 uses the "Clean-Code Subagent Prompt Template")

### Agent 1 — Architecture & Spring Configuration
Scope: Architecture & Layering, Spring Boot Patterns, Package Placement, Configuration & Externalization, Dependency Hygiene.
Checklist:
@../../checklists/java/01-architecture-spring-config.md

### Agent 2 — Data Layer & Persistence
Scope: Entity & Persistence, Database & Migrations, JPA Query Patterns, DTOs & Records, Mapper & Translation Patterns, Data Matching & Identity, Enum Design.
Checklist:
@../../checklists/java/02-data-layer-persistence.md

### Agent 3 — Code Quality & Type Safety
Scope: Code Style, Naming Precision, Java Type & Optional Patterns, Validation & Safety, Exception Handling.
Checklist:
@../../checklists/java/03-code-quality-type-safety.md

### Agent 4 — Cross-cutting Concerns
Scope: Logging, Messaging & Events, Async Correctness, Scheduled Jobs, SOAP & External API Integration, Email & Notifications, Tests, PR & Commit Standards.
Checklist:
@../../checklists/java/04-cross-cutting-concerns.md

### Agent 5 — Holistic Review (no checklist)
Scope: cross-file consistency, design coherence, integration points, subtle bugs, spec fidelity.
Prompt template + axes definition + spec-discovery guidance:
@../../checklists/java/holistic-pass.md

### Agent 6 — Clean Code (uses the clean-code skill)
Scope: readability and maintainability only — intention-revealing naming, self-explanatory code instead of comments, declarative/functional patterns over nested if/else, clear code structure, small focused methods and classes, DRY.
Prompt template: see "Clean-Code Subagent Prompt Template" at the end of this file.
Expected overlap with Agent 3's Naming Precision / Code Style items is fine; aggregation keeps both.

### Severity guidelines (all agents)
@../../checklists/java/severity-guidelines.md

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
You are a specialized Java Spring Boot code reviewer focusing EXCLUSIVELY on: {AGENT_GROUP_NAME}.

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
<inline content of @../../checklists/java/severity-guidelines.md>

## Instructions
1. Read each changed/new Java file in full (not just the diff).
2. Check EVERY applicable checklist item against EVERY changed file.
3. For each finding, report:
   - Severity (CRITICAL / HIGH / MEDIUM / LOW)
   - Domain tag in brackets matching checklist section name (e.g., [Architecture], [Spring Boot], [JPA Query])
   - File path and line number
   - Issue description referencing the specific checklist rule
   - Suggested fix
4. Group findings by severity.
5. If no issues found in your scope, report "No issues found in {AGENT_GROUP_NAME}".

Structural red flags (beyond your checklist): if a change in your files clearly worsens structure — sprawls a class well past ~1000 lines, wedges a special-case branch into an unrelated shared flow, or adds a wrapper / abstraction that only relocates complexity — note it briefly tagged `[Structure]`, even though it is outside your scoped items. Keep this to genuine structural problems, not style; the holistic agent owns the deep structural pass.
```

## Clean-Code Subagent Prompt Template

Use this for Agent 6. Replace `{CHANGED_FILES}` and `{DIFF}`.

```
You are a clean-code reviewer focusing EXCLUSIVELY on code clarity and maintainability. You do NOT review stack-specific rules, architecture, security, or tests — other agents own those.

First, invoke the `clean-code` skill via the Skill tool and apply its standards and severity rubric to the changed files. If the skill is not available, apply this fallback checklist instead:
- Intention-revealing names for variables, methods, classes, packages. Flag vague names (data, info, temp, handle, process, Manager, Util) and misleading names.
- Self-explanatory code instead of comments. A comment explaining WHAT the code does is a naming/structure smell; comments only earn their place stating constraints the code cannot express (and Javadoc on public API).
- Declarative / functional style over imperative nesting: early returns / guard clauses over nested if/else chains, Streams or Vavr over index loops where it reads better, no flag-argument branching.
- Clear structure: one responsibility per method and class; related logic colocated; no grab-bag utils additions.
- Size: flag methods over ~50 lines and classes over ~800 lines, or any method/class the change makes meaningfully harder to follow.
- DRY: duplicated or near-identical blocks introduced or extended by this change.

## Changed Files
{CHANGED_FILES}

## Full Diff
{DIFF}

## Severity Guidelines
<inline content of @../../checklists/java/severity-guidelines.md>

## Instructions
1. Read each changed/new Java file in full (not just the diff).
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
