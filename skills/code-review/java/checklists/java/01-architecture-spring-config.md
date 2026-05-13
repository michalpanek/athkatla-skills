# Architecture & Spring Configuration

Sections: Architecture & Layering, Spring Boot Patterns, Package Placement, Configuration & Externalization, Dependency Hygiene

## Architecture & Layering
- [ ] **Controllers are stupid**: no domain logic, no business decisions, no exception throwing
- [ ] **If a result determines a response** (e.g. HTTP status), that logic is in the service, not the controller
- [ ] **Controllers only**: receive request, call service, return service result
- [ ] **No `IllegalStateException` or generic exceptions** in controllers. Use domain exceptions handled by `@ControllerAdvice`
- [ ] **Unreachable code removed**: if validation guarantees a condition, don't add redundant checks for it
- [ ] **Entities and repositories are purely for database operations**: all business logic on data belongs in service/handler classes, not in entity methods
- [ ] **Repository methods belong to their entity's repository**: `NotificationToken` queries go in `NotificationTokenRepository`, not in another repo
- [ ] **Avoid circular dependencies**: pass specific dependencies as method parameters rather than injecting at class level
- [ ] **Template Method + Strategy for repetitive scheduled jobs**: when multiple Order executors share identical logic, extract to a common pattern
- [ ] **Modify existing controllers** rather than creating parallel ones for the same resource
- [ ] **URL paths must directly name the resource**: `/carVersion` not `/dealer-settings/version`
- [ ] **Specification pattern for composable queries**: combine Specifications instead of making 6 separate calls
- [ ] **Filter field types match cardinality**: when a filter can accept multiple values, use `Set<T>` or `List<T>`, not `String` or single enum
- [ ] **Domain services don't call repositories directly**: use dedicated `*PersistenceService` classes for all DB operations. Domain services orchestrate, persistence services persist.
- [ ] **Rich domain model over anemic**: domain objects should expose meaningful business methods (`offerRequested()`, `promoteToStatus()`), not setters. Values are set inside methods with meaningful names.
- [ ] **Form entity replacement pattern**: delete-then-save for frontend form persistence (e.g. `deleteByEntityKey()` then `save()`), not update-in-place
- [ ] **Error tracking with registry service**: save processing errors to an error registry service for persistent tracking alongside notification service (e.g. Slack/Teams) alerts
- [ ] **Per-result status over HTTP status codes for multi-item operations**: when an endpoint processes multiple items (e.g. sending emails per person), return 200 with per-item status in the response body. Let the frontend inspect each item's status. Don't use 502/207 to signal partial failures. Simpler contract, easier FE handling.

## Spring Boot Patterns
- [ ] **Use `@Service` not `@Component`** for service-layer beans: `@Component` is too generic
- [ ] **Constructor injection mandatory**: use `@RequiredArgsConstructor(onConstructor = @__(@Autowired))` with `final` fields, never `@Autowired` on fields
- [ ] **All injected fields must be `final`**: guarantees thread safety and full initialization
- [ ] **HTTP semantics correct**: PUT = full replace, PATCH = partial update, POST for named actions like "publish"
- [ ] **HTTP status codes correct**: 200 = body, 204 = void, 201 with `ResponseEntity.created(uri).body(...)` or `@ResponseStatus(HttpStatus.CREATED)`, 400 for invalid state (not 304)
- [ ] **`@Valid` without Bean Validation constraints is misleading**: remove it if the DTO has no constraints
- [ ] **Permission-based over role-based security**: use `hasAuthority('PERMISSION_NAME')` not `hasAnyRole(...)` with hardcoded role lists
- [ ] **Authority naming**: `<DOMAIN>_<ACTION>` pattern (e.g. `ORDER_WRITE`, `REPORT_READ`)
- [ ] **JPA derived query method names** preferred over `@Query` for simple lookups: `Optional<X> findXByField(String field)`
- [ ] **`@Param` only needed in `@Query` methods**: not needed in default interface methods
- [ ] **`ScheduledTaskRegistrar.CRON_DISABLED`** instead of custom boolean on/off flags for scheduled tasks
- [ ] **`@Transactional`** on service methods that perform multiple database writes
- [ ] **`@Transactional` + `@Scheduled` gotcha**: transactional logic must be in a separate service method, not the scheduled method itself
- [ ] **`@Async` failures silently swallowed**: validate inputs before async boundary; NPE inside `@Async` is lost
- [ ] **Don't create unnecessary `@Bean`s**: only create a `@Bean` when something actually consumes it
- [ ] **Don't annotate a class as a Spring bean** if it doesn't need injection
- [ ] **CascadeType.ALL must be justified**: always state why it's needed
- [ ] **RabbitMQ Queue `@Bean` declaration required**: without it, messages go to "Unroutable (drop)" silently
- [ ] **Specific event classes per Rabbit topic**: `ServiceRequestCancelled` not a generic `EventServiceRequest` with `EventType` enum
- [ ] **`@ConfigurationProperties` as Java records**: type-safe config, registered via `@EnableConfigurationProperties` on the main application class
- [ ] **`@Qualifier` for multiple beans of same type**: e.g. `@Qualifier("notificationJavaMailSender")` vs `@Qualifier("reportJavaMailSender")`
- [ ] **Token refresh via `@Scheduled`**: use `fixedRate` for token refresh (not cron), ensure refresh interval < token expiry
- [ ] **WebClient buffer size**: set `ExchangeStrategies` buffer size explicitly (default 256KB is too small for some external API responses). Tune per project (e.g. 20MB).
- [ ] **`ResponseEntity.ok().build()`** for void success responses, not `ResponseEntity.ok(null)`
- [ ] **Routes inner class pattern**: use `static class Routes` with `public static final` constants for path strings in CRUD controllers

## Package Placement
- [ ] **Classes in semantically correct packages**: utility classes in `util/` or `common/`, not in feature-specific packages where they were first created
- [ ] **No unnecessary sub-packages**: if only one file would be in a sub-package, keep it in the parent
- [ ] **Shared enums belong to their domain**: don't add provider-specific values to shared domain enums. Create provider-specific enums instead.
- [ ] **Enum values semantically belong**: `ApplicationStatus` is for lifecycle statuses, not error descriptions. Error descriptions belong as constants in relevant service classes.
- [ ] **No redundant package naming**: `car.domain.dto.car` should be `car.domain.dto`
- [ ] **Static utility classes as interfaces**: classes with only static methods (Specification factories, etc.) should be declared as `interface` to prevent instantiation
- [ ] **Mapper classes in `translator/` packages**: organized per domain (e.g. `order/translator/`) with per-provider implementations

## Configuration & Externalization
- [ ] **Externalize all hardcoded values** to `application.properties`: URLs, batch sizes, costs, limits, cron expressions
- [ ] **Support env variable overrides**: `${ENV_VAR_NAME:default_value}` pattern
- [ ] **Safe config defaults**: always set a sensible default to avoid null or zero (`${file.chat.day.limit:10}`)
- [ ] **Group related config** under meaningful namespaces: `sms.segment.size`, `sms.segment.cost`
- [ ] **Feature flags config-driven**: alarm on/off should be overridable per environment
- [ ] **All user-facing strings in translation table**: not hardcoded, even non-English-only ones
- [ ] **Secrets via docker secrets or env vars**: never committed YAML values
- [ ] **HTTPS for all repository URLs** in build scripts (Maven Central turning off HTTP)
- [ ] **Profile-specific security config**: `local`/`integration-test` can disable CORS/CSRF. `dev`/`prod` must enable full `@PreAuthorize` enforcement via `@EnableGlobalMethodSecurity`
- [ ] **`application.properties` not YAML**: project uses `.properties` format, do not introduce `.yml`
- [ ] **WebClient connection pool tuning**: `maxConnections`, `pendingAcquireMaxCount`, `maxIdleTime`, `maxLifeTime` must be set explicitly for external API WebClients

## Dependency Hygiene
- [ ] **No imports from transitive/internal dependencies**: never use classes from internal packages (e.g. `io.netty.util.internal.*`). These are not public API and can change without notice.
- [ ] **New pom.xml dependencies justified**: any new dependency must have a clear reason. Don't add dependencies for functionality already available in Spring Boot.
- [ ] **No wildcard imports** (`import java.util.*`)
- [ ] **No unused imports**
- [ ] **Static imports for test assertions and matchers**
