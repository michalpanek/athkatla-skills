# Child Repo Templates

Skeletons for the files at the root of each child repo. Replace every `<placeholder>`.

## Rules for every file

1. **No Home in a team repo.** These files, their commit messages and their PR go to the team's remote. While the Home is local-only, they name no Home path, no `../` link, no `GLOSSARY-MAP.md` and no skill that lives only in the Home. Name a sibling repo by its name (`<repo>/path`). Name a skill only when it comes from a public plugin. For a team skill, write "the team's <purpose> skill".
2. **One fact, one file.** Each fact lives in the file whose role holds it (table below). Other files point to it.
3. **Facts have references.** Every fact has a file reference (`path` or `path:line`). Mark a fact without one as `Unverified`.
4. **Corrections are visible.** When a doc is wrong, fix it. In `GLOSSARY.md` and `CONTEXT.md`, add a note in the file that says what changed and why. For other files, put the note in the report, so it reaches the commit message and the PR body.

## Roles

| File | Holds | Never holds |
|---|---|---|
| `AGENTS.md` | Repo-only rules and every build, test, lint and run command | Shared rules that the Home holds |
| `CONTEXT.md` | What the service is: purpose, boundaries, integrations, deployment | Term definitions |
| `GLOSSARY.md` | Terms and facts that the team agreed on | Terms derived from code alone, decisions |
| `CODE_STANDARDS.md` | Stack skip rules, framework equivalents, data access specifics, repo conventions, conflicts with the review checklists | Copies of the review checklists |
| `docs/adr/` | Decisions for this repo. The decision repo also holds decisions for more than one repo | Decisions that belong to another repo |
| `docs/agents/` | Tracker and label rules that only this repo uses | Rules that the Home copy holds |

## `CLAUDE.md`

```md
@AGENTS.md
```

Write it when sessions use Claude Code. Keep an existing `CLAUDE.md` with real content: move that content into `AGENTS.md` first, then replace the file with the import line.

## `AGENTS.md`

Use the `<important if>` structure. Keep every command from the old files. One trigger per block. Target: under 80 lines.

```md
# AGENTS.md

<repo>: <one line: what it is, what it is built with>.

## Project map

- `<path>/` - <what it holds>
- `CONTEXT.md`, `GLOSSARY.md`, `CODE_STANDARDS.md`, `docs/adr/` - agent and domain documents

Stack: <languages, frameworks, versions, build tool>.

<important if="you need to run commands to build, test, lint, deploy, or start the app">
| Command | What it does |
|---|---|
| `<command>` | <what it does> |
</important>

<important if="you add or change <language> code">
Read `CODE_STANDARDS.md` before you write code.
</important>

<important if="you name a domain concept, a class, a field, or a status">
Read `GLOSSARY.md` and `CONTEXT.md` first. Use their terms.
</important>

<important if="<narrow trigger for a repo-only rule>">
<rule, with a file reference>
</important>
```

## `CONTEXT.md`

```md
# <repo>: context

## Purpose
<what the service does, for whom> (`<file ref>`)

## Boundaries
<what it owns, what it does not own>

## Integrations
| System | Direction | How | Reference |
|---|---|---|---|
| <system> | in / out | REST / queue / DB | `<file ref>` |

## Deployment
<where and how it runs> (`<file ref>`)

## Unverified
- <fact without a file reference, and who can confirm it>
```

## `GLOSSARY.md`

Move an existing glossary unchanged. Fix only its links. For a new glossary, write the stub:

```md
# <repo>: glossary

Add a term only when the team agrees on it.

| Term | Meaning | Reference |
|---|---|---|
```

## `CODE_STANDARDS.md`

```md
# Code standards: <repo>

The review skill loads its own checklists, for example `java-review-multi-agent` or `ts-review-multi-agent` from the athkatla-skills plugin. This file does not repeat them. It holds what the checklists cannot know. When a checklist rule conflicts with this file, this file wins.

## Stack and skipped rules
- <stack facts> (`<build file>`)
- Absent, so skip: <tools>.
- Review coverage: <the review skill covers every language of the repo / does not cover <language>: review those files by hand>. The review skill's file filter decides.

## Framework equivalents
- <checklist rule> → <how this stack does it>

## Data access
- <rules kept for the real data layer>

## Repo conventions
- <convention>. Example: `<path>`.

## Conflicts
| Checklist rule | Repo convention | Winner |
|---|---|---|
| <rule> (`<checklist file>`) | <convention> (`<path>`) | <side and reason> |
```

## `docs/adr/`

Keep existing ADRs. Add `.gitkeep` when the folder is empty.
