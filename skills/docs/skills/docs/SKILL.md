---
name: docs
description: Documentation conventions (README structure, headings, code-block tags, links, ADRs, changelog). Draft, not yet complete.
disable-model-invocation: true
---

# Documentation Conventions

> TODO: skeleton. Build out the full ruleset.

## Standards to enforce

TODO: expand. Rough draft:

### README

- Title (H1) — one only
- Short one-paragraph description below title
- Sections in this order: Overview → Installation → Usage → Configuration → Contributing → License
- Code blocks always tagged with language (` ```bash ` not ` ``` `)
- Internal links use relative paths, not absolute repo URLs
- No broken anchor links

### Heading hierarchy

- One H1 per file (matches filename intent or page title)
- No skipped levels (H2 → H4 without H3 is a violation)
- Sentence case for H2+ (consistent across the repo)

### Code blocks

- Every fenced block has a language tag
- Long examples have a one-line caption above
- Inline code uses backticks for: identifiers, commands, file paths, env vars

### Links

- Prefer relative for in-repo, full URLs for external
- No tracking parameters
- No bare URLs in body text — wrap in `[label](url)`

### Images

- Alt-text required
- Stored in `docs/images/` or `docs/assets/` consistently
- SVG preferred for diagrams when authored, PNG for screenshots

### ADRs (if `docs/adr/` exists)

- Numbered sequentially (`0001-title.md`, `0002-...`)
- Standard sections: Context → Decision → Consequences → Status
- Status one of: Proposed / Accepted / Superseded / Deprecated

### Changelog (if `CHANGELOG.md` exists)

- Follows Keep-a-Changelog or repo-defined format consistently
- Unreleased section at top
- Each entry tagged with type: Added / Changed / Deprecated / Removed / Fixed / Security

## Behavior

When applying this skill:

1. Detect what kind of doc is being edited (README, ADR, changelog, generic markdown)
2. Apply relevant rules above
3. Surface violations as suggestions, not blocking errors
4. Cite the specific rule when flagging
