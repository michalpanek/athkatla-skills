# Cross-cutting

## Authentication & Authorization
- [ ] **`authenticatedActionClient.allowedRoles()`**: for server action auth
- [ ] **`authorizeApi({ allowedRoles })`**: for API route auth with redirect
- [ ] **`authorizeApiWithError({ allowedRoles })`**: for API routes returning JSON errors
- [ ] **Application-defined role enum**: roles come from a typed enum (e.g. Admin, User, Guest) used consistently across auth checks
- [ ] **`getCurrentUser()` discriminated union**: role-specific fields via type narrowing
- [ ] **Permission checks before mutations**: verify user has access to the resource being modified

## Logging
- [ ] **Use `getLogger()` / `createChildLogger()`**: from your structured logger package, never `console.log`
- [ ] **Structured logging with context**: include relevant IDs, action names, business context
- [ ] **Log AFTER the operation**: log completion, not intent
- [ ] **Error-level for exceptions**: not warn or info
- [ ] **No duplicate logging**: choose one location to log (prefer outer catch with more context)
- [ ] **Environment-aware log levels**: error in test, info in production, debug in development

## Tests
- [ ] **Vitest framework**: `describe` / `test` blocks, not Jest or Mocha
- [ ] **Table-driven tests with `test.each()`**: parameterized tests for multiple scenarios
- [ ] **Descriptive test names**: `$scenario` interpolation in `test.each`
- [ ] **Factory functions for test data**: `createTestData(overrides?)` pattern with sensible defaults
- [ ] **`vi.mock()` for module mocking**: `vi.fn()`, `vi.mocked()` for type-safe mocking
- [ ] **`vi.clearAllMocks()` in `beforeEach`**: clean state between tests
- [ ] **Cleanup in `afterEach`**: `cleanup()` from testing-library for React component tests
- [ ] **No test logic in production code**: no hardcoded test data or conditional test behavior
- [ ] **Pure unit tests preferred**: no framework context when testing business logic
- [ ] **`@testing-library/react` for component tests**: `render()`, `screen`, `userEvent`
- [ ] **Test edge cases**: empty arrays, null values, boundary conditions, error paths, division by zero
- [ ] **Environment directive for Node tests**: `// @vitest-environment node` when not testing UI
- [ ] **Arrange-Act-Assert structure**: expected values in arrange, method call in act, assertions in assert. Don't mix them
- [ ] **Capture result before asserting**: `const result = fn(...)` then `expect(result)...`. Not `expect(fn(...))...`
- [ ] **Use fake timers for date-dependent tests**: `vi.useFakeTimers()` + `vi.setSystemTime(new Date('2026-01-15'))`. Never rely on real system time
- [ ] **Shared test data in `describe` closure**: constants reused across tests can live at `describe` scope
- [ ] **Test methods under 100 lines**: extract setup and assertion helpers for readability
- [ ] **One expect per test case**: testing two things in one test is misleading. Split into separate test cases
- [ ] **Test names describe behavior, not implementation**: `should skip profiles with given email` not `should call filter with email param`
- [ ] **Narrow testing boundary**: mock only direct dependencies of the unit under test. If you mock half the app, the boundary is too wide
- [ ] **Test utilities/mocks in `__tests__/`**: mock files and test helpers must not live in production `lib/` or `src/` directories. Files without `.test.ts` suffix should not import test code
- [ ] **Mark all mock data with TODO**: mocks left in production cause hours of debugging. Always annotate: `// TODO: remove mock, use real data`
- [ ] **Consider property-based testing**: for mathematical/validation logic, `fast-check` generators catch edge cases (like division by zero) that example-based tests miss

## PR & Commit Standards
- [ ] **Conventional commits**: `feat:`, `fix:`, `refactor:`, `docs:`, `test:`, `chore:`, `perf:`, `ci:`
- [ ] **No AI attribution**: never include co-authorship or AI mention in commits
- [ ] **PR titles descriptive**: include ticket number and description, under 70 chars
- [ ] **Commit messages accurate**: must reflect actual changes, not copy-paste from previous commits
- [ ] **No generated/binary files committed**: build outputs, `.env` files must be in `.gitignore`
