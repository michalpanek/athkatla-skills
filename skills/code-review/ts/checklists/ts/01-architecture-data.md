# Architecture & Data

## Architecture & Layering
- [ ] **Feature folder convention followed**: each feature has `_lib/actions.ts`, `_lib/queries.ts`, `_lib/validations.ts`, `_lib/types.ts`
- [ ] **Server actions use `authenticatedActionClient`**: all mutations go through `next-safe-action` with role-based authorization
- [ ] **Queries live in `_lib/queries.ts`**: data fetching separate from mutations in `_lib/actions.ts`
- [ ] **Shared logic in your app-shared package**: code used by multiple apps belongs in the shared package, not duplicated
- [ ] **Database logic in your DB package**: schemas, relations, repositories, and models in proper locations
- [ ] **No business logic in UI components**: components render data and call actions, they don't contain domain logic
- [ ] **No direct database imports in apps**: use your DB package's path aliases (e.g. `@/db/schema/*`, `@/db/repositories/*`, `@/db/models/*`, `@/db/db`)
- [ ] **Utilities in correct package**: your shared package for pure utilities, your app-shared package for app-shared business logic
- [ ] **One component per file**: each component gets its own file, named in PascalCase
- [ ] **Co-located tests**: `Button.tsx` and `Button.test.tsx` in the same directory
- [ ] **API routes use `authorizeApi`**: all API endpoints check authentication and authorization before processing
- [ ] **Repositories wrap `executeQuery`**: all repository methods return `Result<T>`, no raw try/catch
- [ ] **Transform at boundaries**: map input to your types at the very beginning, map output to expected type at the very end. Don't let external API shapes spread across your TypeScript code. Validate/transform right after fetching from APIs
- [ ] **Data transformations where data originates**: if you must transform data, do it where the data is created, not where it's consumed. Reduces duplication across consumers
- [ ] **Generic components don't use domain types**: if `HistoryChart` should be reusable, it cannot import types from a specific domain module
- [ ] **Organize by feature/domain, not by type**: group date utilities in `lib/date/helpers.ts`, not scattered across feature folders. Shared components belong in shared directories
- [ ] **No "bag" files**: never create `utils.ts`, `common.ts`, `helpers.ts`, `shared.ts`, or `misc.ts`. These become dumping grounds. Name files by semantic purpose: `mappers.ts`, `model.ts`, `http.ts`
- [ ] **Non-reusable components live next to their page**: if a header is only used by `MainLayout`, keep it next to `MainLayout`, not in shared `ui/` directory
- [ ] **lib/ for non-UI logic, components/ for UI**: schemas, repositories, domain models, utilities belong in `lib/`. UI components and their helpers belong in `components/` or `ui/`
- [ ] **Domain model types in lib/ for FE/BE sharing**: types that both frontend and backend will use should live in `lib/`, not next to pages
- [ ] **Repository pattern: one entity per repository**: cross-entity operations belong in services that compose multiple repositories
- [ ] **Delete dependents before parents**: delete child entities first. If parent is deleted first and child deletion fails, you get orphaned references
- [ ] **Atomic PRs**: config changes, linting changes, and feature code in separate PRs. No change is too small for its own PR

## Server Actions (next-safe-action)
- [ ] **Always use `authenticatedActionClient`**: never create raw action handlers without auth
- [ ] **Role-based access via `.allowedRoles()`**: specify `UserType` array for authorization
- [ ] **Input validation via `.inputSchema(zodSchema)`**: all actions validate input with Zod
- [ ] **Cache revalidation in middleware**: use `.use()` to call `revalidateAppTag(CacheTag.X)` after mutations
- [ ] **Related tags revalidated together**: when one entity's mutation affects related entities, revalidate all relevant cache tags (e.g. Orders mutations also revalidate Customers; Invoices also revalidate Orders)
- [ ] **`ActionError` with context metadata**: always include `{ action, resourceId }` at minimum, plus relevant business data
- [ ] **No generic `Error` throws**: use `ActionError` instead of `throw new Error('...')` for structured logging
- [ ] **Status-aware guards on mutations**: check current status before allowing edits (e.g., cannot edit entities in terminal states such as Closed/Cancelled)
- [ ] **Transaction wraps multi-entity mutations**: `db.transaction(async (tx) => { ... })` for operations touching multiple tables
- [ ] **Helper functions accept `tx: TransactionType`**: allow transaction composition without nested transactions
- [ ] **Parallel operations within transactions**: use `Promise.all()` for independent inserts within the same transaction
- [ ] **Delta computation for collections**: compute add/remove sets for many-to-many updates, don't delete-all-then-reinsert
- [ ] **Conditional timestamp updates**: only set `completedAt` on actual status transition, not on every update
- [ ] **Metric recording for analytics**: `recordEntityCreated()`, `recordEntityAssigned()` for observability in business logic
- [ ] **Destructure `parsedInput` consistently**: prefer `({ parsedInput: { x, ...rest } })` or inline `const { x, ...rest } = parsedInput`, pick one per file

## Drizzle ORM & Database
- [ ] **UUID primary keys**: `uuid('id').primaryKey().defaultRandom().notNull()` for all tables
- [ ] **Timestamps spread pattern**: all tables use `...timestamps` from centralized `timestamps.ts`
- [ ] **`mode: 'string'` on timestamps**: returns ISO strings, not Date objects. Pass `.toISOString()` not `Date` objects
- [ ] **`$onUpdate(() => sql\`now()\`)` on updatedAt**: automatic update, no manual setting needed
- [ ] **Monetary values stored as INTEGER cents**: `$3.13` = 313, `$41.00` = 4100. Never use float/decimal for money.
- [ ] **pgEnum synced with TypeScript enum**: define TS enum first, then `pgEnum()` from its values
- [ ] **Schema-driven types via drizzle-zod**: `createSelectSchema()` for read types, `createInsertSchema()` for write types
- [ ] **Cascade delete for dependent data**: `onDelete: 'cascade'` when children cannot exist without parent
- [ ] **Set null for optional relationships**: `onDelete: 'set null'` when FK is optional
- [ ] **Self-referential FK uses `AnyPgColumn`**: `references((): AnyPgColumn => table.id)` for parent-child hierarchies
- [ ] **JSONB columns typed with `$type<T>()`**: strong typing for JSON columns
- [ ] **Generated columns for computed fields**: use `.generatedAlwaysAs()` for derived data (e.g., `fullAddress`)
- [ ] **No manual migration files**: always use `pnpm db:generate <name>` after schema changes
- [ ] **Readable enum maps**: provide `readableStatus: { [key in Status]: string }` for display values
- [ ] **Indexes on ordering columns**: `serial()` columns used for ordering should have explicit indexes
- [ ] **Relations enable `.with()` queries**: define relations in your DB package's relations directory for eager loading
- [ ] **Named relations for disambiguation**: when same table referenced multiple ways, use `relationName`

## Schema & Validation (Zod)
- [ ] **Select schema + Insert schema pattern**: `createSelectSchema(table)` for reads, `createInsertSchema(table, customValidators)` for writes
- [ ] **Update schema is partial insert**: `createInsertSchema.partial()` for update operations
- [ ] **Email normalization**: `.email().trim().toLowerCase()` in insert schemas
- [ ] **Custom validators with `.refine()`**: use for complex conditional validation (all-or-nothing address fields)
- [ ] **Schema composition**: use `.merge()`, `.extend()`, `.omit()`, `.pick()` to build form schemas from DB schemas
- [ ] **`z.infer<typeof schema>` for types**: derive TypeScript types from Zod schemas, never duplicate manually
- [ ] **`z.input<typeof schema>` for form values**: when transform exists, use `z.input` for pre-transform types
- [ ] **Validation at system boundaries**: Zod validation on all external input (forms, API requests, URL params)
- [ ] **No duplicate type definitions**: if a schema type exists, use `.pick()` / `.extend()` instead of creating new types

## Data Fetching & Caching
- [ ] **`unstableCache` wrapper on all queries**: wraps Next.js `unstable_cache` with React `cache()` for request deduplication
- [ ] **Cache tags for selective invalidation**: every cached query includes relevant `CacheTag` values
- [ ] **Standard 3600s TTL**: most queries use 1 hour revalidation unless external data
- [ ] **`EXTERNAL_DATA_CACHE_TIME`** for third-party data: QuickBooks, DigitalOcean use separate cache timing
- [ ] **Cache keys from filter objects**: `[JSON.stringify(filters)]` or `[id, JSON.stringify(filters)]`
- [ ] **`'use server'` / `'server-only'` directives**: queries.ts files must enforce server-only execution
- [ ] **Batch fetching with Maps**: use `new Map(items.map(i => [i.id, i]))` for O(1) lookups, avoid N+1 queries
- [ ] **`$dynamic()` for composable queries**: use Drizzle's dynamic query builder for complex filter/sort composition
- [ ] **Aliased tables for self-joins**: `aliasedTable(addresses, 'billing_address')` when joining same table multiple times
- [ ] **Database-level pagination**: use `.limit()` and `.offset()` in queries, not post-fetch array slicing
- [ ] **`getTableColumns()` for spread selection**: avoid manually listing all columns
- [ ] **Filter composition with `and()`**: conditionally include filter clauses, passing `undefined` for inactive filters
- [ ] **`ilike()` for case-insensitive search**: use Drizzle's `ilike` operator, not manual `toLowerCase()`
- [ ] **Relational API with `with` clause**: use Drizzle relations for eager loading nested data
- [ ] **Sorting with fallback defaults**: always provide default sort order when user hasn't specified one

## Database Operations
- [ ] **Repositories support transaction injection**: `tx: TransactionType | DatabaseType = db` parameter
- [ ] **Immutable updates**: filter out undefined values, return new objects from mutations
- [ ] **`getTableColumns()` for column selection**: avoid manually listing columns in select
- [ ] **Foreign key cascade strategy documented**: cascade for owned children, set null for optional refs
- [ ] **Junction tables for many-to-many**: e.g. `userRoles`, `orderItems` with proper FKs
- [ ] **Soft deletes for users**: `deletedAt` field, not hard delete
- [ ] **Snapshot tables for history**: `quotes-history` pattern for versioned data

## Next.js App Router
- [ ] **Minimize "use client" scope**: keep Server Components as default. If only a button needs interactivity, wrap just the button, not the whole page
- [ ] **Use `<Link>` not `router.push` for navigation**: Link supports prefetching and is semantically accessible. `router.push` is imperative and loses prefetch benefits
- [ ] **Next.js Image wildcard hostname patterns**: use `*.googleusercontent.com` not specific subdomains that can change
- [ ] **Next.js error boundaries catch server errors**: don't wrap every page in try/catch. Use `error.tsx` boundary files. Only redirect to 404 when data genuinely doesn't exist
- [ ] **Services should not know about HTTP layer**: no `FormData`, no hardcoded protocols in service functions. Services can be used by anything (API routes, server actions, CLI). Pass typed fields instead
