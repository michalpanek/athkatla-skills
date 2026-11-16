# Home Templates

Skeletons for the files at the root of the Home. Replace every `<placeholder>`. Delete a section that has no content.

## Layout

```
<project>/                           # the Home: holds the repos; a local git repo, no remote until Step 9
├── .gitignore                       # allowlist
├── CLAUDE.md                        # one line: @AGENTS.md (when sessions use Claude Code)
├── AGENTS.md
├── GLOSSARY-MAP.md
├── docs/agents/                     # issue-tracker.md, triage-labels.md, domain.md
├── docs/contexts/<context>/         # contexts that span repos; sensitive ones gitignored
├── <skill folder>/                   # shared project skills: .claude/skills/ (Claude Code) or .agents/skills/
├── .agents/                         # specs, plans, agent tickets: local, never tracked
└── <repo-a>/ <repo-b>/ ...          # child repos, ignored by the Home git
```

## `.gitignore` (allowlist)

The allowlist keeps the child repos, worktrees, backups and secrets out of the Home git. Add one `!/` line for each path the plan tracks.

```gitignore
# Home: allowlist. Ignore everything, then track named paths only.
/*
!/.gitignore
!/AGENTS.md
!/CLAUDE.md
!/GLOSSARY-MAP.md
!/docs/

# Shared skills: keep ONE of these two blocks, for the skill folder in use.
# The lines also win over a global gitignore that ignores the folder.
# Block A: .claude/skills/
!/.claude/
/.claude/*
!/.claude/skills/
# Block B: .agents/skills/ (specs and plans in .agents/ stay untracked)
!/.agents/
/.agents/*
!/.agents/skills/

# Local only: <reason, for example "describes vulnerabilities that are not fixed yet">.
/docs/contexts/<sensitive-context>/

.DS_Store
```

## `CLAUDE.md`

```md
@AGENTS.md
```

Write this file when sessions use Claude Code. Claude Code loads `CLAUDE.md` from the current folder and its parent folders. It does not load `AGENTS.md` without this import. Keep the file to this one line.

## `AGENTS.md`

Follow the `<important if>` structure: identity and map stay bare, each conditional rule gets its own block with one narrow trigger.

```md
# <Project> Home

Agent home for <project>: it links all repos and holds the shared skills, the domain map and the shared docs. Start sessions here. <While local-only: "This folder is a local git repo with no remote.">

## Project map

- `GLOSSARY-MAP.md`: entry point to the domain docs of every repo.
- `docs/agents/`: issue tracker, triage labels and domain doc rules.
- `docs/contexts/<context>/`: <what it is>. <"Local only, gitignored." when sensitive>
- `<skill folder>/`: project skills (<short list>).
- `.agents/`: specs, plans, agent tickets. Local only, not tracked by git.
- One folder per repo (see "Other Repos"). Each repo has `AGENTS.md`, `CONTEXT.md`, `GLOSSARY.md`, `CODE_STANDARDS.md` and `docs/adr/`.

## Other Repos

Integration branch: <per repo or per group>. Before you change a repo, read its `AGENTS.md`.

- <name> (<what it is>): <local path>. Clone from <remote> if missing. <hint>
- <name> (<what it is>): <local path>. Local only, no remote.
- <name> (<what it is>): not cloned. Clone from <remote> if a task needs it.

<important if="you create, find, or update an issue, a ticket, a spec, or a plan">
- <Tracker> is the source of truth. See `docs/agents/issue-tracker.md`.
- Ask the user before every tracker write. Show the exact content first.
- Write specs to `.agents/specs/`, plans to `.agents/plans/`. Git does not track these files.
</important>

<important if="you need domain terms, business rules, or architectural decisions">
Start at `GLOSSARY-MAP.md`. Read the repo's `CONTEXT.md`, then its `GLOSSARY.md`, then its `docs/adr/`. Decisions for more than one repo live in `<central-repo>/docs/adr/`.
</important>

<important if="you record a decision">
A decision for one repo goes to `<repo>/docs/adr/`. A decision for more than one repo goes to `<central-repo>/docs/adr/`, so the team has it in git.
</important>

<important if="the task touches <sensitive topic>">
Read `docs/contexts/<sensitive-context>/` first. Never copy its content into a repo, a PR, the tracker or any remote.
</important>
```

Past about 20 repos, replace the "Other Repos" list with one line per area (`<Area> (<what it holds>): see repos/<area>.md`) and list the repos of each area in its file.

## `GLOSSARY-MAP.md`

```md
# Glossary map: <project>

Entry point to the domain docs of <project>. Each repo owns its documents. This map points to them. Paths are relative to the Home.

## Per-repo documents

- `CONTEXT.md`: what the service is: purpose, boundaries, integrations, deployment.
- `GLOSSARY.md`: agreed terms and agreed facts. No decisions.
- `CODE_STANDARDS.md`: stack skip rules, repo conventions, conflicts with the review checklists.
- `docs/adr/`: decisions for this repo only.

| Repo | What it is | Glossary state |
| --- | --- | --- |
| [`<repo>`](<repo>/CONTEXT.md) | <what it is> | stub / [full](<repo>/GLOSSARY.md) |

## Cross-cutting contexts

| Context | Where | Note |
| --- | --- | --- |
| <context> | `docs/contexts/<context>/` | <scope>. <"Local only: gitignored, because ..."> |

## Decisions

- Decisions for more than one repo: [`<central-repo>/docs/adr/`](<central-repo>/docs/adr/). They stay in git so the team can read them.
- Decisions for one repo: `<repo>/docs/adr/`.

## Rules

- Before you work in a repo, read its `CONTEXT.md`, then its `GLOSSARY.md`, then the ADRs for your area.
- Add a term to `GLOSSARY.md` only when the team agrees on it.
- See [`docs/agents/domain.md`](docs/agents/domain.md).
```

## `docs/agents/`

The engineering skills (for example the `setup-matt-pocock-skills` family) read these three files. Write them yourself from this list. Each file says that the child repos keep their own trackers.

- `issue-tracker.md`: per repo, the tracker (GitHub, GitLab, Jira, local Markdown, other), the project or repo key, and the tool or skill that writes to it. Then the approval rule for writes, and where local specs and plans go (`.agents/specs/`, `.agents/plans/`).
- `triage-labels.md`: one row per role (needs triage, needs info, ready for agent, ready for human, will not fix) with the label string that each tracker uses.
- `domain.md`: the layout (multi-context: one repo is one context, entry point [`GLOSSARY-MAP.md`](../../GLOSSARY-MAP.md)). Then the read order: map, `CONTEXT.md`, `GLOSSARY.md`, ADRs in the repo and in the decision repo, cross-cutting contexts. Then three rules: facts are not decisions; use the glossary's words; flag a conflict with an ADR, do not override it silently.

Links in a file under `docs/agents/` start with `../../` to reach the Home root.
