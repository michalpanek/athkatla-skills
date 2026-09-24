---
name: java-review-multi-agent
description: Java Spring Boot code review using 6 parallel subagents (scoped, holistic, clean-code). Detects the project's stack and applies only the relevant rules; best for large PRs spanning multiple domains.
argument-hint: "[optional: file path or diff range, e.g. HEAD~3..HEAD]"
disable-model-invocation: true
---

# Java Spring Boot Code Review (multi-agent)

Dispatch 6 parallel subagents. Four follow strict scoped checklists; a fifth holistic agent reviews the entire changeset without a checklist to catch emergent issues; a sixth reviews through the clean-code lens using `athkatla-skills:clean-code`. Aggregate findings into one severity-grouped report. **First detect the project's stack and only apply rules for tools actually present — all subagents respect the same skip-rules.**

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

Filter to `.java` and `.groovy` (Spock specs). Keep test resource files (`src/test/resources/**`) in the changed-files list: the Test Value gate needs the fixtures. If no `.java` or `.groovy` files match, report "No Java files to review" and stop.

## Step 2 — Load project context

Read these if they exist, before you dispatch any agent:
- `CLAUDE.md` and `AGENTS.md`, at the root and in the changed modules
- Every file in `.claude/rules/` and `.agents/rules/`
- Each project skill or doc that those files route to for Java code, naming, tests, or review

Write `{PROJECT_RULES}`: every project rule that bears on the changed files, quoted or tightly paraphrased, each with its source file. A project rule wins over a checklist item when they conflict. List each conflict in `{PROJECT_RULES}`, so the agents apply the project side.

Step 2 is done when every existing file above is read and `{PROJECT_RULES}` is written, or reads "No project rules found".

## Step 3 — Dispatch 6 subagents IN PARALLEL

All 6 in a single message with parallel `Agent` tool calls.

Each scoped agent (1-4) receives:
- The agent-group checklist (referenced below)
- The severity guidelines
- The changed-files list and full diff
- `{PROJECT_RULES}` from Step 2. Every agent gets it; append it to the holistic prompt of agent 5 as a `## Project Rules` section.
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

Inline the Test Value gate into this agent's checklist too (see "Test Value" below).

### Agent 5 — Holistic Review (no checklist)
Scope: cross-file consistency, design coherence, integration points, subtle bugs, spec fidelity.
Prompt template + axes definition + spec-discovery guidance:
@../../checklists/java/holistic-pass.md

### Agent 6 — Clean Code (uses `athkatla-skills:clean-code`)
Scope: readability, maintainability, and test value. Rules live in the clean-code and test-value checklists (see the prompt template below), not here.
Prompt template: see "Clean-Code Subagent Prompt Template" at the end of this file.
Agent 6 also owns the method-naming rule (methods start with a verb) and the comment review scan; Agent 3 checks both too. Expected overlap with Agent 3's Naming Precision / Code Style items and Agent 4's Test Value findings is fine; aggregation keeps both.

### Test Value (Agents 4 and 6)
@../../checklists/java/test-value.md

### Severity guidelines (all agents)
@../../checklists/java/severity-guidelines.md

## Step 4 — Aggregate results

After all 6 agents return:
1. Collect findings from all agents (including `[Holistic]`, `[Spec]`, `[Clean Code]`, and `[Test Value]` insights)
2. Number sequentially starting from 1
3. Group by severity: CRITICAL > HIGH > MEDIUM > LOW
4. Tag each finding with its domain in brackets. Preserve `[Holistic]`, `[Spec]`, `[Structure]`, `[Clean Code]`, and `[Test Value]` tags verbatim.
5. Do NOT aggressively deduplicate. When in doubt, INCLUDE the finding.
6. Keep both versions when a holistic finding overlaps with a checklist finding.

## Step 5 — Final verdict

End with PASS / FAIL. FAIL if any CRITICAL or HIGH finding, including `[Spec]`-tagged.

## Scoped Subagent Prompt Template

Use this when constructing each scoped subagent's prompt. Replace `{AGENT_GROUP_NAME}`, `{STACK_SUMMARY}`, `{CHECKLIST}`, `{PROJECT_RULES}`, `{CHANGED_FILES}`, and `{DIFF}`.

```
You are a specialized Java Spring Boot code reviewer focusing EXCLUSIVELY on: {AGENT_GROUP_NAME}.

STRICT SCOPING: review only the checklist items provided below. Other agents cover everything outside this scope.

## Stack Summary & Skip Rules
{STACK_SUMMARY}

## Project Rules (win over the checklist on conflict)
{PROJECT_RULES}

## Changed Files
{CHANGED_FILES}

## Full Diff
{DIFF}

## Your Checklist
{CHECKLIST}

## Severity Guidelines
<inline content of @../../checklists/java/severity-guidelines.md>

## Instructions
1. Read each changed/new Java or Groovy file in full (not just the diff).
2. Check EVERY applicable checklist item against EVERY changed file. Apply the Project Rules that fall in your scope with the same weight as checklist items.
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

Use this for Agent 6. Replace `{CHANGED_FILES}`, `{DIFF}`, `{PROJECT_RULES}`, `{CLEAN_CODE_FALLBACK}` (inline content of `@../../checklists/java/clean-code.md`), `{TEST_VALUE}` (inline content of `@../../checklists/java/test-value.md`), `{METHOD_NAMING}` (inline the "Methods start with a verb" item from `@../../checklists/java/03-code-quality-type-safety.md` § Naming Precision), and `{COMMENT_RULES}` (inline content of `@../../../clean-code/skills/clean-code/references/comments.md`).

```
You are a clean-code reviewer focusing EXCLUSIVELY on code clarity, maintainability, and test value. Stack-specific rules, architecture, security, and test style belong to other agents.

First, invoke `athkatla-skills:clean-code` via the Skill tool and apply its standards and severity rubric to the changed files. If the skill is not available, apply this fallback checklist instead:
{CLEAN_CODE_FALLBACK}

## Project Rules (win over the fallback on conflict)
{PROJECT_RULES}

## Changed Files
{CHANGED_FILES}

## Full Diff
{DIFF}

## Test Value
{TEST_VALUE}

## Method Naming
{METHOD_NAMING}

## Comments
{COMMENT_RULES}

## Severity Guidelines
<inline content of @../../checklists/java/severity-guidelines.md>

## Instructions
1. Read each changed/new Java or Groovy file in full (not just the diff).
2. Judge only what this change introduces or worsens; do not demand refactors of untouched legacy code.
3. Run the Test Value gate on every new test in the change (Test Value section above).
4. Check every new or renamed method name against the Method Naming rule above. Tag findings `[Clean Code]`.
5. Run the Comments review scan on every comment line the change adds or edits, tests included. Tag findings `[Clean Code]`.
6. For each finding, report:
   - Severity (CRITICAL / HIGH / MEDIUM / LOW)
   - Tag `[Clean Code]`, or `[Test Value]` for gate findings
   - File path and line number
   - Issue description naming the violated principle
   - Suggested fix (show the cleaner version when short)
7. Group findings by severity.
8. If no issues found, report "No issues found in Clean Code".
```
