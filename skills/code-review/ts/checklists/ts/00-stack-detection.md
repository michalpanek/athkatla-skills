# Stack Detection (TypeScript / JavaScript)

Detect which tools are actually in use BEFORE applying the checklist. Skip rules that reference tools not present in the project. Universal rules (naming, type safety, error handling, code style) always apply.

## Detect — run these commands

```bash
# TypeScript configs
ls tsconfig*.json 2>/dev/null

# All package.json files (root + workspace packages, depth-limited)
find . -name package.json -not -path '*/node_modules/*' -maxdepth 4 2>/dev/null

# Monorepo indicators
test -f pnpm-workspace.yaml && echo "pnpm-workspace"
test -f turbo.json && echo "turborepo"
test -f nx.json && echo "nx"
test -f lerna.json && echo "lerna"
test -f rush.json && echo "rush"

# App Router indicator (Next.js)
test -d app && echo "next-app-router-dir"
test -d src/app && echo "next-app-router-src-dir"

# Tailwind config
ls tailwind.config.* 2>/dev/null
```

Read the root `package.json` (and workspace package.json files if monorepo) and parse `dependencies` + `devDependencies`.

## Tool matrix

For each row: if the indicator is absent, skip the listed checklist scope.

| Indicator | If absent — skip these rules |
|---|---|
| `next` dep | Skip the entire **Next.js App Router** section; skip server-action rules; skip cache-tag / `unstable_cache` rules |
| `react` dep | Skip **React Component Patterns**, **Semantic HTML & Accessibility**, **Data Table Patterns**, JSX-specific rules in Code Style |
| neither `next` nor `react` (Node/CLI TS) | Skip all UI rules; treat as Node service review |
| `drizzle-orm` | Skip **Drizzle ORM & Database**, **Database Operations**; relax repository-pattern rules to apply to the project's actual ORM |
| `next-safe-action` | Skip **Server Actions (next-safe-action)** section; adapt action-error / role-auth rules to the project's actual mutation layer |
| `zod` | Skip **Schema & Validation (Zod)** section; adapt to project's validation library (Yup, Valibot, ajv, manual) |
| `react-hook-form` | Skip form-state rules (`useWatch`, `dirtyFields`, `zodFormResolver`) |
| `tailwindcss` (or `tailwind.config.*`) | Skip **Tailwind & CSS** section |
| `vitest` | Substitute test patterns with detected runner (`jest`, `node:test`, etc.) — adapt `vi.mock` references to `jest.mock` |
| `@tanstack/react-query` / `react-query` | Skip react-query cache-key rules |
| `nuqs` | Skip nuqs URL-state rules |
| `date-fns` | Adapt date-lib references to the detected library |
| `pnpm-workspace.yaml` / `turbo.json` / `nx.json` / `lerna.json` / `rush.json` / `workspaces` in root `package.json` | If ALL absent: **single-repo project** — skip monorepo rules: "Shared logic in shared package", "Database logic in DB package", "Utilities in correct package", workspace-alias rules. Treat path-alias rules (`@/*`, `~/*`) as project-local instead of cross-workspace. |

## Project conventions override

If `CLAUDE.md`, `AGENTS.md`, or `.claude/rules/` exist in the project, **read them first**. Project conventions override defaults from this checklist. When a project rule conflicts with a default checklist item, the project rule wins; flag the conflict for awareness, do not flag the violation.

## Output

Before starting the review, print a single stack-summary block:

```
Stack detected:
- Next.js 15 (App Router: yes)
- React 19
- Drizzle ORM 0.30
- Zod 3.23
- Tailwind CSS 4
- Vitest 1.6
- Workspaces: pnpm-workspace (Turborepo)
- next-safe-action: NOT installed → skipping Server Actions section
- react-hook-form: NOT installed → skipping form-state rules
- Project rules loaded from: CLAUDE.md
```

Then proceed with the rest of the review applying ONLY rules whose tools are in the detected set.
