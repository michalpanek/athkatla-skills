---
name: dependabot-batch-updates-pr
description: Triage and batch-process Dependabot updates on any GitHub repo with Dependabot alerts enabled. Discovers both (a) open Dependabot PRs and (b) vulnerability alerts that have NO open PR — defaulting to HIGH and CRITICAL severities, with an explicit prompt before including MEDIUM and LOW. Then cherry-picks open PRs as clean linear commits on a dedicated branch, regenerates lockfiles, runs the project's verification scripts, and surfaces alerts without PRs for manual investigation (typically transitive vulnerabilities requiring forced version pins).
when_to_use: User explicitly invokes /dependabot-batch-updates-pr. Triggers include "batch the dependabot PRs", "merge all open dependabot updates", "what dependabot alerts have no PR yet", "consolidate dependabot updates for testing". Do NOT auto-apply on file edits or generic PR-review requests.
argument-hint: "[optional: target branch name or ticket id for the dedicated batch branch]"
disable-model-invocation: true
---

# Dependabot Batch Updates + Alert Triage

Two-pronged workflow:

1. **Alert + PR triage** — list everything Dependabot is currently flagging on this repo:
   - Open Dependabot PRs (one per dependency or group)
   - Open vulnerability alerts that do NOT yet have an associated PR (typically transitive deps)
2. **Batch apply** — cherry-pick all open PRs onto a dedicated branch as clean linear commits, run the project's verification suite, then surface no-PR alerts for manual fix-forward.

The result should be a single branch the user can open as one PR (rebaseable by GitHub, no merge commits).

## Stack assumptions

Cherry-pick mechanics here are written for **npm-ecosystem repos** (`package.json` + a lockfile). The discovery / triage steps work for any ecosystem GitHub supports for Dependabot (npm, pip, Maven, Gradle, Cargo, Composer, Bundler, NuGet, GitHub Actions, Docker, Go modules, ...). For non-npm ecosystems, adapt Step 4 to the analog "regenerate the lockfile from manifest" workflow for your package manager. See [Step 4 — Adapting to other ecosystems](#adapting-to-other-ecosystems) below.

## Step 0 — Detect stack and conventions

Run these checks to determine how to apply the rest of the workflow:

```bash
# GitHub repo identity
gh repo view --json nameWithOwner --jq .nameWithOwner

# Default base branch
gh repo view --json defaultBranchRef --jq .defaultBranchRef.name

# Package manager + lockfile (npm ecosystem)
test -f package.json     && echo "node project"
test -f pnpm-lock.yaml   && echo "pnpm"
test -f yarn.lock        && echo "yarn"
test -f bun.lock         && echo "bun"
test -f package-lock.json && echo "npm"

# Other ecosystems
test -f pyproject.toml   && echo "pip / poetry / uv / hatch (detect further)"
test -f requirements.txt && echo "pip"
test -f Pipfile.lock     && echo "pipenv"
test -f pom.xml          && echo "maven"
test -f build.gradle     && echo "gradle (groovy)"
test -f build.gradle.kts && echo "gradle (kotlin)"
test -f Cargo.toml       && echo "cargo"
test -f go.mod           && echo "go modules"
test -f Gemfile.lock     && echo "bundler"

# Workspaces / monorepo (npm)
grep -l '"workspaces"' package.json 2>/dev/null
test -f pnpm-workspace.yaml && echo "pnpm-workspace"
test -f turbo.json && echo "turborepo"

# Project scripts (npm)
test -f package.json && node -e "const p=require('./package.json'); for(const k of Object.keys(p.scripts||{})) console.log(k)" 2>/dev/null
```

Detect and remember:

- **Package manager** (drives Step 4 cherry-pick mechanics)
- **Default base branch** (where Dependabot targets PRs — usually `main` / `master` / `develop`, but Dependabot can be configured to target any branch)
- **Available scripts** (typecheck, lint, format, test, build) — substitute the project's actual script names in Step 6
- **Monorepo shape** — pin-backs in Step 4f must apply across ALL workspace manifests, not just the one flagged

Read `CLAUDE.md` / `AGENTS.md` / `.claude/rules/` if present — project conventions override defaults below.

## Step 1 — Discover open Dependabot PRs

```bash
gh pr list --author "app/dependabot" --state open \
  --json number,title,headRefName,baseRefName,labels,createdAt \
  --limit 100
```

Present the list to the user. Note which **base branch** PRs target. If multiple base branches are in play, ask the user which one to consolidate against (you can only batch PRs that share a base branch).

## Step 2 — Discover vulnerability alerts WITHOUT an open PR

Some advisories don't get a PR auto-opened (typically transitive dependencies, or packages where Dependabot can't compute a safe upgrade). Pull every open alert and remove the ones that already have a PR:

```bash
# All open Dependabot alerts on the repo
gh api "repos/$(gh repo view --json nameWithOwner --jq .nameWithOwner)/dependabot/alerts" \
  --paginate \
  --jq '.[] | select(.state == "open") | {
    number,
    severity: .security_advisory.severity,
    package: .dependency.package.name,
    ecosystem: .dependency.package.ecosystem,
    scope: .dependency.scope,
    cve: .security_advisory.cve_id,
    ghsa: .security_advisory.ghsa_id,
    summary: .security_advisory.summary,
    fixed_in: .security_vulnerability.first_patched_version.identifier,
    auto_dismissed_at,
    has_pr: (.auto_dismissed_at == null and .dismissed_at == null),
    html_url
  }'
```

UI reference for the user: `https://github.com/<owner>/<repo>/security/dependabot`

**Severity filtering — DEFAULT:** show only `critical` and `high`. Ask the user explicitly:

> "Open Dependabot alerts found: N critical, M high. Also include K medium and L low alerts? [y/N]"

If the user says no (or declines), proceed with critical + high only.

**Cross-reference with open PRs.** An alert is "covered by a PR" when the alert's `dependency.package.name` matches the package being bumped in an open Dependabot PR. List alerts NOT covered as the "no-PR" set — these will be addressed in Step 5.

Display:

```
=== Dependabot alerts without an open PR ===
| Severity | Package        | Ecosystem | CVE          | Fixed in   | Summary                          |
|----------|----------------|-----------|--------------|------------|----------------------------------|
| critical | foo            | npm       | CVE-2026-... | 2.4.1      | Prototype pollution in ...       |
| high     | bar (transitive) | npm     | CVE-2026-... | 5.0.0      | RCE via crafted input            |
```

Save this list — Step 5 walks through each.

## Step 3 — Pre-flight + dedicated branch

1. **Working tree clean?** `git status --short` must be empty. If not, ask the user to commit or stash.
2. **Dedicated branch.** Never cherry-pick directly onto the base branch. Ask the user for a branch name or ticket id (use `$ARGUMENTS` if provided):

```bash
git checkout -b chore/<ticket-id>-dependabot-batch
# or
git checkout -b chore/dependabot-batch-YYYY-MM-DD
```

A dedicated branch is recoverable — if something goes wrong mid-process, you can delete and recreate it. Cherry-picking onto the base branch directly is not safely undoable.

## Step 4 — Cherry-pick each open PR onto the batch branch

**Strategy: cherry-pick, NOT merge.** Merge commits prevent GitHub from rebasing the PR if the target repo only allows rebase merges. Cherry-pick produces clean linear commits.

Process PRs in this order to minimize conflicts:

1. **Manifest-only PRs first** (e.g. GitHub Actions, Dockerfile bumps — no lockfile churn)
2. **Small / focused dependency groups** (one library family)
3. **Catch-all / "rest-dependencies" groups last** (these tend to overlap with everything else)

### Step 4a — Fetch all Dependabot branches in one shot

```bash
PR_BRANCHES=$(gh pr list --author "app/dependabot" --state open --json headRefName --jq '.[].headRefName' | tr '\n' ' ')
git fetch origin $PR_BRANCHES
```

### Step 4b — Cherry-pick manifest changes, regenerate lockfile (npm ecosystem)

For each open Dependabot PR's head commit:

```bash
git cherry-pick <commit-hash> --no-commit

# Discard the Dependabot-generated lockfile; we'll regenerate it cleanly
git checkout HEAD -- <lockfile>            # e.g. pnpm-lock.yaml / package-lock.json / yarn.lock

# Stage only manifest changes
git add -A -- '*.json' "':!<lockfile>'"    # or scope to package.json / package-lock.json families

# Regenerate the lockfile from the new manifest
<pkg-mgr> install --no-frozen-lockfile     # e.g. pnpm install / npm install / yarn install / bun install
git add <lockfile>

git commit -m "<original commit message>" --author="<original author>"
```

### Step 4c — Resolving manifest conflicts (multiple PRs touching the same `package.json`)

When two PRs both bump entries in the same `package.json`, cherry-pick produces conflict markers. **Never parse files with conflict markers** — invalid JSON breaks the install step.

Use `git show :2:<file>` (ours) and `git show :3:<file>` (theirs) to get clean JSON from each side, then merge picking the higher semver per dependency:

```bash
for f in $(git diff --name-only --diff-filter=U | grep -E 'package\.json$'); do
  git show ":2:$f" > /tmp/ours.json
  git show ":3:$f" > /tmp/theirs.json
  node -e "
    const fs = require('fs');
    const ours = JSON.parse(fs.readFileSync('/tmp/ours.json','utf8'));
    const theirs = JSON.parse(fs.readFileSync('/tmp/theirs.json','utf8'));
    const pickHigher = (a,b) => {
      if (!a) return b;
      if (!b) return a;
      if (/^(workspace:|link:|file:|portal:)/.test(a)) return a;
      if (/^(workspace:|link:|file:|portal:)/.test(b)) return b;
      const av = a.replace(/[^0-9.]/g,'').split('.').map(Number);
      const bv = b.replace(/[^0-9.]/g,'').split('.').map(Number);
      for (let i=0;i<Math.max(av.length,bv.length);i++) {
        if ((av[i]||0) > (bv[i]||0)) return a;
        if ((av[i]||0) < (bv[i]||0)) return b;
      }
      return a;
    };
    for (const field of ['dependencies','devDependencies','peerDependencies','optionalDependencies']) {
      if (theirs[field]) {
        if (!ours[field]) ours[field] = {};
        for (const [pkg,ver] of Object.entries(theirs[field])) {
          ours[field][pkg] = pickHigher(ours[field][pkg], ver);
        }
      }
    }
    fs.writeFileSync(process.argv[1], JSON.stringify(ours,null,2)+'\n');
  " "$f"
  git add "$f"
done
```

Then regenerate the lockfile and finish the commit.

### Step 4d — When `<pkg-mgr> install` fails (version not found / yanked)

Dependabot occasionally references a pre-release or yanked version. Check what's actually available:

```bash
<pkg-mgr> view <package> versions      # npm / pnpm / yarn / bun
# or registry-specific equivalent for other ecosystems
```

Pick the closest valid version, update the manifest, and re-run install.

### Step 4e — When typecheck / build fails after a major bump

Inspect the failure:

- **Small breakage (1-5 lines)**: fix inline in this branch
- **Large breaking change**: fetch the library's migration guide (e.g. via `context7` resolve-library-id + query-docs, or the library's own docs). Then **ask the user**:
  1. Pin the package back to the previous version and tackle migration in a separate PR
  2. Proceed with the full migration here

### Step 4f — Pinning a package back (monorepo-safe)

When pinning a major bump back, search **every workspace manifest**, not just the one where the failure surfaced:

```bash
# npm-ecosystem monorepo
grep -rn "\"<package-name>\"" apps/*/package.json packages/*/package.json 2>/dev/null
# pip multi-project
grep -rn "<package-name>" **/requirements*.txt **/pyproject.toml 2>/dev/null
```

Pin in **all** locations, regenerate lockfile, re-run typecheck AND tests. Missing a pin in one workspace leaves a broken build that only surfaces later.

### Step 4g — Package manager safe-publish delays (npm / pnpm safe-chain)

Some package managers suppress packages younger than a minimum age (npm 7d, pnpm safe-chain default 3d) to protect against supply-chain attacks. Symptoms: explicit version pins or overrides resolve to the older version anyway, with a log message about "minimum age".

If a Dependabot security PR pins to a freshly-published version (< the threshold), ask the user before bypassing. Use the package manager's documented escape hatch only for known-good security patches:

```bash
pnpm install --safe-chain-skip-minimum-package-age   # pnpm
npm install --foreground-scripts ...                  # npm (no built-in age skip; check current docs)
```

The lockfile pin survives subsequent `--frozen-lockfile` installs in CI.

### Adapting to other ecosystems

The cherry-pick pattern abstracts to:

1. Apply the manifest diff from the Dependabot commit (without the resolved lockfile)
2. Regenerate the lockfile / resolved state from the new manifest
3. Commit manifest + regenerated lockfile together

| Ecosystem | Manifest | Lockfile | Regen command |
|---|---|---|---|
| npm / pnpm / yarn / bun | `package.json` (+ workspaces) | `package-lock.json` / `pnpm-lock.yaml` / `yarn.lock` / `bun.lock` | `<pkg-mgr> install` |
| pip (poetry) | `pyproject.toml` | `poetry.lock` | `poetry lock --no-update && poetry install` |
| pip (pip-tools) | `requirements.in` | `requirements.txt` | `pip-compile` |
| Maven | `pom.xml` | none (resolved at build) | `mvn dependency:resolve` |
| Gradle | `build.gradle[.kts]` | `gradle.lockfile` (if enabled) | `./gradlew dependencies --write-locks` |
| Cargo | `Cargo.toml` | `Cargo.lock` | `cargo update -p <pkg> --precise <ver>` then `cargo build` |
| Bundler | `Gemfile` | `Gemfile.lock` | `bundle update --conservative <pkg>` |
| Go modules | `go.mod` | `go.sum` | `go get <pkg>@<ver> && go mod tidy` |

For ecosystems without a Dependabot PR (Dependabot only supports the formats above), apply the same triage logic to whatever advisory feed your project uses.

## Step 5 — Address alerts without an open PR

For each alert in the "no-PR" set from Step 2:

1. **Classify**: direct vs transitive
   - Direct → the package appears in some manifest in this repo
   - Transitive → it doesn't; some other package depends on it
2. **Find the fixed version** from the alert (`security_vulnerability.first_patched_version.identifier`)
3. **Force the version** in one of these ways (npm-ecosystem):
   - Direct: add `"<package>": "<fixed-version>"` to the relevant manifest's `dependencies` / `devDependencies`
   - Transitive: add an explicit `devDependency` in the root manifest at the patched version. This hoists and forces peer resolution. **Avoid `pnpm.overrides` / `npm.overrides` for peer dependencies** — they're unreliable for peer resolution.
4. **Run install**, regenerate lockfile, commit as a separate "fix: pin <package> for <CVE>" commit.
5. **Verify** the fix actually applies: `npm ls <package>` / `pnpm why <package>` / `yarn why <package>` to confirm only the patched version is resolved.

If a fix is not yet available upstream:

- Note the alert in the PR description with the GHSA ID and a date to re-check
- Consider whether the project is actually exposed (some alerts only matter for specific code paths)
- Don't suppress the alert in the UI — leave it open so it surfaces again next scan

## Step 6 — Final verification (in this order)

After all PRs are cherry-picked AND no-PR alerts are addressed, run the project's verification suite **in this exact order**. Substitute the script names detected in Step 0:

1. **Lockfile sync**: `<pkg-mgr> install --frozen-lockfile` (or equivalent for the detected ecosystem). Must pass — this is what CI runs.
2. **Typecheck** (if applicable): the project's typecheck script.
3. **Lint** (if applicable): the project's lint script with zero-warning policy.
4. **Format**: the project's format check; commit any auto-fixes.
5. **Tests**: ask the user which test command and which language runtime version to use if the project pins one (e.g. `nvm use <version>`, `pyenv local <version>`).
6. **Build**: the project's build script. Discard any auto-generated file changes (e.g. `next-env.d.ts`, `*.gen.go`, generated TypeScript declaration files).

**IMPORTANT**: Only run format and build AFTER the lockfile is in its final state. Regenerating the lockfile mid-process can change transitive resolution, which may invalidate earlier formatting commits.

Commit any final fixes (lockfile drift, formatting) as a single follow-up commit.

## Step 7 — Summary

Present a table the user can paste into the PR description:

```
| # | Source       | Ref            | Title                                  | Status                                     |
|---|--------------|----------------|----------------------------------------|--------------------------------------------|
| 1 | Dependabot PR | #123          | bump @scope/foo from 1.2.3 to 1.3.0    | Clean cherry-pick                          |
| 2 | Dependabot PR | #124          | bump bar from 4.0.0 to 5.0.0           | Pinned back — breaking; follow-up needed   |
| 3 | Alert (no PR) | GHSA-xxxx     | CVE-2026-XXXX in baz (transitive)     | Force-pinned to 2.4.1 as root devDependency |
| 4 | Alert (no PR) | GHSA-yyyy     | CVE-2026-YYYY in qux                  | No upstream fix yet — left open            |
```

Note every package that was pinned back or skipped so the user has a clear follow-up list.

## Common pitfalls

These are illustrative — the underlying lesson generalizes beyond the specific example.

1. **Never use `git merge` for Dependabot branches.** Merge commits prevent GitHub from rebasing the PR. Always cherry-pick.
2. **Never parse files containing conflict markers.** Always use `git show :2:<file>` (ours) and `git show :3:<file>` (theirs). Conflict markers produce invalid JSON / YAML / TOML that breaks installs.
3. **Dependabot may reference yanked or pre-release versions.** Always verify install succeeds after resolving manifest conflicts.
4. **Major version bumps may contain breaking API changes.** Examples seen in the wild include library API restructures, peer-dep version requirement changes, and removed bundled subpackages. Fetch the library's migration guide before assuming a one-line fix.
5. **`--frozen-lockfile` (or equivalent) in CI fails on lockfile drift.** Always run it locally before pushing.
6. **Unstaged lockfile churn blocks the next cherry-pick.** Stage or commit lockfile changes immediately after each install.
7. **Empty cherry-picks are expected** when a later PR (e.g. "rest-dependencies") subsumes changes from an earlier PR. Skip the empty commit, don't force it.
8. **Aim for one commit per Dependabot group + one fix commit.** Clean `git bisect` boundaries.
9. **Pin-backs must cover ALL workspaces in a monorepo.** Missing one leaves a broken build that surfaces later. Always grep across every manifest.
10. **The `security` label on a Dependabot PR is set by group config, not by CVE presence.** Always cross-reference `dependabot/alerts` to confirm urgency.
11. **`overrides` / `resolutions` are unreliable for peer dependency forcing.** For transitive vulnerabilities, prefer an explicit root-level `devDependency` at the patched version.
12. **Package-manager minimum-age policies block recent publishes.** Bypass only for known-good security patches and only with explicit user approval.
13. **Run formatting / build AFTER the final lockfile state.** Intermediate lockfile regenerations can shift transitive resolutions and invalidate earlier formatting commits.
14. **Discard auto-generated build artifacts after `build`.** Tools like Next.js, codegen plugins, and various build frameworks emit files that shouldn't be committed.
15. **Always work on a dedicated branch.** Reset is safe; recovering from a botched cherry-pick on `main` is not.
16. **`gh api ... /dependabot/alerts` requires admin or security-events read scope.** If the call fails with 403, ask the user to provide a token with the right scopes (or use a fine-grained PAT with security_events: read).
