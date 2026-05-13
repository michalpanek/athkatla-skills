---
name: supply-chain-scan
description: Detection-only scanner for npm supply-chain compromise. Searches the workstation for installed packages, lockfile pins, IOC filenames, rogue GitHub workflow files, and suspicious lifecycle scripts that match user-provided lists. All scan inputs (affected `package@version` list, IOC filenames, workflow patterns, lifecycle keywords) are supplied by the user via file path, URL, or stdin. No bundled campaign lists. Reports findings; never modifies, quarantines, or deletes anything.
when_to_use: User explicitly invokes /supply-chain-scan. Triggers include "scan for supply-chain attack", "check workstation against advisory", "is this compromise on my machine", "audit npm packages against IOC list". Do NOT auto-apply on file edits or generic dependency questions.
argument-hint: "--packages <PATH|URL|-> [--iocs <PATH|URL|->] [--workflows <PATH|URL|->] [--lifecycle <PATH|URL|->]"
disable-model-invocation: true
---

# supply-chain-scan

## Overview

Detection-only npm supply-chain scanner. Walks the user's home directory and global npm install locations and reports anything matching the supplied advisory data:

- **INSTALLED** — `node_modules/**/package.json` whose `name@version` matches the user-provided affected list
- **LOCKFILE** — `package-lock.json`, `pnpm-lock.yaml`, `yarn.lock`, `bun.lock`, `bun.lockb` referencing an affected `name@version`
- **IOC** — files whose basename matches a user-provided indicator-of-compromise filename list
- **WORKFLOW** — files under `.github/workflows/` matching user-provided path patterns
- **LIFECYCLE** — `package.json` files whose `preinstall` / `postinstall` / `prepare` scripts contain a user-provided keyword

The scanner **does NOT modify, quarantine, or delete anything**. All remediation is performed manually by the user based on the report.

## When to Use

- After a supply-chain advisory drops and you need to check whether the listed `name@version` pairs are installed
- Before running `npm install` / `pnpm install` / `yarn install` on a project pulled during a known compromise window
- When auditing a workstation against any published list of affected versions (developer laptop, CI runner, build agent)
- When investigating suspicious `preinstall` / `postinstall` scripts referenced in an advisory

## When NOT to Use

- For non-npm ecosystems (PyPI, RubyGems, Cargo, Maven) — current scanner is npm-only. See "Future work" below.
- For closed-source / proprietary registries not affected by the advisory
- As a remediation tool — this is detection only

## How to Run

The scanner takes flag-based inputs. At minimum, supply `--packages`.

```bash
# Local file
${CLAUDE_SKILL_DIR}/scan.sh --packages path/to/affected.txt

# URL (fetched via curl or wget)
${CLAUDE_SKILL_DIR}/scan.sh --packages https://example.org/affected.txt

# Stdin
cat affected.txt | ${CLAUDE_SKILL_DIR}/scan.sh --packages -

# Combine multiple advisory inputs
${CLAUDE_SKILL_DIR}/scan.sh \
  --packages https://example.org/affected.txt \
  --iocs    https://example.org/ioc-filenames.txt \
  --workflows path/to/workflow-patterns.txt \
  --lifecycle path/to/lifecycle-keywords.txt
```

Slash command (recommended inside Claude Code sessions):

```
/supply-chain-scan --packages https://example.org/affected.txt
/supply-chain-scan --packages affected.txt --iocs ioc-files.txt
```

## Inputs

All inputs are line-based. Lines starting with `#` and blank lines are ignored.

| Flag | Format | Purpose | Required |
|---|---|---|---|
| `--packages` | one `package@version` per line, e.g. `@scope/pkg@1.2.3` | Affected installed packages and lockfile pins | **Yes** |
| `--iocs` | one filename basename per line, e.g. `evil_runner.js` | Indicator-of-compromise filenames | No |
| `--workflows` | one path glob per line under `.github/workflows/`, e.g. `*/formatter_*.yml` | Rogue workflow file patterns | No |
| `--lifecycle` | one keyword per line, e.g. `evil_runner` | Substrings to flag in preinstall/postinstall/prepare scripts | No |

Each input accepts:
- A local file path
- A `http://` or `https://` URL (auto-detected; fetched with `curl` or `wget`)
- `-` to read from stdin

Sample format files are bundled under `samples/`. See `samples/example-packages.txt`, `samples/example-iocs.txt`, `samples/example-workflows.txt`, `samples/example-lifecycle.txt`.

## Environment Variables

| Variable | Purpose | Default |
|---|---|---|
| `SUPPLY_SCAN_ROOTS` | Colon-separated extra roots to scan | `$HOME` plus `/usr/local/lib/node_modules` and `/opt/homebrew/lib/node_modules` if present |
| `SUPPLY_SCAN_PRUNE` | Colon-separated directory basenames to skip | `.Trash:Library:.cache:.npm:.pnpm-store:.bun:.yarn` |

## Exit Codes

| Code | Meaning |
|---|---|
| `0` | Clean — no matches in any provided category |
| `1` | One or more matches found |
| `2` | Invalid args, missing/empty input, or required `--packages` not supplied |

## Manual Remediation

The script reports. The user acts. When matches are reported:

1. **Stop** all `npm` / `pnpm` / `yarn` / `bun` operations on the affected project
2. **Back up** untracked work to external storage before any cleanup
3. **Rotate credentials** reachable from the affected machine:
   - npm tokens: `npm token revoke <id>` then `npm login`
   - GitHub Personal Access Tokens
   - AWS / GCP / Azure access keys
   - SSH keys (generate new pairs)
   - CI/CD secrets (GitHub Actions, GitLab CI, etc.)
   - any credentials in `.env` files or shell history
4. **Clean affected repos** (manually):
   - Remove `node_modules` and the lockfile pin for the affected package
   - Clear package manager cache: `npm cache clean --force` / `pnpm store prune` / `yarn cache clean --all`
   - Reinstall pinned to a known-good pre-compromise version
5. **Verify**: run `npm audit signatures` to verify remaining package signatures
6. **Forensics**: preserve copies of any IOC files before deleting them
7. **Workflow hits**: disable GitHub Actions in affected repos (Settings → Actions → Disable), delete any unknown self-hosted runners, audit the GitHub account for repos created by an attacker

## Defensive Posture Going Forward

- Pin versions in `package.json` (strip `^` and `~`)
- Set `ignore-scripts=true` in `~/.npmrc`
- Consider Socket Firewall (`sfw`) for npm command wrapping
- Prefer `pnpm` with strict supply-chain settings: https://pnpm.io/supply-chain-security
- Subscribe to advisory feeds (GHSA, Aikido, Socket, npm advisories) and run this scanner against new lists as they drop

## Files in This Skill

- `SKILL.md` — this file
- `scan.sh` — bash 3.2+ compatible scanner
- `samples/example-packages.txt` — sample `--packages` input
- `samples/example-iocs.txt` — sample `--iocs` input
- `samples/example-workflows.txt` — sample `--workflows` input
- `samples/example-lifecycle.txt` — sample `--lifecycle` input

## Future Work

- Extend to other ecosystems: PyPI (`requirements.txt`, `Pipfile.lock`, `pyproject.toml`), Maven (`pom.xml`), Gradle, Cargo (`Cargo.lock`), Go modules (`go.sum`), RubyGems (`Gemfile.lock`)
- Add optional advisory feed fetcher (e.g. OSV.dev, GHSA) that builds the `--packages` list automatically from a CVE ID
