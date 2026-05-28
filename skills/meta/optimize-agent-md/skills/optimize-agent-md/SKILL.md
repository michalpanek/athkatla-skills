---
name: optimize-agent-md
description: Use ONLY when the user explicitly invokes this skill (e.g. /optimize-agent-md, "optimize my CLAUDE.md", "optimize my AGENTS.md", "audit and split AGENTS.md / CLAUDE.md", "split my agent rules"). Audits a monolithic root agent-config file (CLAUDE.md, AGENTS.md, GEMINI.md, or equivalent), detects stale or copy-pasted rules that do not match the current project, splits content by area (overall, code, project config, review) into per-agent rule files (.claude/rules/ for Claude, .agents/rules/ for Codex / OpenAI / generic, .gemini/rules/ for Gemini), and rewrites the root file as an on-demand router. Do NOT auto-invoke.
disable-model-invocation: true
---

# optimize-agent-md

## Overview

Audit, slim, and split a project's root agent-config file (`CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, or equivalent) plus any existing rules directory into a router + per-area rule files. Detect rules that were copy-pasted from another repo and no longer apply. Reorganize survivors into a router pattern so heavy detail loads on demand instead of at every conversation start.

Works across agent ecosystems. Auto-detects the agent flavor from filenames and rewrites the right tree (`.claude/rules/`, `.agents/rules/`, `.gemini/rules/`).

**Core principle:** wrong rules are worse than no rules. Hallucinated constraints (libraries that are not installed, paths that do not exist) waste tokens and produce broken suggestions. Verify every claim against the current repo before keeping it.

## When to use

- User explicitly invokes the skill name or asks to:
  - "Optimize CLAUDE.md" / "optimize AGENTS.md" / "optimize GEMINI.md"
  - "Audit / split / refactor my agent config file"
  - "Reorganize `.claude/rules/`" / "`.agents/rules/`"
  - "Make my agent config a router"
- A repo has a single huge root config (>200 lines) that loads on every turn.
- Rules in the root file or `*/rules/` reference libraries, paths, or workflows that the user has confirmed are wrong.

## When NOT to use

- Auto-invocation. Manual only. Do not run because you happened to read the root config file.
- Single short root file (<80 lines) with no stale content. Split adds discovery burden for no gain.
- Project explicitly relies on one flat file by convention.

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

If a claim cannot be verified, flag it for removal. Common red flags:
- Mentions of `@<org>/shared-*` packages that are not in the manifest.
- Mentions of `apps/*`, `packages/*`, `services/*` directories in a single-package repo.
- Rules referring to "MFE", "MountMicroFrontend", "service-registry", "root-config" with no matching code.
- Slack channel mapping, Sentry projects, infra names from another org.
- Tooling references that don't match (e.g. `eslint` rules listed but project uses Biome / Ruff / ktlint).
- Rules about a language not present in the repo (e.g. Java rules in a Node-only project).

### 3. Categorize survivors

Bucket every rule into one of four categories. If a rule fits two, pick the one that best matches the trigger condition.

| Category | Contents |
|---|---|
| Overall | Approach, working principles, tone, tool preferences (MCP servers, editors), validation-before-end-of-turn, model routing |
| Code | Code style, naming, comments, language-specific rules (TS/JS/Python/Go/Rust/Java/etc.), framework rules (React/Vue/Spring/etc.), styling rules, state management, type modeling |
| Project | Commands (build/test/dev/lint), architecture pointers, env vars, embedding/integration context, E2E setup, build + deploy, local-only artifacts, issue-tracker conventions |
| Review | Blocking + warning rules for PR review, self-validation checklist, conflict resolution |

### 4. Write the four files

Target layout (substitute `RULES_DIR`):

```
<RULES_DIR>/
  overall.md    # Overall approach + tool prefs
  code.md       # Code rules (language + framework specific)
  project.md    # Commands, architecture, build, env, E2E setup
  review.md     # Review rules (blocking + warning + self-validation)
```

Naming note: original layout used `claude.md` inside `.claude/rules/`. For the generic skill use `overall.md` so the same name works under `.agents/rules/` and `.gemini/rules/`. If the existing tree already uses `claude.md` / `agents.md` / `gemini.md`, keep the existing name to avoid churn.

File-size guidance (rough):
- `overall.md`: 50-100 lines
- `code.md`: 100-250 lines (heaviest; project-specific TS / React / Python / etc. rules live here)
- `project.md`: 80-150 lines
- `review.md`: 50-120 lines

If a category is empty, skip the file. Do not write empty stubs.

### 5. Rewrite root `ROOT_FILE` as a router

Keep it short (under 60 lines). Structure (substitute `RULES_DIR` and `ROOT_FILE`):

```markdown
# <ROOT_FILE> (Router)

Minimal entry point. Detailed rules live in `<RULES_DIR>`. Load on demand.

## Precedence

User instructions override this file and every linked rule file.

## When to read what

| Task | File |
|---|---|
| Default overall approach, tool prefs, validation | `<RULES_DIR>overall.md` |
| Writing new features, refactoring, code style | `<RULES_DIR>code.md` |
| Need a command, env var, build step, architecture | `<RULES_DIR>project.md` |
| Doing a code review or PR self-check | `<RULES_DIR>review.md` |
| <docs/* file if present> | `docs/<path>` |

## Quick rules (must follow on every task)

- (3-6 truly always-on rules, no more)

## Reach for files when

- Adding new code -> read `code.md`.
- Reviewing PR -> read `review.md`.
- Need a project command or architecture detail -> read `project.md`.
- Need tool preference or validation steps -> read `overall.md`.

## Local-only artifacts (gitignored)

(only if project has spec-kit / brainstorm / plans / specs trees)

## Plans pointer

(only if a plans dir exists)
```

### 6. Route to `docs/` when present

If `docs/` (or `docs/agents/`, `docs/adr/`, `CONTEXT.md`) exists, add rows to the router table AND triggers to the "Reach for files when" list. Read each doc's first 5 lines to write an accurate description.

Common docs to route:

| Doc | Trigger |
|---|---|
| `docs/agents/issue-tracker.md` | Naming branches / commits, opening tickets |
| `docs/agents/triage-labels.md` | Applying triage labels |
| `docs/agents/domain.md` | Looking up domain terminology |
| `CONTEXT.md` | Looking up domain glossary |
| `docs/adr/` | Checking architectural decisions |

### 7. Surface what was dropped

In your final message to the user, list:
- Files created / modified.
- Rules dropped, with one-line reason each (cite evidence: "no `@x/y` in `package.json`", "no `apps/` dir").
- Rules reworded, with what changed.

User should be able to `git diff` and understand every change.

## Audit checklist (use this when scanning rules)

For each rule, ask:

- [ ] Does the library/tool/path it references exist in this repo?
- [ ] Does the command it references work (check `scripts` in `package.json` or equivalent)?
- [ ] Does the convention it enforces match what current code actually does (sample 2-3 files)?
- [ ] Is the rule generic-enough-to-survive that it would apply to any project? If yes, it belongs in the user's global agent config (`~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`, `~/.gemini/GEMINI.md`), not the project file.
- [ ] Is the rule contradicted by another rule in the same file? Flag for resolution.

## Common stale-rule patterns

| Pattern | Action |
|---|---|
| `@<org>/shared-*` library rules | Verify package exists. If not, drop. |
| MFE / `MountMicroFrontend` / `root-config` rules | Verify MFE infra exists. Otherwise drop the entire section. |
| Slack channel mapping rules | Drop unless `.github/` workflows reference Slack. |
| Specific test framework rules (Jest fixtures, Playwright POM, Pytest fixtures) | Verify framework matches. Reword to actual setup. |
| Specific styling library rules (styled-components, emotion, CSS Modules, Tailwind) | Verify dep present. Drop or reword. |
| State management rules (Redux selectors, Zustand stores, Pinia) | Verify lib in deps. Reword to actual lib. |
| `index.ts` barrel file rules | Check if codebase uses them. Keep rule only if convention is followed. |
| Jira/Linear/GitHub Issues references | Verify which tracker is actually used. |
| Language-specific rules for unused language | Drop entire section. |

## Router section template

Copy and adapt (substitute `RULES_DIR`):

```markdown
## When to read what

| Task | File |
|---|---|
| Default overall approach, tool prefs, validation-before-end | `<RULES_DIR>overall.md` |
| Writing new features, refactoring, code style | `<RULES_DIR>code.md` |
| Need a command, env var, build step, architecture pointer | `<RULES_DIR>project.md` |
| Doing a code review or PR self-check | `<RULES_DIR>review.md` |

## Reach for files when

- Adding new code / new feature -> read `code.md`.
- Reviewing a PR or doing self-review -> read `review.md`.
- Need a project command, architecture detail, or env config -> read `project.md`.
- Need tool preference detail or validation steps -> read `overall.md`.
```

## Common mistakes

- **Splitting without auditing.** Carrying stale rules into smaller files just rearranges chairs. Audit first, drop irrelevant rules, then split.
- **Generic content in `overall.md`.** "Be concise", "think before acting" applies to every project and belongs in the user's global agent config. Project-level `overall.md` should still be project-specific approach.
- **Duplicating root content in `project.md`.** Pick one. Recommend: keep architecture in `project.md`, make root file a pure router.
- **Forgetting `docs/` routing.** If the repo has `docs/agents/*`, `CONTEXT.md`, or `docs/adr/`, the router should point there.
- **Empty stubs.** If a category is empty for this project (e.g. no review rules yet), do not write an empty `review.md`. Skip.
- **Hyphens / em-dashes in user-facing output if the project bans them.** Check root file for style rules before writing the final summary message.
- **Mixing agent trees.** Do not split into both `.claude/rules/` and `.agents/rules/` in one run. Pick one target per invocation.
- **Renaming working filenames.** If existing tree uses `claude.md` / `agents.md`, keep it. Do not churn names just to match the generic `overall.md` convention.

## Deliverable shape

Final user message must contain:
1. File inventory before / after with line counts.
2. Table of what was dropped + evidence.
3. Table of what was added or reworded.
4. Suggested next step: `git diff <ROOT_FILE> <RULES_DIR>` for review.

## Manual-only invocation

This skill is invoked manually. Do not trigger it from:
- Reading the root agent file at session start.
- Encountering a stale rule incidentally.
- Generic "audit my project" requests without explicit mention of `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` or a rules directory.

If unsure whether the user wants this skill, ask before running.
