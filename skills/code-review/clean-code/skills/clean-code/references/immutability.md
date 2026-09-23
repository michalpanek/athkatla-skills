# Immutability & Readonly Types (TypeScript)

Part Ia of the `clean-code` skill. TypeScript-specific: express immutability in the type system instead of trusting convention.

Defaulting to readonly types makes mutation a deliberate decision (you must opt out) instead of an accident (you must remember not to). Callers receive a contract: "I will not modify this." Future maintainers get a compile error before they introduce a bug, not a runtime surprise after it ships.

## Rules

- **`ReadonlyArray<T>` over `T[]` and `Array<T>`** for function parameters and return types. Default to readonly.
- **`ReadonlyMap<K, V>` over `Map<K, V>`** when the consumer should only `.get()` / `.has()` / iterate.
- **`ReadonlySet<T>` over `Set<T>`** when the consumer should only check membership.
- **`Readonly<T>` wrapper** for object types where every field should be immutable from the consumer's perspective.
- **`readonly` on properties** of one-off inline object types when the value should never be reassigned after construction.
- **`as const`** for literal-type narrowing of arrays, tuples, and object literals you don't intend to mutate.

## Examples

```typescript
// ❌ BAD: Mutable types invite mutation, hide intent
const sumPrices = (items: Item[]): number => {
  items.sort((a, b) => a.price - b.price)  // mutates caller's array!
  return items.reduce((sum, i) => sum + i.price, 0)
}

const buildIndex = (rows: Row[]): Map<string, Row> =>
  new Map(rows.map((r) => [r.id, r]))

const config: { retries: number; timeout: number } = { retries: 3, timeout: 5000 }
config.retries = 5  // surprise mutation

// ✅ GOOD: Readonly contract — compiler stops accidental mutation
const sumPrices = (items: ReadonlyArray<Item>): number =>
  [...items]
    .sort((a, b) => a.price - b.price)
    .reduce((sum, i) => sum + i.price, 0)

const buildIndex = (rows: ReadonlyArray<Row>): ReadonlyMap<string, Row> =>
  new Map(rows.map((r) => [r.id, r]))

const config: Readonly<{ retries: number; timeout: number }> = { retries: 3, timeout: 5000 }
// config.retries = 5  // ❌ TS error: Cannot assign to 'retries' because it is a read-only property

const STATUSES = ['active', 'archived', 'deleted'] as const
type Status = (typeof STATUSES)[number]  // 'active' | 'archived' | 'deleted'
```

## Function Parameters

Accepting `ReadonlyArray<T>` is a strict superset of accepting `T[]` — callers can pass either. Returning `ReadonlyArray<T>` tells callers they must not mutate. Pick the loosest input and the strictest output.

```typescript
// Accepts mutable AND readonly arrays. Returns a contract: "do not mutate me."
const filterActive = (users: ReadonlyArray<User>): ReadonlyArray<User> =>
  users.filter((u) => u.active)
```

## When You Must Mutate

If you must mutate (legitimate side effect, performance hot path, library API requires it), make it loud:
- Confine the mutation to a small, named helper.
- Document why in a comment with the constraint (perf measurement, library requirement, etc.).
- Don't expose mutable references across module boundaries.

## Mutation Smells to Catch in Review

| Smell | Fix |
|-------|-----|
| Function takes `T[]`, doesn't push or reassign | Switch to `ReadonlyArray<T>` |
| Function returns `Map<K, V>` for read-only consumers | Return `ReadonlyMap<K, V>` |
| Object literal type used as a constants table | Wrap in `Readonly<>` or use `as const` |
| `arr.sort(...)` / `arr.reverse(...)` / `arr.splice(...)` on a function param | Copy first: `[...arr].sort(...)` |
| `obj.field = value` where `obj` is a parameter | Return a new object: `{ ...obj, field: value }` |
| `Object.assign(target, ...)` mutating `target` | Use spread: `{ ...target, ...patch }` |
| Module-level `let` array filled by side effects | Build via `map`/`filter`/`reduce` and export `const` |

## Why It Matters

Mutation is the most common source of "spooky action at a distance" bugs: a function modifies a value its caller didn't expect, downstream code reads the modified value, and the cause is invisible at the call site. Readonly types push that risk to compile time. They cost nothing at runtime — TypeScript erases them — but they catch a class of bugs that no amount of test coverage reliably catches.
