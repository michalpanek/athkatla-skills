---
name: java-review-multi-agent
description: Opinionated Java code review (Spring Boot-focused) using 5 parallel subagents. Auto-detects the project's stack (Spring Boot starters, JPA, Lombok, Vavr, Resilience4j, Spock, RabbitMQ, etc.) and applies ONLY rules for tools actually in use. Works for single-module or multi-module Maven/Gradle projects. Use for large PRs spanning multiple domains.
when_to_use: User explicitly invokes /java-review-multi-agent. Do NOT auto-apply on edits or generic "review my code" requests — this skill is opt-in only.
argument-hint: "[optional: file path or diff range, e.g. HEAD~3..HEAD]"
disable-model-invocation: true
---

# Java Spring Boot Code Review (multi-agent)

Dispatch 5 parallel subagents. Four follow strict scoped checklists; a fifth holistic agent reviews the entire changeset without a checklist to catch emergent issues. Aggregate findings into one severity-grouped report. **First detect the project's stack and only apply rules for tools actually present — all subagents respect the same skip-rules.**

## Step 0 — Detect stack

@../../checklists/java/00-stack-detection.md

Print the stack summary before continuing. Include the same stack-summary + skip-rules verbatim in every subagent prompt so all 5 agents apply consistent skip logic.

## Step 1 — Gather changes

```bash
git diff --name-only HEAD
git status --short
git diff HEAD
```

If `$ARGUMENTS` is provided, treat as diff range or file list. Otherwise default to uncommitted changes on `HEAD`.

Filter to `.java`. If no files match, report "No Java files to review" and stop.

## Step 2 — Dispatch 5 subagents IN PARALLEL

All 5 in a single message with parallel `Agent` tool calls.

Each scoped agent (1-4) receives:
- The agent-group checklist (referenced below)
- The severity guidelines
- The changed-files list and full diff
- The scoped subagent prompt template (inline at the end of this file)

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

### Severity guidelines (all agents)
@../../checklists/java/severity-guidelines.md

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
You are a specialized Java Spring Boot code reviewer focusing EXCLUSIVELY on: {AGENT_GROUP_NAME}.

STRICT SCOPING: Review ONLY against the checklist items provided below. Do NOT review items outside your assigned scope. Other agents are handling those sections.

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
```
