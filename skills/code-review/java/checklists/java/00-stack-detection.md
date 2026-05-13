# Stack Detection (Java / Spring Boot)

Detect which tools and frameworks are actually in use BEFORE applying the checklist. Skip rules that reference tools not present in the project. Universal rules (naming, exception handling, code style, Optional patterns) always apply.

## Detect — run these commands

```bash
# Build tool
test -f pom.xml && echo "maven"
test -f build.gradle && echo "gradle-groovy"
test -f build.gradle.kts && echo "gradle-kotlin"

# Multi-module project
grep -c '<module>' pom.xml 2>/dev/null
ls settings.gradle settings.gradle.kts 2>/dev/null

# Java version (rough check)
grep -oE '<java.version>[^<]+' pom.xml 2>/dev/null || grep -oE 'sourceCompatibility\s*=\s*[^\s]+' build.gradle* 2>/dev/null

# Application properties shape
ls src/main/resources/application*.properties src/main/resources/application*.yml src/main/resources/application*.yaml 2>/dev/null

# Spock tests present?
find src/test -name '*.groovy' 2>/dev/null | head -1
```

Read `pom.xml` (or `build.gradle` / `build.gradle.kts`) and inspect declared dependencies.

## Tool matrix

For each row: if the indicator is absent, skip the listed checklist scope.

| Indicator | If absent — skip these rules |
|---|---|
| `spring-boot-starter` / `spring-boot-starter-parent` | This is not a Spring Boot project — stop and report "Not a Spring Boot project; this checklist does not apply" |
| `spring-boot-starter-web` (or `webflux`) | Skip controller / `@RestController` / HTTP-status rules |
| `spring-boot-starter-data-jpa` (or `hibernate-core`) | Skip **Entity & Persistence**, **JPA Query Patterns**; relax repository rules to project's actual data layer |
| `spring-boot-starter-amqp` | Skip **Messaging & Events** (RabbitMQ) section |
| `spring-boot-starter-webflux` (without webmvc) | Adapt WebClient rules; skip `.block()` allowance |
| `spring-boot-starter-mail` (or javax/jakarta mail) | Skip **Email & Notifications** section |
| `cxf-codegen-plugin` / `wsdl4j` / JAX-WS deps | Skip **SOAP & External API Integration** section |
| `lombok` | Skip Lombok-specific rules (`@RequiredArgsConstructor(onConstructor=@__(@Autowired))`, `@Builder`, `@Slf4j`, `@Getter`/`@Setter`); adapt to manual constructors |
| `io.vavr:vavr` | Skip Vavr `Try<T>` rules; expect plain try/catch |
| `io.github.resilience4j` | Skip Resilience4j retry rules; expect Spring Retry or manual retry if present |
| `org.mapstruct` | Skill BANS MapStruct — flag its presence as a HIGH finding per checklist (manual mapping preferred) |
| `org.spockframework` (or `*.groovy` in `src/test/`) | Skip Spock-specific rules (`given:`/`when:`/`then:`, `@Shared`, GString interpolation); apply JUnit-only rules |
| `org.testcontainers` | Skip `TestPostgresqlContainer` patterns; adapt to project's integration-test base |
| `nl.altindag:log-captor` | Skip `LogCaptor` rules |
| `application.properties` present, no `.yml` | Apply "properties not YAML" rule |
| `application.yml` / `.yaml` present | Skip "properties not YAML" rule; project chose YAML |
| Multi-module pom.xml / `settings.gradle` with `include(...)` | Apply multi-module rules: package placement across modules, FK constraints in migration modules, etc. |
| Single-module project | Skip multi-module rules; treat package boundaries as the only structural boundary |

## Project conventions override

If `CLAUDE.md`, `AGENTS.md`, `.claude/rules/java.md`, or `.claude/rules/` exist in the project, **read them first**. Project conventions override defaults from this checklist. When a project rule conflicts with a default checklist item, the project rule wins; flag the conflict for awareness, do not flag the violation.

## Output

Before starting the review, print a single stack-summary block:

```
Stack detected:
- Java 21
- Spring Boot 3.3 (Maven, single-module)
- spring-boot-starter-web, spring-boot-starter-data-jpa
- Lombok 1.18
- Hibernate 6.5 (via spring-boot-starter-data-jpa)
- JUnit 5 + Mockito + AssertJ
- application.yml (NOT .properties) → skipping "properties not YAML" rule
- Vavr: NOT installed → skipping Try<T> rules
- Resilience4j: NOT installed → skipping retry-decorator rules
- Spock: NOT detected → skipping Spock rules
- MapStruct: NOT installed → OK (skill prefers manual mapping)
- Project rules loaded from: CLAUDE.md, .claude/rules/java.md
```

Then proceed with the rest of the review applying ONLY rules whose tools are in the detected set.
