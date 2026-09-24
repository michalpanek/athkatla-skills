# Code Comments

The default is no comment. A comment is **unverified** documentation: the compiler, the tests, and the review of the next change all pass while a comment turns false. Code stays true because something runs it; a comment stays true only by luck.

Language agnostic. Applies to production code and test code.

## Before a comment: make it unnecessary

Try these in order. Stop at the first one that works.

1. **Rename.** A precise name replaces the comment. `BY_CLOSED_DATE` hid that the key first splits open from closed items; `BY_OPEN_THEN_CLOSING_DATE` says it.
2. **Extract.** Move the expression into a named function or constant. A named predicate `IS_OPEN` replaces a comment above an inline condition.
3. **Restructure.** Remove the trap that the comment warns about. A comment said `criteria.and(...)` works although its return value is ignored; `criteria = criteria.and(...)` removes the trap and the comment.
4. **Test.** A test pins the behaviour, and its name describes it. The test name replaces a comment that describes the behaviour.

## A comment earns its place

Write a comment only when it states one of these:

1. **A business rule or domain fact.** "The issue date describes the resolution only for a sale." The code shows the filter, not the reason.
2. **A constraint from outside the code.** "The MongoDB driver throws on an empty bulk write." "The permit prevents overlapping runs only inside one instance."
3. **A deliberate choice that looks like a mistake.** "The second SETTER is deliberate: the list query adds its own only when an expiry filter is present." Without it, the next reader removes the duplicate and breaks the sort.
4. **A test setup that looks strange.** "Notification's DAO calls Firebase at module load, which throws under jsdom, so it is stubbed."

Also keep the comments that a tool or a project rule requires: suppression justifications (`@ts-expect-error`, `eslint-disable`, `@SuppressWarnings`), TODOs with a ticket key, license headers, public API docs (Javadoc, TSDoc) that state the contract, and test section markers the project prescribes (for example `// given`, `// when`, `// then`).

## Shape

1. One or two lines. A comment that needs a paragraph signals a wrong name or a wrong design.
2. The reason, not the mechanism: why, not what or how.
3. Present tense, about the code as it is now.
4. At the exact point of the surprise, not at the top of the file.

## Where other knowledge goes

| Knowledge | Home |
|---|---|
| Why the design is this way | ADR |
| What changed in this change, review discussion, "a reviewer asked", pasted compiler errors | Commit message, pull request description |
| How to operate or roll back | Pull request description, runbook |
| Domain vocabulary | `CONTEXT.md` |
| Expected behaviour, what a test verifies | The test and its name |
| Source line numbers, sections of documents the reader cannot open, paths into other repositories | Nowhere: they go stale. Link a stable ADR or delete |
| Notes to the next agent or developer | Nowhere: agents and people read code, tests, git history, and ADRs |

## Review scan

Run this on every comment line that the change adds or edits, in production code and in tests. Test REPLACE first, then give the verdict that fits:

- **REPLACE**: a rename, an extraction, a restructure, or a test makes it unnecessary. Name that change, for example the new name of the symbol under the comment.
- **KEEP**: it is one of the four kinds above, or a required comment, and it has the right shape.
- **REWRITE**: it is one of the four kinds, but it is too long, in past tense, or tells history. Give the one or two line replacement text.
- **MOVE**: it belongs in a home from the table above. Name the home.
- **DELETE**: it restates the next line, or it describes what a test verified.

Check each KEEP and REWRITE against the code in the change. A comment that the code contradicts is a bug.

Severity:
- **HIGH**: the comment is false against the code.
- **MEDIUM**: work history, a runbook, a stale reference, or a note to the next agent in the code; a comment that a rename or extraction replaces.
- **LOW**: shape issues (length, tense, placement); a comment that restates the next line.

When the change adds many comment lines for one feature, report the count once as a single MEDIUM finding, with the verdicts under it.

The scan is done when every added or edited comment line has a verdict.

### The fix for "this needs explanation"

When a finding says code is hard to understand, the suggested fix names a rename, an extraction, a restructure, or a test. Suggest a comment only when all four fail, and then give the exact comment text in one or two lines. A finding that only says "add a comment" makes the implementer write a paragraph, and the paragraph turns into a record of the review.
