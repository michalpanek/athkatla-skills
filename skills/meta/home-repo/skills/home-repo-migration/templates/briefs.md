# Briefs

## Subagent brief: per-repo docs (Step 6)

Give one agent 2 or 3 repos. Replace every `<placeholder>`.

```md
Write the agent docs for these repos: <repo paths>.

Each repo is on branch `<branch>`. Stay on it. Do not switch branches, commit or push.
Leave .env and other secret files unread.
Search with the tools that the user's setup names (CLAUDE.md, hooks). When a search finds nothing, check the same search on a term that exists before you trust it.

Read <absolute path to templates/repo.md>. Follow its rules and templates for every file.
Write or update: AGENTS.md, CLAUDE.md (<"yes" when sessions use Claude Code, else "no">), CONTEXT.md, GLOSSARY.md, CODE_STANDARDS.md, docs/adr/.

Also:
1. AGENTS.md: keep every command from the old files. Run only these commands to verify them: <approved commands from plan item 7>. Install nothing.
2. Apply these approved corrections: <plan item 8 rows for these repos>. Put each correction note in your report. Write a note into a file only for a fact in GLOSSARY.md or CONTEXT.md.
3. Run: python3 <absolute path to scripts/linkcheck.py> --root <repo> <each file you wrote or changed>. Fix every problem it prints in those files.

Report, per repo:
- each file written, with its line count
- the commands you ran, and the result of each
- every "Unverified" item
- conflicts between the repo and the review checklists
- every correction, with what changed and why
- skipped items, with the reason
- the output of `git status --short`
```

## PR body (Step 8)

Write the PR body in the language and style of the repo's earlier PRs. While the Home is local-only, the body names no Home path.

```md
## What

Agent and domain docs for <repo>: AGENTS.md, CONTEXT.md, GLOSSARY.md, CODE_STANDARDS.md, docs/adr/.

## Why

<one sentence: agents load these files at session start, so they follow the repo's own rules and terms>

## Review notes

- Every fact has a file reference. Items marked "Unverified" need a person who knows: <list or "none">.
- <removed tracked duplicates: "<item> is now maintained outside this repo". Write "none" when no tracked copy was removed: a git-ignored copy was never in the repo.>
- <each correction note from the commit messages, or "none">
```

## Publish pointer line (Step 9)

Add this line to the child repo's `AGENTS.md`, under the identity line, only after the Home has a remote:

```md
This repo is part of the <project> Home (<home remote>). Start sessions in the Home: it holds the shared skills and the map of all repos.
```
