---
name: ux-ui-auditor
description: >
  Perform a structured UX/UI audit on frontend code (HTML, JSX, TSX, CSS) and optionally
  live screenshots. Produces a markdown report grouped by category with High / Medium / Low / Info
  severity ratings. Focus areas: UI consistency, user flow & navigation, action entry points,
  button/control matrix on lists, color usage, color coding, and information structure.
  Use this skill whenever the user asks to audit, review, or critique a UI, mentions issues
  like "inconsistent design", "broken flow", "confusing buttons", "bad colors", or provides
  frontend code for design feedback. Also trigger when the user says "audit my UI",
  "review this component", "what's wrong with this design", or uploads/pastes JSX, TSX, or HTML.
---

# UX/UI Auditor Skill

> Thanks to [@abankowski](https://github.com/abankowski) for this skill.

## Overview

This skill audits frontend code (and optionally live screenshots) against established UX/UI
principles. It focuses specifically on failure patterns common in AI-generated UIs:
visual inconsistency, broken flow, buried entry points, button matrix antipatterns,
arbitrary color use, and flat information hierarchy.

The principles used as reference are distilled from a curated UX/UI design book
library and bundled with this skill. Read them from `references/principles.md`
(relative to this skill's directory) before running any audit.

---

## Inputs

**Required (at least one):**
- Frontend code: HTML, JSX, TSX, CSS, Tailwind, or inline styles
- URL or running app (if Chrome MCP is available)

**Optional:**
- Screenshots (user can provide, or agent can capture via Chrome MCP)
- Context: what the screen is supposed to do, who the user is

---

## Step 1 — Gather Input

1. **If code is provided**: read it. Note the framework and styling approach.
2. **If a URL is provided** or the user says the app is running:
   - Check if `chrome-devtools` MCP tools are available (look for `chrome-devtools:take_screenshot` in your tool list).
   - If available: use `chrome-devtools:navigate_page` to load the URL, then `chrome-devtools:take_screenshot` to capture the full page. Inform the user: *"I'll open Chrome and take screenshots — please authenticate if prompted."*
   - Take multiple screenshots: full page, any modals/drawers, key list views, form screens.
   - If Chrome MCP is NOT available: ask the user to provide screenshots manually, or proceed with code-only analysis and note the limitation.
3. **If neither code nor URL**: ask for one of the two before proceeding.

---

## Step 2 — Read the Principles

Before analyzing, load and internalize `references/principles.md`.
This file contains the distilled principles across all 7 audit categories, each attributed
to source books in your library. Use these as your evaluation baseline.

---

## Step 3 — Run the Audit

Analyze the input against all 7 categories. For each finding, determine:
- **Category** (see below)
- **Severity**: High / Medium / Low / Info
- **Location**: component name, file, line number, or screen if known
- **Issue**: what the problem is
- **Principle violated**: one-line reference to the principle (+ source book in parentheses)
- **Fix**: concrete, actionable recommendation

### Severity Guide

| Severity | Meaning |
|----------|---------|
| **High** | Blocks task completion, causes user confusion, or violates accessibility (WCAG AA). Fix before shipping. |
| **Medium** | Degrades experience, breaks consistency, or erodes trust over time. Fix before next release. |
| **Low** | Polish issue; doesn't block use but reduces quality. Fix in a design pass. |
| **Info** | Observation, pattern note, or suggestion with no urgency. |

### Audit Categories

1. **Consistency** — visual language, naming, spacing, icons, interaction states, tone
2. **Flow & Navigation** — dead ends, missing back paths, broken step sequences, modal chains
3. **Entry Points & CTAs** — action visibility, hierarchy, empty states, affordance
4. **Button & Control Matrix** — per-row action count, overflow patterns, destructive action distinction
5. **Color Usage** — palette discipline, contrast (WCAG), semantic integrity, gradient overuse
6. **Color Coding** — status color standards, semantic color map consistency, badges, legends
7. **Information Structure** — typographic hierarchy, visual weight, proximity grouping, density

---

## Step 4 — Write the Report

Output a markdown report using the structure below.
Do NOT output a flat bullet list. Group by category, severity-sorted within each category.

```markdown
# UX/UI Audit Report
**Target**: [component/page/app name]
**Date**: [today]
**Input**: [code / screenshots / both]
**Summary**: X findings — Y High, Z Medium, W Low, V Info

---

## 1. Consistency
### 🔴 High
#### [Short issue title]
- **Location**: `ComponentName.tsx:42`
- **Issue**: [What's wrong]
- **Principle**: [Principle text] *(Source: Book Title)*
- **Fix**: [Concrete recommendation]

### 🟡 Medium
...

### 🟢 Low
...

### ℹ️ Info
...

---

## 2. Flow & Navigation
...

[repeat for all 7 categories that have findings]

---

## Summary Table

| # | Category | Severity | Issue |
|---|----------|----------|-------|
| 1 | Consistency | 🔴 High | ... |
...

---

## Top 3 Priority Fixes
1. **[Most critical]** — [one-sentence why]
2. ...
3. ...
```

---

## Handling Edge Cases

- **Only CSS/styles provided, no markup**: Audit color, spacing, and typography only. Note what can't be assessed without markup.
- **Component library / design system present**: Check compliance with the system rather than raw principles. Violations of the system's own tokens are Higher severity than raw principle violations.
- **Mobile-only code**: Apply mobile-specific thresholds (44px touch targets, thumb-zone placement, etc.). Reference `Mobile UI Design Patterns` principles from the library.
- **Single small component**: Still run the full checklist; mark categories "N/A — insufficient context" where there's genuinely not enough to evaluate. Do not skip categories silently.
- **Chrome MCP available but user is not authenticated**: Capture the login screen, note it in the report header, audit whatever is visible, and prompt user to authenticate for full coverage.

---

## Calibration Notes (AI-Generated UI Antipatterns)

When auditing code or screenshots that appear AI-generated, apply extra scrutiny to:
- Components that look correct in isolation but are inconsistent with each other
- Every action mapped to a visible button (no overflow menus)
- Arbitrary color values not belonging to a coherent palette
- Equal visual weight across all elements (everything looks like a heading)
- Missing empty states and error states
- Forms with no logical field ordering
- Navigation items that exist in the code but go nowhere (`href="#"`, `onClick={() => {}}`)

These are the fingerprints of generated UI — catch them explicitly.
