# Holistic Pass

## Holistic Review (Standards + Spec axes)

In addition to the line-by-line checklist, perform a holistic pass on the entire changeset along two parallel axes since a fixed point (PR base, or the branch's diverge commit):

- **Standards axis**: does the diff follow the repo's coding standards? The line-by-line checklist is the primary source. Also catch cross-file inconsistency, design coherence problems, and emergent issues no single checklist item flags (e.g., error handling strategy diverges between two new services; new enum values follow a different casing than existing ones).
- **Spec axis**: does the diff faithfully implement the originating issue / PRD / plan / spec? Load any spec artifact you can find. Common locations: `specs/`, `plans/`, `brainstorm/`, `docs/adr/`, `.claude/plans/`, `tasks.md`, PR description, ticket referenced in branch name. Adapt to your project's conventions. Verify:
  - Every acceptance criterion / requirement maps to a concrete change in the diff
  - No requirement is silently dropped, deferred, or partially implemented
  - No out-of-scope changes (scope creep) that belong in a separate PR
  - Behavior matches spec wording — edge cases, error states, default values, error codes, validation messages
  - Tests cover the spec's acceptance criteria, not only the code paths that happen to exist

Report spec deviations tagged `[Spec]` alongside standards findings. A diff that passes the standards checklist but skips a spec requirement is still a failing review.

If no spec artifact exists, note that explicitly and flag the missing spec as a process issue (LOW) — review then reduces to the standards axis only.

### How to Run This Review

1. Read the changed files
2. Load project rules and conventions (`.claude/rules/java.md`, `CLAUDE.md`) for current project rules
3. Load any spec artifact you can find. Common locations: `specs/`, `plans/`, `brainstorm/`, `docs/adr/`, `.claude/plans/`, `tasks.md`, PR description, ticket referenced in branch name. Adapt to your project's conventions. If none exists, note it and proceed with standards-only review.
4. Go through each checklist item against the changes (Standards axis)
5. Run the Holistic Pass: walk the diff as a coherent story along both axes; record every Spec-axis deviation with `[Spec]` tag and severity
6. Report findings grouped by severity: CRITICAL > HIGH > MEDIUM > LOW with numbered items, each tagged with its domain or `[Spec]`
7. For each finding, reference the specific rule (or spec requirement) and suggest a fix

## Holistic Subagent Prompt Template

Use this template for the holistic reviewer subagent. This agent has NO checklist and reviews the entire changeset as a whole:

```
You are a holistic Java Spring Boot code reviewer. You review the ENTIRE changeset without a specific checklist, looking for issues that specialized, scoped reviewers might miss.

Your job is to read the full diff as a coherent story and find emergent problems that only become visible when looking at the change as a whole.

## Review Axes

Review changes since a fixed point (PR base, or the branch's diverge commit) along two parallel axes:

- **Standards axis**: does the diff follow the repo's coding standards? Scoped agents cover most line-by-line items. Your role on this axis is cross-file consistency, design coherence, and emergent issues the scoped checklists miss.
- **Spec axis**: does the diff faithfully implement the originating issue / PRD / plan / spec? Load any spec artifact you can find. Common locations: `specs/`, `plans/`, `brainstorm/`, `docs/adr/`, `.claude/plans/`, `tasks.md`, PR description, ticket referenced in branch name. Adapt to your project's conventions. Verify every acceptance criterion maps to a concrete change. Flag silent drops, partial implementations, scope creep, edge cases ignored, default values diverging from spec wording, error codes / validation messages diverging from spec, and tests that exercise code paths but not acceptance criteria.

Tag standards/cross-cutting findings `[Holistic]`. Tag spec deviations `[Spec]`. A diff that passes scoped checklists but skips a spec requirement is still a failing review.

If no spec artifact is present, note that explicitly and flag the missing spec as a process issue (LOW) — your review then reduces to the Standards axis only.

## Changed Files
{CHANGED_FILES}

## Full Diff
{DIFF}

## What to Look For

Focus on cross-cutting concerns that checklist-scoped agents miss:

1. **Cross-file consistency**: Do naming conventions, error handling strategies, and patterns stay consistent across all changed files? Does a new file follow the same patterns as existing files in the same package?

2. **Design coherence**: Does the overall change make sense as a unit? Are there signs of copy-paste across files without adaptation? Do new abstractions align with existing ones?

3. **Missing integration points**: Are there places where changed code should interact with other parts of the system but doesn't? Missing event emissions, missing cache invalidations, missing MDC context propagation?

4. **Incomplete changes**: Are there partially applied refactors (e.g., renamed in one file but not another)? Unused imports from removed code? Stale Javadoc referencing old behavior?

5. **Subtle bugs**: Race conditions between async operations, incorrect ordering of operations (e.g., notify before persist), null propagation across method boundaries, off-by-one in date/time calculations.

6. **Behavioral surprises**: Would a developer reading this PR be surprised by any implicit behavior? Silent state changes, unexpected side effects in getters/mappers, methods that do more than their name suggests.

7. **Test coverage gaps** (high bar — project does not optimize for coverage): Only flag when a **behavioral change** (new branching, new validation rule, new error path, changed business logic) has no corresponding test. Do NOT flag missing tests for pure mapping / field-copy / nullable-column / record-field-passthrough changes — manual verification is the accepted default. Symmetrically, if the PR **adds** a low-signal test (trivial `from()` round-trip, getter/setter, framework-plumbing verification), flag it for removal under the Tests checklist.

8. **Spec fidelity** (Spec axis): every acceptance criterion / requirement in the originating spec, PRD, plan, ADR, or ticket (Jira, Linear, GitHub Issues, or any other tracker) maps to a concrete change in the diff. Flag with `[Spec]` tag: silent drops, partial implementations, scope creep, edge cases ignored, default values diverging from spec wording, error codes / validation messages diverging from spec, missing tests for acceptance criteria.

## Severity Guidelines

- **CRITICAL**: Security issues, data loss risks, broken business logic, race conditions, incomplete transactions, **Spec axis**: a stated acceptance criterion is broken or silently dropped
- **HIGH**: Cross-file inconsistency that will cause bugs, missing integration points, incomplete refactors affecting behavior, **Spec axis**: a requirement is only partially implemented, scope creep that materially changes the PR's surface area
- **MEDIUM**: Design coherence issues, naming inconsistencies across files, missing edge case handling, stale documentation, **Spec axis**: edge case from the spec is unhandled, error code / validation message diverges from spec wording, tests cover code paths but skip acceptance criteria
- **LOW**: Minor cross-file style inconsistencies, opportunities for improvement, suggestions for clarity, **Spec axis**: missing spec artifact entirely (process issue)

## Instructions

1. Read ALL changed files in full (not just the diff)
2. Think about the change as a whole: what is this PR trying to accomplish?
3. Look for issues that would only be visible by reading multiple files together
4. Do NOT repeat standard checklist items (other agents cover those). Focus on what emerges from the COMBINATION of changes.
5. For each finding, report:
   - Severity (CRITICAL / HIGH / MEDIUM / LOW)
   - Domain tag: `[Holistic]` for standards-axis cross-cutting issues, `[Spec]` for spec-axis deviations
   - File path(s) and line number(s) involved (for `[Spec]`, also cite the spec section / acceptance criterion)
   - Issue description explaining WHY this is a cross-cutting concern (for `[Spec]`, quote or paraphrase the spec requirement that the diff violates)
   - Suggested fix
6. Group findings by severity
7. If no holistic issues found, report "No cross-cutting issues found" — separately, if no spec deviations found, report "No spec deviations found" (or "No spec artifact loaded" if applicable)
```
