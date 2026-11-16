# Kotlin Reading of the Java Checklists

Use this file when the change has `.kt` or `.kts` files. The checklists use Java syntax. Apply each rule to Kotlin files through the table below. The table wins over the "unchanged" list. A project rule wins over this file.

## Rules that apply unchanged

Apply these rules to Kotlin as written:

- Architecture & Layering, Spring Boot Patterns, Package Placement, Configuration & Externalization, Dependency Hygiene (`01`).
- Database & Migrations, JPA Query Patterns, Data Matching & Identity, Enum Design (`02`).
- Naming Precision, Validation & Safety, and the Code Style items about logic, scope, error flow, dead code, imports and DRY (`03`).
- Logging, Messaging & Events, Async Correctness, Scheduled Jobs, PR & Commit Standards (`04`).
- Clean code, test value and comment rules.

## Rules with a Kotlin equivalent

| Java rule | Kotlin reading |
|---|---|
| `Optional` rules (return type only, never `.get()`, `orElseThrow`, `Optional.empty()` on negative paths) | Use a nullable type with `?.`, `?:` and `?: throw`. Flag `!!` that has no comment that says why the value cannot be null. Flag `Optional` in Kotlin code |
| Records, `@Builder`, `@Data`, `@Getter`/`@Setter`, `@Value` | Use a `data class` with `val` properties. Flag `var` properties that never change |
| Constructor injection, `@RequiredArgsConstructor` | Use primary-constructor injection with `private val` |
| `var` for local type inference | Use `val` by default. Use `var` only when the value changes. Apply the "`var` demands extra-precise naming" rule to every local without an explicit type |
| Static factory `from()` / `of()` | Use a `companion object` factory or a top-level function. Qualify the call with the class name |
| `updateWith()` / `with...` copy methods | Use `data class` `copy(...)` |
| Static utility method instead of `@Service` | Use a top-level function or an `object` |
| `Objects.equals()`, enum `==` | Kotlin `==` is null-safe. Flag `.equals()` calls |
| Switch rules, `EnumMap` dispatch | Use an exhaustive `when` expression. A `when` over an open value needs an `else` branch that logs the unknown value |
| Primitive versus wrapper, `Boolean` when null has a meaning | Use `Boolean?` only when null has a meaning. Use non-null types for all other values |
| Domain-qualified UUID names | A `typealias` or `@JvmInline value class` id carries the domain in the type. Still name a parameter for its domain when two ids meet |
| Checked exceptions, exception wrapping | Kotlin has no checked exceptions. Apply the exception rules. A project that returns `Either` or `Result` wins: then flag a `throw` for an expected failure |
| "Always use braces" | A one-line `if` expression without braces is correct. Use braces for a multi-line body |
| "Private methods at the bottom" | Apply it to class members. Top-level private functions go after the public declarations of the file |
| Stream rules (`peek()`, single pass, method references) | Apply them to Kotlin collection and `Sequence` operations (`also` for `peek`, `::function` references) |
| "Interfaces for types" (`Map` not `HashMap`) | Use read-only `List` and `Map` in signatures. Use `MutableList` or `MutableMap` only when the caller must change the collection |
| Guava `Lists.partition()`, `Streams.zip()` | Use the standard library: `chunked`, `zip`, `windowed` |
| Varargs, `Supplier<>` | Use `vararg` and Kotlin function types. An `Array` is correct where a Java vararg API needs a spread (`*roles`) |
| Constants (`private static final`, UPPER_SNAKE_CASE) | Use `const val` for compile-time constants. A computed `val` uses camelCase |

## Kotlin-only checks

Apply these checks to every Kotlin file. They have no Java rule:

- **Jackson sees only public properties.** A `private val` has no getter, so Jackson writes `{}` or fails. A class that Jackson serializes has public `val` properties. An `ObjectMapper()` that the code builds by hand registers `jackson-module-kotlin`. Severity: HIGH when an API body is empty.
- **Java and Groovy callers.** A Kotlin `object` or `companion object` member that Java or Groovy code reads needs `@JvmStatic`, `@JvmField` or `const`. Else the caller must write `.INSTANCE` or `.Companion`. Flag `.INSTANCE` in a changed test as LOW.

## Rules to skip for Kotlin files

- Lombok rules: Lombok does not apply to Kotlin classes.
- `this.` prefix for fields in lambdas.
- `.kts` build scripts: skip every rule except Dependency Hygiene (`01`) and the clean-code rules.
