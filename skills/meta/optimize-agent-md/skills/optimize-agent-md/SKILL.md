---
name: optimize-agent-md
description: Audits a monolithic root agent-config file (CLAUDE.md, AGENTS.md, GEMINI.md), drops stale or copy-pasted rules, and splits the survivors into a router plus per-subject rule files or skills.
disable-model-invocation: true
---

# optimize-agent-md

## Overview

Audit, slim, and split a project's root agent-config file (`CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, or equivalent) plus any existing rules directory into a **router + per-subject rule files**. Detect rules that were copy-pasted from another repo and no longer apply. Reorganize survivors into small, single-subject `.md` files so heavy detail loads on demand instead of at every conversation start.

Works across agent ecosystems. Auto-detects the agent flavor from filenames and rewrites the right tree (`.claude/rules/`, `.agents/rules/`, `.gemini/rules/`).

In a Claude Code repo, each subject has two possible destinations: a **rule file** (`.claude/rules/<subject>.md`, loaded via the router) or a **skill** (`.claude/skills/<subject>/SKILL.md`, auto-discovered by task relevance and `/name`-invocable). The user chooses per subject in step 4; they can mix freely. Skill-destined subjects follow the conversion rules of the companion skill `athkatla-skills:promote-rules-to-skills`. Outside Claude Code (`.agents/`, `.gemini/`), everything goes to rule files.

**Core principle:** wrong rules are worse than no rules. Hallucinated constraints (libraries that are not installed, paths that do not exist) waste tokens and produce broken suggestions. Verify every claim against the current repo before keeping it.

## When to use

- User explicitly invokes the skill name or asks to:
  - "Optimize CLAUDE.md" / "optimize AGENTS.md" / "optimize GEMINI.md"
  - "Audit / split / refactor my agent config file"
  - "Reorganize `.claude/rules/`" / "`.agents/rules/`"
  - "Make my agent config a router"
- A repo has a single huge root config (>200 lines) that loads on every turn. Between 80 and 200 lines: judgment call; split when the file mixes 4+ subjects or carries stale content, otherwise leave it.
- Rules in the root file or `*/rules/` reference libraries, paths, or workflows that the user has confirmed are wrong.

## When NOT to use

- Run this skill only when the user explicitly invokes it, accepts its offer, or names the target file. Reading the root config file at session start, noticing a stale rule, or a generic "audit my project" request with no named file are not invocations — when unsure whether the user wants this skill, ask before running.
- Single short root file (<80 lines) with no stale content. Split adds discovery burden for no gain.
- Project explicitly relies on one flat file by convention.
- User asks ONLY to promote already-existing rule files into skills, or to revive dormant flat skills, with no root-file split involved: that is `athkatla-skills:promote-rules-to-skills` standalone. (Within this skill's own workflow, step 5 still delegates skill-destined subjects to it.)

## Workflow

Follow in order. Do not skip the audit step.

### 0. Detect agent flavor

Pick the target tree based on which root file(s) exist:

| Root file present | Rules dir to write |
|---|---|
| `CLAUDE.md` only | `.claude/rules/` |
| `AGENTS.md` only | `.agents/rules/` |
| `GEMINI.md` only | `.gemini/rules/` |
| Multiple present | Ask user which to optimize. Do not split into multiple trees in one run. |
| None of the above, but the user named one | Use the one named. |
| None present, no name | Stop. Ask the user which file to optimize. |

If both `CLAUDE.md` and `AGENTS.md` exist and the user is ambiguous, default to `CLAUDE.md` + `.claude/rules/` only if the project is clearly Claude Code (presence of `.claude/`, `.claude-plugin/`, `claude` in scripts). Otherwise ask.

Files in the non-chosen tree (e.g. `.agents/rules/` when targeting `.claude/rules/`): leave untouched, note their existence in the final message, and suggest a second run targeting that tree if the user wants parity.

Variables used below:
- `ROOT_FILE` = the chosen root file (e.g. `CLAUDE.md`).
- `RULES_DIR` = the chosen rules directory (e.g. `.claude/rules/`).

### 1. Inventory

Find every relevant file:

```bash
# Root files
find . -maxdepth 4 \( -iname "CLAUDE.md" -o -iname "AGENTS.md" -o -iname "GEMINI.md" -o -iname "agent.md" \) 2>/dev/null

# Existing rules trees
ls -la .claude/rules/ 2>/dev/null
ls -la .agents/rules/ 2>/dev/null
ls -la .gemini/rules/ 2>/dev/null

# Adjacent docs
find docs -maxdepth 3 -type f 2>/dev/null
ls -la CONTEXT.md docs/adr/ 2>/dev/null
```

Read each one fully. Note size in lines per file.

### 2. Audit every claim against the real repo

For each rule, library, command, path, or convention mentioned, verify it matches reality.

| Claim | Verify with |
|---|---|
| Library X is used | `grep -E '"<lib>"' package.json` / `cat go.mod` / `cat pyproject.toml` / equivalent |
| Path `foo/bar/` exists | `ls foo/bar` |
| Command `pnpm run X` works | check `package.json` `scripts` |
| Test framework is Jest/Vitest/Pytest/etc. | check devDependencies + config files |
| Style approach is CSS Modules / SCSS / styled-components / Tailwind | check imports + dependencies |
| State lib is Redux / Zustand / Signals / Pinia | check imports |
| MFE / micro-frontend rules | search for actual MFE infra (single-spa, module federation) |
| External rule file `.github/REVIEW_RULES.md` | `ls` it |
| Slack channel / Linear project / Jira project references | check `.github/` workflows, env files, or ask user |
| Convention (naming, barrels, etc.) matches current code | sample 2-3 files |

For each rule, also check:
- Does it contradict another rule in the same file? Flag both for resolution.
- Is it generic enough to apply to any project (e.g. "Be concise", "think before acting")? If yes, it belongs in the user's global agent config (`~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`, `~/.gemini/GEMINI.md`), not the project file. Drop it from the project files and list it in the final message under "recommend moving to global config". Do not edit the global config yourself.

A rule is audited once it has one of three outcomes: verified and kept, reworded to match reality, or dropped with a one-line reason.

If a claim cannot be verified, flag it as hallucinated and remove it. Common stale-rule patterns and how to handle each: see `references/stale-rule-patterns.md`.

### 3. Group survivors by subject

Derive subjects **from the content**, not from a fixed template. One file per subject the rules actually cover. Typical subjects that emerge:

| Subject (example filename) | Contents |
|---|---|
| `approach.md` | Working principles, tone, validation-before-end-of-turn, model routing |
| `tool-preferences.md` | MCP servers, editors, search tools, when to use which |
| `typescript.md` / `python.md` / `java.md` | Language-specific code rules |
| `react.md` / `spring.md` / `vue.md` | Framework-specific rules |
| `naming.md` | Naming conventions across the codebase |
| `styling.md` | CSS / styling library rules |
| `state-management.md` | Store/selector/signal rules |
| `testing.md` | Test framework, fixtures, coverage expectations |
| `commands.md` | Build / test / dev / lint commands, env vars |
| `architecture.md` | Module layout, layer boundaries, data flow pointers |
| `git-workflow.md` | Branch naming, commit style, PR conventions |
| `review.md` | Blocking + warning PR review rules, self-validation checklist |
| `security.md` | Secret handling, input validation baseline |

Sizing rules:
- Target **20-120 lines per file**. Single subject per file.
- A subject under ~10 lines does not earn its own file: merge it into the nearest related subject. When the nearest neighbor is ambiguous, follow the subject table's grouping (e.g. commit-message format belongs with `git-workflow.md` content, so it merges wherever that content landed).
- A subject over ~120 lines is probably two subjects: split it (e.g. `react.md` + `react-data-fetching.md`).
- Aim for roughly 4-12 files total. Fewer for small configs, more only when content genuinely demands it.
- Filenames: kebab-case, named after the subject, meaningful to a reader scanning the directory.

If the existing tree already has sensible per-subject files, keep their names and merge into them instead of renaming. Do not churn working filenames.

### 4. Ask the user: rule file or skill, per subject (Claude Code only)

If `RULES_DIR` is `.claude/rules/`, present the subject list and ask ONE batched question: for each subject, should it become a **rule file** or a **skill**? Include your recommendation per subject:

| Subject shape | Recommend |
|---|---|
| Always-on discipline (code conventions, security baseline, naming) | Rule file. If detail-heavy (>40 lines), recommend hybrid: slim non-negotiables as rule file + full detail as skill. |
| Phase-scoped, topic-shaped, detail-heavy (testing setup, review checklist, commands, framework patterns) | Skill. Triggers by task relevance, stays out of always-loaded context. |
| Tiny (<30 lines) and phase-scoped | Rule file. Skill wrapper adds a discovery hop for no gain. |

State the trade-off once: a skill self-triggers and is `/name`-invocable, but if it fails to fire the content is silently skipped — which is why always-on disciplines stay (at least partly) in rules.

The user can mix freely: some subjects as rules, some as skills, some hybrid. Their choice wins over your recommendation.

If the tree is `.agents/` or `.gemini/`: skip this step, everything becomes a rule file. Skill auto-discovery is Claude Code only.

### 5. Write the files

**Rule-destined subjects** go to `RULES_DIR` (filenames are examples, derive from actual content):

```
<RULES_DIR>/
  approach.md
  typescript.md
  commands.md
```

Each rule file:
- Starts with a one-line scope statement: when an agent should read this file.
- Contains only rules verified in step 2.
- No duplication across files. A rule lives in exactly one file; other files may reference it by filename.

**Skill-destined subjects** go to `.claude/skills/<name>/SKILL.md` (directory form, never flat). Follow the conversion rules of `athkatla-skills:promote-rules-to-skills` — invoke it if installed; if not installed, apply at minimum: directory form, third-person "Use when…" trigger-only description, name-collision check against existing skills and slash commands, hybrid for always-on disciplines, and verify each new skill appears in the available-skills list same session.

```
.claude/skills/
  testing-conventions/SKILL.md
  review-checklist/SKILL.md
```

Write a file only for a subject that has surviving content; skip any subject left empty by the audit.

### 6. Rewrite root `ROOT_FILE` as a router

Keep it short (under 60 lines as guidance; the routing table is mandatory and wins over the line budget when a repo has many subjects). The routing table is generated from the actual rule files written in step 5: one row per rule file, with a concrete trigger. Skill-destined subjects do NOT get router rows for loading (they self-trigger); list them in a short "Skills" section instead so a reader knows where that content went. Structure (substitute `RULES_DIR` and `ROOT_FILE`):

```markdown
# <ROOT_FILE> (Router)

Minimal entry point. Detailed rules live in `<RULES_DIR>`. Load on demand.

## Precedence

User instructions override this file and every linked rule file.

## When to read what

| Task / trigger | File |
|---|---|
| <one row per rule file written in step 5, trigger phrased as the task that needs it> | `<RULES_DIR><subject>.md` |
| <docs/* file if present> | `docs/<path>` |

## Quick rules (must follow on every task)

- (3-6 truly always-on rules, no more)

## Skills

(only if subjects became skills)
Detail for <subjects> lives in auto-triggering skills: `/​<name>`, ... See `.claude/skills/`.

## Local-only artifacts (gitignored)

(only if project has spec-kit / brainstorm / plans / specs trees)

## Plans pointer

(only if a plans dir exists)
```

Trigger phrasing matters: write the row so an agent matching its current task to the table picks the right file. "Writing or refactoring React components" beats "React rules".

### 7. Route to `docs/` when present

If `docs/` (or `docs/agents/`, `docs/adr/`, `CONTEXT.md`) exists, add rows to the router table. Read each doc's first 5 lines to write an accurate description.

Common docs to route:

| Doc | Trigger |
|---|---|
| `docs/agents/issue-tracker.md` | Naming branches / commits, opening tickets |
| `docs/agents/triage-labels.md` | Applying triage labels |
| `docs/agents/domain.md` | Looking up domain terminology |
| `CONTEXT.md` | Looking up domain glossary |
| `docs/adr/` | Checking architectural decisions |

### 8. Surface what was dropped

In your final message to the user, list:
- Files created / modified, marking which subjects became rules vs skills.
- Rules dropped, with one-line reason each (cite evidence: "no `@x/y` in `package.json`", "no `apps/` dir").
- Rules reworded, with what changed.

Check the root file for existing output-style rules (for example, a ban on hyphens or em-dashes) and follow them when writing this message. User should be able to `git diff` and understand every change.

## Deliverable shape

Final user message must contain:
1. File inventory before / after with line counts, marking rule files vs skills.
2. Table of what was dropped + evidence, plus generic rules recommended for global config.
3. Table of what was added or reworded.
4. The router table as written.
5. (If skills were created) live-discovery confirmation: each new skill appears in the available-skills list.
6. Suggested next step: `git diff <ROOT_FILE> <RULES_DIR>` for review (add `.claude/skills/` when skills were created).
