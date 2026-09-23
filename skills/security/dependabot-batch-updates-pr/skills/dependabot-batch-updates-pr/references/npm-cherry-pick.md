# npm-ecosystem cherry-pick mechanics

Detailed procedure for Steps 4b through 4g of `athkatla-skills:dependabot-batch-updates-pr`, for npm-ecosystem repos (`package.json` + a lockfile). Read this after Step 4a, once the Dependabot branches are fetched. Other ecosystems skip this file — see [Adapting to other ecosystems](../SKILL.md#adapting-to-other-ecosystems) in the main skill instead.

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
