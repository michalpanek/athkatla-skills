---
name: dependabot-review
description: Review one or more open Dependabot pull requests for security impact, breaking-change risk, transitive-dependency surprises, and merge-readiness. Returns a per-PR risk verdict (SAFE / NEEDS_AUDIT / BLOCK) with a one-line rationale and a suggested merge order.
when_to_use: User explicitly invokes /dependabot-review. Triggers include "review the dependabot PRs", "is this dependabot bump safe to merge", "batch the dependabot updates". Do NOT auto-apply on file edits or general PR review requests.
argument-hint: "[optional: PR number, repo path, or 'all' for every open Dependabot PR]"
disable-model-invocation: true
---

# Dependabot PR Review

> TODO: skeleton. Build out the full workflow.

## Step 1 — Gather Dependabot PRs

TODO: list open PRs from `dependabot[bot]`. Use `gh pr list --author "app/dependabot" --state open --json number,title,headRefName,body`. If `$ARGUMENTS` is a PR number, target that one. If `all`, target every open Dependabot PR.

## Step 2 — Per-PR analysis

For each PR, gather:

- Package name + old/new versions
- Semver delta (patch / minor / major / pre-release)
- Changelog or release notes (parse from PR body; fall back to fetching from registry)
- Transitive impact (lockfile diff size, new transitive deps introduced)
- Advisory ID if security update (GHSA / CVE)
- CI status

## Step 3 — Risk classification

TODO: define rubric. Rough draft:

- **SAFE** — patch bump, no advisory, CI green, changelog clean
- **NEEDS_AUDIT** — minor bump with non-trivial changelog, new transitive deps, or PR touches a critical dep
- **BLOCK** — major bump, breaking-change note in changelog, advisory unresolved, CI red, or package on a watchlist (e.g. cryptography, auth, db driver, build tooling)

## Step 4 — Suggested merge order

TODO: sort SAFE first (easy wins), then NEEDS_AUDIT grouped by package family, then BLOCK with a fix-first action.

## Step 5 — Report

TODO: output table with columns: PR #, package, old → new, semver, risk, rationale, recommended action.
