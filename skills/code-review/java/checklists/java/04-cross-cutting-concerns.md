# Cross-cutting Concerns

Sections: Logging, Messaging & Events, Async Correctness, Scheduled Jobs, SOAP & External API Integration, Email & Notifications, Tests, PR & Commit Standards

## Logging
- [ ] **Log business actions and outcomes**: "Sending order information to provider" is good. "Updating status to ORDER_SUCCESS_DELIVERY_TO_PROVIDER" is too implementation-focused.
- [ ] **Balance start/end logs**: if logging a process start, also log completion (success or failure)
- [ ] **Catch block logs describe the failure**, not what was attempted
- [ ] **MDC context method naming consistent**: follow `addXToLogs` / `removeXFromLogs` pattern
- [ ] **`log.error` for exceptions**: not `log.warn` or `log.info`. Exceptions are errors.
- [ ] **Consistent log levels**: similar operations should use the same level across the codebase
- [ ] **`kv()` keys use snake_case**: `kv("order_id", ...)` not `kv("orderId", ...)`. Stay consistent with structured logging conventions.
- [ ] **Don't log the same exception twice**: choose one location to log (prefer the outer catch with more context), not both inner and outer catch blocks.
- [ ] **Log AFTER the operation, not before**: log completion, not intent
- [ ] **Use DEBUG for internal state tracing**: not INFO
- [ ] **`[CATEGORY]` prefix pattern** for Kibana-searchable log lines: `log.info("[DEPRECATED ENDPOINT] ...")`, `log.info("[TECHNICAL REVIEW] Creating...")`
- [ ] **Include contextual identifiers in every log**: UUIDs, location keys, relevant entity IDs
- [ ] **Log no-op outcomes**: when a condition results in nothing sent/updated, log why
- [ ] **Log message grammar**: log messages should be grammatically correct English. "About to process", not "About to processing"
- [ ] **Mask PII in logs**: phone numbers as `514 *** ***`, never log message content in plain text
- [ ] **No `System.out.println`**: replace with proper log levels or remove
- [ ] **`@Slf4j` cannot be on interfaces**: only on classes
- [ ] **Log timing metrics** for significant operations: "Time to fetch all last messages"
- [ ] **Log important operations**: additions, deletions, significant state changes all deserve log entries
- [ ] **MDC cleanup convention**: `Slf4jMDCFilter` calls `MDC.clear()` in a `finally` block at the servlet filter level, so HTTP request threads are always cleaned up automatically. Manual `removeXFromLogs()` calls are for within-request clarity only (e.g., clearing a key before processing a second item). Do NOT flag missing `finally` blocks around MDC removal in controller/service code called from HTTP requests. **Exception**: `@Scheduled` methods bypass the servlet filter, so MDC cleanup at the end of scheduled methods is important.
- [ ] **MDC keys follow established set**: `request_id`, `process_id`, `case_id`

## Messaging & Events
- [ ] **Specific event classes**: `ServiceRequestCancelled`, `ServiceRequestCreated` not generic `EventServiceRequest` with `EventType` enum
- [ ] **Fanout exchange** when multiple services need the same event independently
- [ ] **Queue name constants** must be `public static final` and visible
- [ ] **Dot-separated naming** for queue names following existing convention
- [ ] **Listener consolidation**: a class can have multiple `@RabbitListener` methods; merge related listeners
- [ ] **Validate incoming messages early** with dedicated `RabbitValidator` before processing
- [ ] **`@JsonSerialize(using = LocalDateSerializer.class)`** on `LocalDate` fields in messaging objects
- [ ] **Document service startup/shutdown order** when message schema changes: include in release steps

## Async Correctness
- [ ] **If all futures are joined synchronously, the method is not async**: change return type to reflect reality
- [ ] **`@Async` failures are silently swallowed**: validate inputs before the async boundary
- [ ] **`CompletableFuture.allOf(...).join()`** for waiting on parallel provider calls: collect futures in Map, await all, then process results
- [ ] **`ExecutionService` wrapper for async with MDC**: always use the project's `ExecutionService` (preserves MDC context) instead of raw `CompletableFuture.supplyAsync()`
- [ ] **Resilience4j `Retry.decorateSupplier()`** for external API calls: wrap WebClient calls with retry config, separate retry names per endpoint

## Scheduled Jobs
- [ ] **Idempotency**: ensure scheduled operations are safe to call twice in a row
- [ ] **`@Transactional` in separate method**: not on the `@Scheduled` method itself
- [ ] **Cron expressions in properties**: guard conditions inside the method ensure correctness
- [ ] **Default branch for unknown states**: log a warning for enum values not yet handled
- [ ] **Token refresh schedules**: `fixedRate` for token providers (e.g. `55*60*1000` for tokens expiring in 1 hour), ensuring refresh happens before expiry

## SOAP & External API Integration
- [ ] **`SoapRequestService<REQUEST, RESPONSE>` generic pattern**: typed SOAP service with `sendRequest()` and WS-Security authentication callback
- [ ] **WS-Security UsernameToken**: OASIS namespace, PasswordText type. Never construct manually; use project's `SoapRequestService` or `TokenizedSoapRequestService`.
- [ ] **WSDL code generation**: CXF maven plugin generates from WSDL/XSD. Never hand-edit generated classes. Add Lombok `@Getter`/`@Setter` annotations to generated classes.
- [ ] **Resilience4j retry config**: separate retry names per external API endpoint. Retry on `WebClientResponseException` only.
- [ ] **WebClient `.block()` for synchronous calls**: acceptable in non-WebFlux application. Wrap with Resilience4j retry decorator.
- [ ] **SSL context via custom provider**: use your certificate provider for mutual TLS. Never hardcode certificate paths.

## Email & Notifications
- [ ] **Dual mail sender pattern**: separate `JavaMailSender` beans for different domains (e.g. report vs notification), selected via `@Qualifier`
- [ ] **Thymeleaf for HTML emails**: templates in `mail/` resource directory, `.html` suffix, UTF-8 encoding. Build context in private `buildContext()` method.
- [ ] **Notification service (e.g. Slack/Teams) for operational alerts**: scheduled every minute to flush notification queue. Use for processing failures, not for business events.

## Tests

**FIRST-CHECK gate before any style/structure item below:** For every net-new test file or new `@Test` method in this PR, answer *"does this test catch a real bug the compiler / type system / an existing integration test doesn't?"* If the answer is "no" or "only during this one change," flag it as **MEDIUM — propose removal** and STOP evaluating that test against the rest of the checklist (no point grading the style of a test that shouldn't exist). Only proceed to style/structure items for tests that pass the first-check gate.

- [ ] **Low-signal test (propose removal)**: flag any net-new test that only verifies trivial mapping (`from()` round-trip, getter/setter, field-copy through layers), framework behavior (Hibernate writing a column, Jackson (de)serializing a record), or "when I pass X I get X back" plumbing. Project stance: coverage-for-coverage's-sake is not a goal; tests must catch a concrete, recurring failure mode (business logic, branching, validation rules, integration seams). If a test catches nothing the compiler / existing integration tests don't, its correct severity is **MEDIUM — propose removal**, not LOW. When suggesting a replacement, prefer an integration test against real Postgres (`TestPostgresqlContainer`) + MockMvc over a new unit test.
- [ ] **Do NOT flag "missing test coverage" as an issue** for changes with no business logic to protect (pure mapping edits, nullable column adds, record field additions that pass through unchanged, getter/setter additions). Manual verification is the accepted default in this project for such changes.
- [ ] **Test cases first, helpers last**: when opening a test file, you see tests immediately, not setup
- [ ] **`//given //when //then`** sections in every test method
- [ ] **`@Nested` only with 2+ groups**: don't nest if there's only one group
- [ ] **Descriptive `@Nested` names**: `WhenRequired`, `WhenOptional`, not `RequiredDefaults`
- [ ] **Capture results before asserting**: `var result = ...` then `assertThat(result)...`
- [ ] **`any()` with expected class**: use `any(OrderRequest.class)` not bare `any()`
- [ ] **Extract expected values to `//given`**: never inline magic strings or numbers in assertions. Create named variables like `var expectedTotal = ...`
- [ ] **Name all magic numbers**: `EXPECTED_ITEM_COUNT` not raw `6`
- [ ] **Extract deeply nested getter chains**: if `response.orderInformation().get(0).orderDetails().items()` appears 3+ times, create a helper method
- [ ] **Test methods under 100 lines**: extract setup and assertion helpers
- [ ] **Test resource file names match content**: `priceResponseWithTimeoutException.json` must actually contain a timeout exception response
- [ ] **Use `@LocalServerPort`** instead of hardcoding test server ports
- [ ] **Separate test utilities by purpose**: `TestUtil` for general, `E2ETestUtil` for E2E, `DatabaseTestUtil` for DB cleanup
- [ ] **Integration test profile named descriptively**: not `local`, use `integration-test` to clearly indicate purpose
- [ ] **No test class inheritance**: avoid extending test classes. Use composition, `@Nested`, and shared utilities. Exception: `TestPostgresqlContainer` base class for integration tests.
- [ ] **Test fields are `private`**: constants and mocks in test classes should be private
- [ ] **Use framework cleanup mechanisms**: `@AfterEach` / `@BeforeEach` (JUnit) or `cleanup:` (Spock) instead of manual `deleteAll()` at end of test body
- [ ] **Complex test conditions extracted to helpers**: unreadable ternary conditions in assertions should be named helper methods
- [ ] **No redundant parametrized test columns**: don't include duplicate columns where values are always identical
- [ ] **Security tests must not be skipped**: if Spring Security is disabled in test profile, destructive endpoints still need dedicated security tests
- [ ] **Separate test concerns**: PDF merging tests separate from order sending tests, etc.
- [ ] **When in doubt**, check existing test files like `OrderMapperTest`, `RequestValidatorTest` for project standards
- [ ] **Test method names as factual statements**: "chat notification sent only when 5 minutes since last message" not imperative commands
- [ ] **Tests must verify response body content**: not just HTTP status code
- [ ] **Parametrize tests for zero, one, and many items**
- [ ] **Use repository directly for `@AfterEach` cleanup**: not endpoint calls
- [ ] **Test fixture data must use values** that cannot coincidentally exist in production data
- [ ] **Security regression tests**: verify deleted/anonymized client data never leaks through any endpoint
- [ ] **Plain unit tests preferred**: no Spring context when testing pure business logic (executes in < 1 sec)
- [ ] **`@MockBean` causes new Spring context**: potentially causing port conflicts; use `RANDOM_PORT`
- [ ] **Named column inserts in test SQL**: `INSERT INTO table (id, created, ...)` for clarity
- [ ] **Remove unused test data**: clean up `data.sql` rows no longer referenced
- [ ] **Delete permanently failing tests**: don't keep tests that never pass
- [ ] **`@Shared` in Spock** for shared test constants
- [ ] **GString interpolation in Spock**: `"/api/v1/user/$uuid"` not `'/api/v1/user/' + uuid`
- [ ] **Use domain objects in test setup**: not raw multi-arg constructors that break when signature changes
- [ ] **Test `when:`/`then:` labels must be accurate**: inaccurate Spock labels are misleading documentation
- [ ] **Keep test names in sync**: when renaming methods under test, update test names too
- [ ] **Make stub constants `public static final`**: refer to them from tests for clarity
- [ ] **Test edge cases**: invalid input, missing entities, boundary conditions, empty collections
- [ ] **`@SpringBootTestProfile`** for component tests with H2 (custom annotation combining `@SpringBootTest` + `@ActiveProfiles("local")`)
- [ ] **`TestPostgresqlContainer`** for integration tests: extends this base class, uses PostgreSQL 16.1 with container reuse, `@DynamicPropertySource` for DB config
- [ ] **`DatabaseTestUtil.clear()`** in `@BeforeEach`: clean all tables in dependency order for test isolation
- [ ] **`TestUtil.readObjectFromFile()`** for loading JSON fixtures: organize by domain in `src/test/resources/` (order/, translator/, responses/, entities/)
- [ ] **`@DirtiesContext`** on integration tests that modify Spring context state
- [ ] **`@DynamicPropertySource` for mock server URLs**: inject mocked API endpoints dynamically, not via hardcoded properties
- [ ] **`ArgumentCaptor<T>`** for verifying complex method arguments: capture, then assert on captured values
- [ ] **`LogCaptor`** (nl.altindag.log) for verifying log output in tests
- [ ] **MockMvc setup with `standaloneSetup()`**: include `.setControllerAdvice(RequestProcessingExceptionHandler.class)` to test exception handling
- [ ] **Security in MockMvc tests**: use `.with(user("user").authorities(() -> "AUTHORITY_NAME"))` for auth context
- [ ] **EntityManager `flush()` + `clear()`** in integration tests: force fresh entity load from DB, don't rely on first-level cache
- [ ] **`RANDOM_PORT` for Spring context tests**, `DEFINED_PORT` only for E2E tests that need predictable mock server URLs

## PR & Commit Standards
- [ ] **PR titles descriptive**: include ticket number and description, not "WIP"
- [ ] **Commit messages accurate**: must reflect actual changes
- [ ] **Don't bundle external contract changes with internal refactoring** in the same PR
- [ ] **ADR references** for non-obvious design decisions
