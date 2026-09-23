# Stale-rule patterns

Reference for Step 2 (audit). For each pattern found in a rule, verify it against the real repo before keeping the rule.

| Pattern | Action |
|---|---|
| `@<org>/shared-*` library rules | Verify the package exists in the manifest. If not, drop. |
| `apps/*`, `packages/*`, `services/*` monorepo directories in a single-package repo | Verify with `ls`. If absent, drop. |
| MFE / `MountMicroFrontend` / `service-registry` / `root-config` rules | Verify MFE infra exists (single-spa, module federation). Otherwise drop the entire section. |
| Slack channel mapping / Sentry projects / infra names from another org | Drop unless `.github/` workflows reference them. |
| Tooling references that don't match (e.g. `eslint` rules listed but the project uses Biome / Ruff / ktlint) | Verify the actual tool. Reword or drop. |
| Specific test framework rules (Jest fixtures, Playwright POM, Pytest fixtures) | Verify the framework matches. Reword to the actual setup. |
| Specific styling library rules (styled-components, emotion, CSS Modules, Tailwind) | Verify the dependency is present. Drop or reword. |
| State management rules (Redux selectors, Zustand stores, Pinia) | Verify the library is in `dependencies`. Reword to the actual library. |
| `index.ts` barrel file rules | Check whether the codebase uses them. Keep the rule only if the convention is followed. |
| Jira / Linear / GitHub Issues references | Verify which tracker is actually used. |
| Language-specific rules for a language not present in the repo (e.g. Java rules in a Node-only project) | Drop the entire section. |
