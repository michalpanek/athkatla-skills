---
name: ux-site-mapper
description: >
  Maps a Next.js application's route structure into a site map, then triggers the ux-ui-auditor
  skill to run a UX audit against that map. Use when the user wants to audit an entire
  Next.js app (not a single component), asks to "audit the whole site", "map and audit",
  "find UX issues across the app", or provides a Next.js codebase path and wants
  a systemic UX review. This skill orchestrates: (1) discovery questions, (2) site mapping,
  (3) screenshot capture via Chrome MCP if chosen, (4) handoff to ux-ui-auditor for
  per-route findings and a cross-cutting summary.
---

# UX Site Mapper Skill

> Thanks to [@abankowski](https://github.com/abankowski) for this skill.

## Overview

This skill maps a Next.js codebase into a structured site map, optionally captures
live screenshots, then hands the full map + screenshots to `ux-ui-auditor` for a
systemic audit. Issues are pinned per route, then cross-cutting patterns are
summarised separately.

Supports both `app/` router (Next.js 13+) and `pages/` router.

---

## Step 1 — Ask the User (Required)

Before doing anything, ask these two questions explicitly. Do not assume or skip.

**Question A — Map scope** (ask user to pick one):
1. **Routes + navigation links** — what routes exist and how they connect to each other
2. **Routes + shared layouts** — routes with their layout components (`layout.tsx`, `_app.tsx`, shared wrappers)
3. **Routes + user flows** — routes grouped into end-to-end journeys (e.g. auth flow, onboarding flow, core task flow)
4. **Full map** — all of the above combined

**Question B — Primary source** (ask user to pick one):
1. **Codebase only** — parse `app/` or `pages/` directory structure; no browser needed
2. **Live crawl** — launch Chrome via `chrome-devtools` MCP, navigate routes, capture screenshots
3. **Both** — codebase for structure, Chrome for screenshots on each discovered route

Also ask:
- **Codebase root path** — where is the Next.js project? (e.g. `/path/to/your-next-app`)
- **Base URL** — only if source includes live crawl (e.g. `http://localhost:3000`)
- **User role context** (optional) — admin / regular user / guest? Helps interpret auth-gated routes.

---

## Step 2 — Discover Routes from Codebase

### Next.js App Router (`app/` directory)

Walk the `app/` directory. Map filesystem path → route URL using these rules:
- `app/page.tsx` → `/`
- `app/dashboard/page.tsx` → `/dashboard`
- `app/dashboard/settings/page.tsx` → `/dashboard/settings`
- `app/(group)/page.tsx` → `/` (route groups in `()` are ignored in URL)
- `app/[id]/page.tsx` → `/[id]` — mark as **dynamic**
- `app/[...slug]/page.tsx` → `/[...slug]` — mark as **catch-all**
- `app/api/*/route.ts` → mark as **API route**, exclude from UX map

For each route, also note:
- `layout.tsx` files in scope (immediate parent + all ancestors)
- `loading.tsx` present? (yes/no)
- `error.tsx` present? (yes/no)
- `not-found.tsx` present? (yes/no)

### Next.js Pages Router (`pages/` directory)

Walk `pages/`. Map to routes:
- `pages/index.tsx` → `/`
- `pages/dashboard/index.tsx` → `/dashboard`
- `pages/[id].tsx` → `/[id]` — mark as **dynamic**
- `pages/api/*` → **API route**, exclude from UX map

Note `_app.tsx` and `_document.tsx` as global wrappers.

### Navigation Link Discovery (if scope includes navigation links)

Scan all `.tsx`/`.jsx` files for:
- `<Link href="...">` — Next.js links
- `router.push(...)` / `router.replace(...)` — programmatic navigation
- `<a href="...">` — plain anchors (flag if used for internal navigation — antipattern)

Build a links map: `source route → [target routes]`.
Flag **orphan routes** (no inbound links) and **dead links** (link targets that don't exist as routes).

### Layout Discovery (if scope includes layouts)

For each route, list its layout chain from root to leaf:
- `RootLayout (app/layout.tsx) → DashboardLayout (app/dashboard/layout.tsx) → page`

Note components imported in each layout (nav bars, sidebars, headers, footers) — these are consistency-critical shared surfaces.

### Flow Discovery (if scope includes user flows)

Group routes into logical flows by naming convention and link topology:
- Auth flow: routes containing `login`, `signup`, `register`, `forgot`, `reset`, `verify`
- Onboarding: routes containing `onboarding`, `setup`, `welcome`, `step`
- Core task: largest connected subgraph of routes (usually the main app)
- Settings: routes under `/settings`, `/profile`, `/account`
- Error/edge: `404`, `error`, `not-found`, `maintenance`

For each flow, determine:
- Entry point (first route in flow)
- Exit point (where flow ends or hands off to another flow)
- Steps in between
- Whether a back path exists at each step

---

## Step 3 — Build the Site Map Table

Output a markdown table per flow (or one table if scope is routes-only).

```markdown
## Site Map

| Route | Type | Layout Chain | Links To | Linked From | User Role | Loading | Error | Notes |
|-------|------|-------------|----------|-------------|-----------|---------|-------|-------|
| `/` | static | RootLayout | `/dashboard`, `/login` | — | all | ✓ | ✗ | Landing page |
| `/dashboard` | static | RootLayout → DashboardLayout | `/dashboard/settings` | `/` | auth | ✓ | ✓ | |
| `/dashboard/[id]` | dynamic | RootLayout → DashboardLayout | `/dashboard` | `/dashboard` | auth | ✗ | ✗ | Missing loading + error states |
| `/login` | static | RootLayout | `/dashboard`, `/signup` | `/`, `/dashboard` | guest | ✗ | ✗ | |
```

Column guide:
- **Type**: `static` / `dynamic` / `catch-all` / `(group)`
- **Layout Chain**: layouts wrapping this route, root → leaf
- **Links To**: routes this page navigates to
- **Linked From**: routes that link to this page
- **User Role**: inferred from middleware, route naming, or auth guards (`all` / `auth` / `guest` / `admin`)
- **Loading / Error**: whether `loading.tsx` / `error.tsx` exist for this route (✓/✗)

Flag these immediately in the table Notes column:
- 🔴 **Orphan route** — no inbound links
- 🔴 **Dead link** — links to non-existent route
- 🟡 **Missing error boundary** — dynamic route with no `error.tsx`
- 🟡 **Missing loading state** — async-heavy route (has `async` page component or data fetch) with no `loading.tsx`
- ℹ️ **Auth ambiguity** — can't determine required auth level from code

---

## Step 4 — Screenshot Capture (if source includes Chrome MCP)

Only proceed if `chrome-devtools` MCP tools are available (check for `chrome-devtools:take_screenshot`).
If not available, note it in the report and skip to Step 5.

For each route in the site map:
1. `chrome-devtools:navigate_page` to `{baseUrl}{route}`
2. Wait for page to settle (use `chrome-devtools:wait_for` if needed)
3. `chrome-devtools:take_screenshot` — full page
4. If the route is part of a multi-step flow, also capture intermediate states if reachable

Tell the user upfront: *"I'll navigate each route in Chrome — please authenticate if prompted and let me know when you're ready."*

Name screenshots by route: `/dashboard` → `screenshot-dashboard.png`.
If a route redirects (e.g. auth-gated route redirects to `/login`), note this in the map.

---

## Step 5 — Hand Off to ux-ui-auditor

Once the site map is built (and screenshots captured if applicable), invoke the
`ux-ui-auditor` skill with the following context package:

```
AUDIT CONTEXT:
- Site map: [the full markdown table from Step 3]
- Screenshots: [list of captured screenshots, or "none"]
- User role context: [from user input]
- Codebase root: [path]

AUDIT INSTRUCTIONS:
Run the full ux-ui-auditor checklist with these additions:
1. For each route in the site map, pin relevant findings to that route.
2. After per-route findings, produce a CROSS-CUTTING SUMMARY section (see below).
3. Flag map-level structural issues (orphan routes, dead links, missing error/loading states)
   as audit findings under a new category: "Site Structure".
```

---

## Step 6 — Output Format

The final report structure (produced by ux-ui-auditor, shaped by this skill):

```markdown
# UX Site Audit Report
**Project**: [name]
**Date**: [today]
**Routes mapped**: N
**Flows identified**: [auth, onboarding, core, settings, ...]
**Source**: [codebase / live crawl / both]
**Summary**: X findings — Y High, Z Medium, W Low, V Info

---

## Site Map
[full table from Step 3]

---

## Per-Route Findings

### `/dashboard`
#### 🔴 High — [issue title]
- **Category**: Consistency
- **Issue**: ...
- **Principle**: ... *(Source: Book)*
- **Fix**: ...

#### 🟡 Medium — ...

### `/dashboard/[id]`
...

[one section per route that has findings; routes with no findings are omitted]

---

## Cross-Cutting Summary

Issues that appear across multiple routes — these are systemic, not one-off.

| Pattern | Severity | Routes affected | Category |
|---------|----------|-----------------|----------|
| Primary CTA missing from empty states | 🔴 High | `/dashboard`, `/projects`, `/team` | Entry Points |
| Inconsistent badge color for "Active" status | 🟡 Medium | `/dashboard`, `/settings/billing` | Color Coding |
| No error boundary on dynamic routes | 🟡 Medium | `/dashboard/[id]`, `/project/[id]` | Flow & Navigation |

### Top 3 Systemic Fixes
1. **[Most impactful]** — affects N routes — [why it matters]
2. ...
3. ...

---

## Site Structure Issues
[Orphan routes, dead links, missing loading/error states from the map]
```

---

## Edge Cases

- **Monorepo**: if `app/` is not at root, ask the user for the correct path (e.g. `apps/web/app/`)
- **Large app (50+ routes)**: map all routes in the table, but for per-route audit focus on routes that are: (a) entry points to flows, (b) flagged with structural issues, (c) shared layouts. Note which routes were skipped and why.
- **No `app/` or `pages/` found**: ask the user to confirm the project root; check for custom `src/app/` or `src/pages/`
- **Auth-gated routes during Chrome crawl**: note the redirect, record the auth wall screenshot, do not attempt to bypass auth. User should be logged in before running the crawl.
- **API routes**: exclude from UX map entirely; mention count in report header as context.
