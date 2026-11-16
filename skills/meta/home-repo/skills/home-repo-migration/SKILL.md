---
name: home-repo-migration
description: Move a set of related repos to the Home Repo pattern. Builds a local Home that links the repos and holds the shared skills and docs once. Gives each repo its own agent docs on a branch. Opens PRs and publishes the Home only after approval.
argument-hint: "[optional: folder that holds the project's repos]"
disable-model-invocation: true
---

# Home Repo Migration

A **Home** is the folder that holds a project's repos. Sessions start there. It links every repo and holds the shared agent material once: skills, `AGENTS.md`, shared docs. It is a local-only git repo until Step 9. Each child repo keeps its code, history, remote and tracker, and gets its own agent docs.

The skill works for any stack, code host, tracker and harness. Work from the folder in `$ARGUMENTS`. When `$ARGUMENTS` is empty, work from the current folder.

Files in this skill's folder (use their absolute paths):
- `templates/home.md`: Home layout, `.gitignore`, `CLAUDE.md`, `AGENTS.md`, `GLOSSARY-MAP.md`, `docs/agents/`
- `templates/repo.md`: child repo files, their roles and the rules for their content
- `templates/briefs.md`: subagent brief, PR body, publish pointer line
- `scripts/linkcheck.py`: Markdown link checker (Python 3.10 or later)

## Rules for the whole run

1. **Gates.** Steps 1 to 3 only read. The plan approval in Step 3 covers Steps 4 to 7: local files, local branches and local commits. Step 8 (push and PRs) and Step 9 (publish) each need their own round. Never push before that round.
2. **Rounds.** Bring the user decisions, not facts. Look up facts yourself with the filesystem, git and the code host CLI. Number every question. Give a recommended answer and word the question so "yes" accepts it. A question that depends on an open question waits for a later round. Show rounds, plans and reports as tables.
3. **Silence is not yes.** A question that the user skips stays open. Ask it again in the next round. Do not act on it until the user answers it.
4. **Secrets stay unread.** Leave `.env`, key files and credential files unread and unmoved. Run no command that can load them, such as a test run, without the user's approval.
5. **Verify every subagent claim** before it reaches the user or a file. This includes negative claims ("file X has no tracker rules"). Open the file and check.
6. **Tracker writes.** A defect that you find goes to the tracker only with the user's approval for that item, or with a batch approval that names its exclusions. Write it as the user's team would. Leave out "created by an AI" text.
7. **Hooks.** A hook can block a command or rewrite its output. When a command prints a summary where you expect a list (for example `git add -n .`), use the bypass that the hook names.

## Step 1: Inventory the repos (read only)

Find every git repo under the folder. Skip dependency folders. Use subagents for a wide search. Record these facts per repo:
- path, remote and code host (GitHub, GitLab, Bitbucket, other, none)
- visibility (when the host has it), last commit date, current branch, uncommitted changes, worktrees
- integration branch: `develop` or `dev` first, `main` or `master` only when no other exists

For each org on a hosted code host, list the remote repos that are not cloned. A repo without a remote is "local only".

Round 1 asks:
1. Which repos does the Home point at? Recommend the repos with a commit in the last 6 months.
2. Is the Home the folder that holds the repos? Recommend yes. The Home must be above the repos, because harnesses load agent files from parent folders.
3. Is the Home personal? Recommend personal, unless the user says that the team will clone it.
4. Which harnesses do sessions use? For Claude Code, the Home needs `CLAUDE.md`. For Codex and most other agents, `AGENTS.md`. Recommend the harnesses that the setup shows.

Done when every repo is in or out and questions 2 to 4 have answers.

## Step 2: Inventory the shared material (read only)

Across the chosen repos and the user-level skill folders, list every skill (a folder with `SKILL.md`), `AGENTS.md`, `CLAUDE.md`, `CLAUDE.local.md`, `.claude/rules/*`, `.agents/*`, coding standard, glossary, `CONTEXT.md`, ADR and `docs/agents/*` file. For each repo item, run `git check-ignore -v <path>`. An ignored item exists only on this disk, so the team does not have it.

Put each item in exactly one bucket:
- **shared**: true for more than one repo of this project
- **duplicate**: the same item in several places. Diff the copies. Content that only one copy has is a claim: check it against the code before you keep it. Plan one merged copy and show it.
- **decision**: an ADR. A decision never goes to the Home (see Step 3, item 4).
- **repo-specific**: about one repo's code, commands or domain
- **installed**: from a marketplace, a plugin or a symlink to another tool
- **user-level**: a user skill for all projects. It stays user-level.
- **sensitive**: an unfixed vulnerability or other material that must not reach a remote

Also record each wrong doc: a stale claim, a link to a missing file, a wrong host. Run `python3 <skill dir>/scripts/linkcheck.py` on the existing agent docs to find dead links. A claim that you cannot check without the network is "Unverified", not wrong.

Done when every item sits in exactly one bucket.

## Step 3: Agree the plan (read only)

Show the plan as numbered items. The user approves or changes each one:
1. **Item table:** item, where it is now, git-ignored or tracked, bucket, destination. Shared and duplicate items are copied to the Home (one copy). Sensitive items go to a gitignored path in the Home. Other items stay.
2. **Repo copies:** remove the copies that moved to the Home from each repo? When every copy is git-ignored, recommend "yes": the team never had them, so the removal is local only. Else recommend "no" for a personal Home, because the team would lose them, and "yes" for a team Home that the team can clone.
3. **Draft Home `AGENTS.md`** from `templates/home.md`, with one "Other Repos" line per repo. It names the decision repo, so it stays open while item 4 is open.
4. **Decision location:** decisions for more than one repo stay in `docs/adr/` of one tracked repo. Recommend the repo that already holds cross-repo docs. Else recommend the repo that most other repos call. A local-only Home would take decisions out of the team's git.
5. **Tracker:** the tracker for each repo (GitHub, GitLab, Jira, local Markdown, other) and the tool that writes to it. Recommend what the repo docs and remotes show. When they show none, recommend "none known" and write that into `docs/agents/`.
6. **Branches:** per repo, the branch name and its base. The name says what changed (`docs/agent-docs`), not "home".
7. **Commands:** which commands the subagents may run to verify `AGENTS.md`. Recommend `--help`, lint and type check only. When the tools are not installed, recommend reading the script definitions (`package.json`, `Makefile`, build files) instead.
8. **Corrections:** each wrong doc and its correction, for repo files and for items that move to the Home.

Settle open items in more rounds. Done when the user approves every item.

## Step 4: Build the Home (gate: plan approved)

1. Run `git init` in the Home.
2. Write the allowlist `.gitignore` from `templates/home.md`. Read the file that `git config core.excludesFile` names. Add an un-ignore line for each Home path that it ignores.
3. Copy the shared and duplicate items into the Home. Copy each skill folder whole. Apply the planned merges and the approved corrections to the Home copies. Change nothing in the child repos.
4. Write `AGENTS.md`, the harness files, `docs/agents/` and the cross-cutting contexts from `templates/home.md`.

Done when the Home holds every planned item. Do not commit yet: `GLOSSARY-MAP.md` follows in Step 6.

## Step 5: Branch each repo (gate: plan approved)

For each repo:
1. When the repo has a remote, run `git fetch`. The base is the remote integration branch. Without a remote, the base is the local integration branch.
2. Run `git switch -c <branch> --no-track <base>`. Git carries the user's uncommitted edits to the new branch. When git refuses because an edit would be overwritten, stop and ask. Leave the stash untouched.

Done when every repo is on its branch and `git status --short` shows the same edits as before. Report each repo's original branch, new branch and base commit.

## Step 6: Write the per-repo docs (gate: plan approved)

1. Dispatch subagents in parallel, 2 or 3 repos each, with the brief in `templates/briefs.md`.
2. When item 2 of the plan says "yes", remove the moved copies from each repo. Before you remove a git-ignored copy, copy it to `<home>/.migration-backup/<repo>/`. Git cannot restore it. Remove the folders that the removal leaves empty.
3. Check every returned file against the rules in `templates/repo.md`. Verify each claim (rule 5).
4. In each repo, run `python3 <skill dir>/scripts/linkcheck.py --root <repo> <file>...` on the files that this run wrote or changed. Search those files for `../` and `GLOSSARY-MAP`. Fix every hit. Report problems in other files and leave them unchanged.
5. Write the Home `GLOSSARY-MAP.md` from `templates/home.md`.

Done when every repo has its files, every claim is verified, and both checks find nothing in the files of this run.

## Step 7: Commit (gate: plan approved)

1. In each repo, commit the doc files and the planned removals on its branch. Leave out the user's own uncommitted edits. Write the correction notes in the commit message. Name no Home path in the message.
2. In the Home, run `python3 <skill dir>/scripts/linkcheck.py <home>/CLAUDE.md <home>/AGENTS.md <home>/GLOSSARY-MAP.md <home>/docs <home>/<skill folder>`. Links to repo files resolve only while each repo is on its docs branch. Fix every other problem.
3. In the Home, run `git add -n .`. Check that the list holds only planned paths: no child repo, no secret, no sensitive path. Then commit.

Done when each repo and the Home have their commits and only the user's own edits stay uncommitted.

## Step 8: Push and open PRs (gate: separate round)

Ask: "1. Push each branch and open one PR per repo against its integration branch?" List the repos that have a remote. A repo that the user leaves out stays local.

For each approved repo:
1. Run `git push -u origin <branch>`.
2. Open the PR with the code host CLI (`gh pr create`, `glab mr create`). When no CLI works, give the user the compare link. When the remote has no web page, give the branch range and the `git diff --stat` output. When `gh pr edit` fails on a GraphQL deprecation, use `gh api -X PATCH repos/<org>/<repo>/pulls/<n> -F body=@<file>`.
3. Use the PR body from `templates/briefs.md`.

Done when each approved repo has a PR link, or a compare link for the user.

## Step 9: Publish the Home (optional, gate: separate rounds)

Ask: "1. Publish the Home to a remote?" Recommend "no" for a personal Home. When the user says "yes", ask in the next round:
1. Which remote and visibility? Recommend a private repo on the code host that the child repos use.
2. Add the publish pointer line to each child repo, on a new branch with its own PR? Recommend yes for a team Home.

After approval:
1. Change the local paths in the Home `AGENTS.md` to paths relative to the Home. Remove the "local-only" statement. Add the remote. Commit.
2. Run `git ls-files` in the Home. Check that it holds no sensitive path and no secret. Then add the remote and push.
3. In each approved repo, create a new branch from the integration branch. Add the publish pointer line from `templates/briefs.md` to `AGENTS.md`. Then do Steps 7 and 8 for these branches.

Done when the Home has its remote and each approved repo has a pointer PR.

## Report

Show one table row per plan item with its outcome. Then list:
- the Home commit, and the backup folder when one exists
- per repo: original branch, new branch, base commit, PR link
- every correction note and every "Unverified" item
- each skipped item, with the reason
