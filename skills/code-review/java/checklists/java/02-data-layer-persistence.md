# Data Layer & Persistence

Sections: Entity & Persistence, Database & Migrations, JPA Query Patterns, DTOs & Records, Mapper & Translation Patterns, Data Matching & Identity, Enum Design

## Entity & Persistence
- [ ] **BaseEntity provides audit columns**: entities extend `BaseEntity` for `createdAt` (`@CreationTimestamp`) and `updatedAt` (`@UpdateTimestamp`). Don't re-declare these.
- [ ] **UUID primary keys with `GenerationType.AUTO`**: standard pattern. Use `@PrePersist` for manual UUID generation only when entity might be constructed without ID.
- [ ] **`@Enumerated(EnumType.STRING)`**: always persist enums as strings, never ordinals
- [ ] **Entity collection fields initialized**: use `new LinkedList<>()` or `new ArrayList<>()` to prevent NPE. Never leave collection fields uninitialized.
- [ ] **Custom setter overrides for state tracking**: acceptable pattern (e.g. `setApplicationStatus()` saves `previousApplicationStatus` before update)
- [ ] **`@Convert` for encrypted fields**: use `StringEncryption`, `LocalDateEncryption`, `IntegerEncryption` converters. Ensure entity class has `@Configurable` if converters need Spring injection.
- [ ] **Money as `@Embeddable`**: use `@AttributeOverride` pairs (amount + currency) per Money field. Precision: 15, scale: 2 for amounts.
- [ ] **View entities use `@Immutable`**: database views mapped with `@Immutable`, all fields `final`, `@NoArgsConstructor(force = true)` for JPA compatibility
- [ ] **`@Modifying` + `@Transactional`** required on custom delete `@Query` methods in repositories
- [ ] **LEFT JOIN FETCH** for eager loading in `@Query` methods, not `@EntityGraph` or switching to EAGER fetch type
- [ ] **`@MappedSuperclass` for shared field groups**: `BaseEntity` for audit, `HealthBaseEntity`/`SportsBaseEntity` for domain-specific shared fields

## Database & Migrations
- [ ] **VARCHAR lengths chosen deliberately**: don't default to 255 or 300. Consider actual data and justify the length.
- [ ] **Entity design anticipates reuse**: if a field/entity is for frontend form persistence only, name and document it clearly
- [ ] **Column nullability considered**: if a column may not have data at insert time, make it nullable. If always required, add NOT NULL.
- [ ] **FK constraints included**: when adding tables or PKs, include corresponding foreign key constraints in migration
- [ ] **Backward compatibility tested**: when changing types (enum to class, column types), verify existing DB data still works
- [ ] **UUID columns use PostgreSQL `uuid` type**: not `varchar()`
- [ ] **Unique constraints where appropriate**: e.g. `unique (phone_hash, topic)`
- [ ] **JPQL BETWEEN is inclusive**: use `>` and `<` operators instead to avoid off-by-one issues
- [ ] **Migration version numbers sequential**: verify current max before creating new; rebase and adjust before merging
- [ ] **Static data migrations** also applied to `prod` folder: `migration/static/` needs separate prod copy
- [ ] **Schema vs static folders**: DDL-only changes in schema folder; data/config changes in static folder
- [ ] **`@DynamicUpdate`** on entities to only update changed columns when appropriate
- [ ] **`LocalDateTime` for entity fields**: DTOs may use `ZonedDateTime` where needed for clients. Never mix in entity classes.
- [ ] **Single source of truth for date format constants**: don't create duplicate constants with slightly different names

## JPA Query Patterns
- [ ] **Batch fetching to avoid N+1**: use `findByKeyIn(Set<String>)` for bulk fetches instead of looping
- [ ] **`saveAll()` for multiple entities**: not `save()` in a loop
- [ ] **Use the entity returned by `save()`**: don't re-fetch what you just saved
- [ ] **`@EntityGraph` for selective loading**: fix lazy loading issues with `@EntityGraph(attributePaths = {"user"})` not by switching to EAGER
- [ ] **Default to LAZY loading**: only EAGER when association is always needed
- [ ] **LIMIT 1 + ORDER BY** when only one result is needed: avoid correlated subqueries
- [ ] **Always ORDER BY when order matters**: don't rely on database default ordering
- [ ] **EXISTS queries for boolean checks**: `existsByUuidAndStatus()` or `COUNT > 0` instead of fetching full entity
- [ ] **Push filter logic to database**: time-range conditions in `@Query`, not filtering in application code
- [ ] **Query filter completeness**: verify all business rule conditions are present in the query (e.g., filtering by `status` without also filtering by `result` when both matter)
- [ ] **`=` instead of `IN`** when filtering by a single value
- [ ] **JPQL constructor expressions** for typed projections: `select new ReminderData(uuid, ...)` instead of `Object[]`
- [ ] **Spring Data Projections**: use projection interfaces for list queries. Lombok `@Value` covers projection DTOs
- [ ] **Single comprehensive queries** preferred over fetch-UUIDs-then-fetch-entities pattern
- [ ] **JPQL null-safe filter**: `where (:brand) is null or version.brand.brandName in :brand`
- [ ] **Separate repository methods by query shape**: no-search / 1-word / 2-word, not one complex nullable-parameter method
- [ ] **IN clause with List parameter**: `WHERE c.firstNameHash IN :hashes` with `@Param("hashes") List<String>` eliminates utility classes
- [ ] **Null safety in JPQL named parameters**: never pass potentially null values without validation
- [ ] **Parent saved before child association**: JPA bidirectional relationship save order matters
- [ ] **Parallel branches can create conflicting Flyway migration numbers**: the later merge must rename
- [ ] **Repository default methods for query variants**: convenience overloads that delegate to parameterized `@Query` methods
- [ ] **Text blocks for complex JPQL**: use Java 17 triple-quote text blocks for multi-line `@Query` strings

## DTOs & Records
- [ ] **Never pass JPA entities as DTO fields**: entities are direct contracts with the database. A stray `.setter()` inside a `@Transactional` context silently persists changes, and lazy-loaded relationships cause `LazyInitializationException` outside the persistence context. Flatten entity fields into the DTO record.
- [ ] **DTOs in `dto/` sub-package**: when records transfer data between services within a domain, place them in a `dto/` sub-package (e.g. `order/service/dto/OrderData.java`). This separates data carriers from service logic.
- [ ] **`from(Entity)` on request records is acceptable**: when a service-layer DTO needs request-layer objects built from entity data, use `Record.from(Entity)` factory methods (e.g. `OrderData.from(OrderEntity)`) to keep mapping consistent with the project's `from()` convention.
- [ ] **Factory methods**: use `static from()` methods for object creation, following the project pattern
- [ ] **`@Schema` annotations**: all request/response records should have OpenAPI `@Schema` with descriptions and examples
- [ ] **`@JsonProperty`** when the API field name differs from the internal field name (e.g. `internalOrderId` serialized as `externalOrderId`)
- [ ] **Field naming matches domain**: internal field names should reference database tables/classes, API names can differ via annotations
- [ ] **DTO names must reflect actual content**: `ClientPhoneDto` is misleading if it contains phone AND email
- [ ] **`@JsonIgnoreProperties(ignoreUnknown = true)`** on records consuming external API responses to prevent deserialization failures when fields are added
- [ ] **`@JsonFormat` for flexible date parsing**: use optional millisecond patterns for external APIs: `pattern = "yyyy-MM-dd'T'HH:mm:ss[.SSS][.SS][.S][xxx]"`
- [ ] **Core* intermediate models**: use `Core*` prefix for bridge models between upstream and provider formats (e.g. `CorePayload`, `CoreDetails`)
- [ ] **`CoreMessages.empty()` and similar factory methods**: provide `.empty()` static factory for no-error/no-data cases instead of `new CoreMessages(Collections.emptyList(), Collections.emptyList())`

## Mapper & Translation Patterns
- [ ] **Mappers are `@Component` beans**: stateless, constructor-injected, no field mutation
- [ ] **No MapStruct**: all mapping is manual for full control over per-provider business logic. Do not introduce MapStruct.
- [ ] **Extract private helper per DTO field**: `getPersonIndividual()`, `getAdvisor()`, `getProduct()` instead of inline construction in the mapping method
- [ ] **Null-safe Money conversions**: use `Money.integerValueOfNullable()`, `Money.floatValueOfNullable()`, `Money.ofNullable()` at mapping boundaries
- [ ] **Multiple factory methods for different error sources**: `ValidationResult.from(ProviderErrorResponse)`, `ValidationResult.from(WebClientResponseException)`, `ValidationResult.from(ValidationResult)` each handle a different error format
- [ ] **XMLGregorianCalendar via utility**: use `CommonUtil.createXMlGregorianCalendarDate()` for SOAP date conversion, never construct manually
- [ ] **Switch expressions for enum mapping**: use Java 17 switch expressions with `->` for cross-domain enum translations (e.g. `EmploymentStatus` to provider-specific int codes)
- [ ] **Skip on partial failure in mapping loops**: use `continue` in for-loops when one item fails validation, not `throw` that blocks all others

## Data Matching & Identity
- [ ] **Never rely on user-provided IDs for internal matching**: user input (like `personId` from payload) can have duplicates
- [ ] **Use database-generated entity IDs** (UUID) for internal operations
- [ ] **Prefer explicit identity matching** over index-based iteration. Bundle related data into records (e.g. `OrderData`) to avoid relying on list ordering.
- [ ] **Entity is source of truth after save**: after `repository.save(entity)`, the entity has auto-generated IDs and all persisted data. Don't cross-reference request DTOs with entities by field matching (e.g. filtering by `personId`). Use the saved entity directly via `entity.getChildren().stream().map(Data::from).toList()`. The entity already has everything.

## Enum Design
- [ ] **Error codes are unique**: every `ErrorCode` enum value must have a distinct numeric code
- [ ] **Error codes are specific**: don't reuse `PROVIDER_QUERY_FAILED` for a different upstream API failure. Each distinct failure source gets its own error code.
- [ ] **Field-based enum pattern** when every constant has its own display value (constructor parameter, not a switch method)
- [ ] **No `@Deprecated` on new code**: only use `@Deprecated` on code that was previously public and is being phased out, not on newly created methods
- [ ] **Enum as configuration**: store per-enum config as final fields on the enum: `HDD_ALARM("alarm.message.hdd")`, not in service classes
- [ ] **`@Enumerated(EnumType.STRING)` always**: never use ordinal persistence for enums. String persistence survives enum reordering.
- [ ] **`@JsonValue` for JSON serialization**: use `@JsonValue` on enum getter when API representation differs from Java name (e.g. `STANDARD_PLAN` -> `"StandardPlan"`)
