---
name: write-java-tests
description: Use when writing, editing, or reviewing Java Spring Boot tests (JUnit, Spock, MockMvc, Testcontainers), or when asked to write tests for uncommitted Java changes. Gates each test on value first, then applies the project test conventions.
argument-hint: "[optional: file path or diff range, e.g. HEAD~3..HEAD]"
---

# Write Java Tests

Write only the tests that earn their place, then write them in the project style. The value gate comes first. The default is no test.

## Step 1 — Gather changes

```bash
git diff --name-only HEAD
git status --short
git diff HEAD
```

If `$ARGUMENTS` is provided, treat it as a diff range or file list. Keep changed production files, changed tests, and new fixtures under `src/test/resources/**`.

## Step 2 — Load project context

Read these if they exist:
- `CLAUDE.md` and `AGENTS.md` (root and any nested)
- Every file in `.claude/rules/` and `.agents/rules/`, and each project skill or doc they route to for tests
- One or two existing tests of the same type as the one you plan, to match local style

A project rule wins over this skill when they conflict. Move to Step 3 once every existing item above has been read.

## Step 3 — Gate every planned test

Apply the gate and the drop-on-sight scan:
@../../checklists/java/test-value.md

Print a verdict table. Give one row to each changed production file, each new fixture file, and each new or edited assertion:
- **KEEP**: name the recurring bug it catches.
- **DROP**: name the scan item that killed it.

Step 3 is done when every row has a verdict. Write nothing for a DROP. When every row is DROP, recommend "verify manually" and stop.

## Step 4 — Write each KEEP test

1. Pick the lightest test type that exercises the real seam: pure logic → unit test; Spring wiring → component test; database → integration test; full HTTP flow → E2E test.
2. When a test file for the class exists, extend it. Otherwise create one. When you edit a file, also remove the assertions that Step 3 dropped.
3. Follow the conventions:
@references/conventions.md

## Step 5 — Verify

1. Run each KEEP test class (`mvn test -Dtest=<TestClassName>`, or the Gradle equivalent). Integration tests can be excluded from `mvn verify`; run them by name.
2. Watch each new test fail once: break the rule it protects, see it go red, then restore the code.
3. Run the project formatter (for example `mvn fmt:format`).

The work is done when every KEEP test passes, each one was seen red, and the verdict table is in your reply.
