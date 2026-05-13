# Conflict Resolutions

These rules from `/typescript-best-practices` are **overridden** by our project conventions:

| TS Best Practice says | Our convention (wins) | Reason |
|---|---|---|
| Use `interface` for object types | Inline types only | We avoid standalone type declarations entirely |
| Namespace pattern for type organization | Inline types, schema reuse | We keep types co-located and minimal |
| `type` for unions/mapped/conditional | Inline or schema-derived | Same principle: avoid standalone declarations |
| `Array<T>` syntax always | `Array<T>` preferred | Both camps agree here |
