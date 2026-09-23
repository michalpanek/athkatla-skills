# athkatla-skills

Personal collection of Claude Code agent skills — code review, security, productivity, docs. Model agnostic, manual-invocation by default.

## Install

```
/plugin marketplace add michalpanek/athkatla-skills
/plugin install athkatla-skills@athkatla-skills
```

One plugin ships every skill. Invoke a skill as `/athkatla-skills:<skill-name>`, for example `/athkatla-skills:java-review-multi-agent`.

## Skills

| Area | Skills | Purpose |
|---|---|---|
| Code review | `ts-review`, `ts-review-lite`, `ts-review-multi-agent` | Opinionated TypeScript / JavaScript code review (single-agent, lite, multi-agent) |
| Code review | `java-review`, `java-review-multi-agent` | Opinionated Java Spring Boot code review (single-agent + multi-agent) |
| Code review | `clean-code` | Clean-code standards for TS / JS: declarative style, DRY, readonly immutability, SOLID, naming, error handling (auto-trigger) |
| Security | `dependabot-review` | Per-PR risk analysis for open Dependabot PRs (skeletal) |
| Security | `dependabot-batch-updates-pr` | Batch + alert triage workflow for any GitHub repo with Dependabot |
| Security | `supply-chain-scan` | Generic npm supply-chain scanner with user-supplied advisory lists |
| Docs | `docs` | Documentation conventions (skeletal) |
| Productivity | `productivity` | Non-code workflows (skeletal) |
| Productivity | `spade-it` | Facilitate a full S.P.A.D.E. decision session for hard contested decisions |
| Productivity | `show-me` | Show the current topic visually and re-pitch it in simple English, grounded in the ticket |
| UX | `ux-site-mapper`, `ux-ui-auditor` | Systemic UX/UI audit for Next.js apps: route mapping + principles-based audit (auto-trigger) |
| Meta | `optimize-agent-md` | Audit + split a monolithic `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` into a router + per-area files |
| Meta | `promote-rules-to-skills` | Promote `.claude/rules/*.md` into auto-discoverable skills |

All manual-invocation skills use `disable-model-invocation: true`. Code-review skills detect the project's stack in Step 0 and apply only relevant rules.

## Contributing — schema validation

Plugin and marketplace manifests must conform to the [Claude Code plugin schema](https://code.claude.com/docs/en/plugin-marketplaces#marketplace-schema). Validation runs in two places:

### Pre-commit hook (local, one-time setup)

Configure git to use the repo's bundled hook:

```bash
git config core.hooksPath .githooks
```

After this, every commit that touches a `plugin.json`, `marketplace.json`, `SKILL.md`, or `hooks.json` runs `claude plugin validate .` automatically and blocks the commit on validation failure.

To bypass for a single commit (use sparingly):

```bash
git commit --no-verify
```

### CI workflow

`.github/workflows/validate.yml` runs on every push to `main`, every PR targeting `main`, every published release, and on manual dispatch. The workflow:

1. JSON syntax check on every `*.json` (fast fail before installing claude)
2. Install Claude Code CLI on the runner
3. Run `claude plugin validate .`

Fails the workflow on any schema violation.

## Schema reference

For authoring future plugins, the authoritative schemas are:

- [Plugin manifest (`plugin.json`)](https://code.claude.com/docs/en/plugins-reference#plugin-manifest-schema)
- [Marketplace manifest (`marketplace.json`)](https://code.claude.com/docs/en/plugin-marketplaces#marketplace-schema)
- [Skill frontmatter (`SKILL.md`)](https://code.claude.com/docs/en/skills#frontmatter-reference)

Common pitfalls:
- `author` and `owner` are **objects** (`{name, email?}`), never strings
- `name` fields are **kebab-case** (lowercase + digits + hyphens only)
- Plugin `source` relative paths must start with `./` and cannot use `..`
- Setting `version` in both `plugin.json` and the marketplace entry silently uses `plugin.json` — pick one

## Credits

Thanks to [@abankowski](https://github.com/abankowski) for the `ux-audit` skills (`ux-site-mapper` + `ux-ui-auditor`) — created with his help.

## License

MIT
