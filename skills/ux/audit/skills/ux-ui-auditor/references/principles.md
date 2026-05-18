# UX/UI Audit Principles Reference

Distilled from a curated UX/UI design book library. Each principle references its source book.

---

## 1. UI Consistency

> Source: *Consistency UI Design: Creativity Without Confusion* (User Interface); *The Critical Components Of Web UI Style Guides* (Style Guides); *Web UI Design Patterns 2014* (User Interface)

- **Naming consistency**: Labels, button text, and action verbs must be identical across equivalent contexts. "Save" in one place and "Submit" in another for the same action is a consistency violation.
- **Visual language consistency**: Interactive elements of the same type (primary buttons, secondary buttons, links, toggles) must look identical across all screens. Inconsistency signals to users that elements behave differently.
- **Component reuse**: Do not create one-off component variants that aren't part of the design system. AI-generated UIs often spawn subtle variants (slightly different border radius, font weight, padding) that fragment visual cohesion.
- **Spacing system**: Spacing must follow a consistent scale (e.g., 4/8/16/24/32px). Arbitrary spacing values indicate missing system thinking.
- **Icon consistency**: Icons from mixed sources (different stroke weight, style, size) destroy visual language. A mix of outline and filled icons on the same screen is a High severity issue.
- **Interaction feedback consistency**: Hover, active, focus, and disabled states must follow the same pattern for equivalent elements everywhere.
- **Tone of voice**: Error messages, empty states, tooltips, and labels should follow a consistent voice. Mixing formal and casual registers in one interface is a violation.

**AI-generated failure pattern**: AI often generates locally correct components that are globally inconsistent — each component looks fine in isolation but the ensemble is fragmented.

---

## 2. User Flow & Navigation

> Source: *About Face Edition 4 – The Essentials of Interaction Design* (Interaction Design); *Interaction Design Best Practices: Mastering Time, Responsiveness, and Behavior*; *Task Centred User Interface Design* (User Interface)

- **No dead ends**: Every screen must have a clear path forward and a clear path back. Users must never feel trapped.
- **Progressive disclosure**: Show only what is necessary at each step. Don't overload the initial view; reveal complexity as users advance.
- **State visibility**: Users must always know where they are in a flow (breadcrumbs, step indicators, page titles). The system must communicate current state.
- **Error recovery paths**: Every error state must have a recovery action. Displaying an error without an actionable next step is broken flow.
- **Confirmation and reversibility**: Destructive actions (delete, cancel, submit) must be either reversible or confirmed. No silent, unrecoverable actions.
- **Consistent navigation placement**: Navigation elements (back, next, cancel, submit) must always appear in the same position across all steps of a flow.
- **Modal interruption**: Modals should be used sparingly and only for critical interruptions. Chains of modals are a broken flow antipattern.

**AI-generated failure pattern**: AI generates valid individual screens but misses the connective tissue — navigation items that lead nowhere, back buttons that skip steps, flows that have no success state.

---

## 3. Entry Points & Action Discoverability

> Source: *Task Centred User Interface Design*; *Tactical UI Design Patterns*; *Designing Better UX with UI Patterns* (User Experience); *Idiot Buttons – The Placebo in UX Design* (User Experience)

- **Primary action visibility**: Every screen must have exactly one visually dominant action. The user should never have to search for what to do next.
- **Affordance clarity**: Interactive elements must look interactive. A flat card with no hover state is an invisible entry point.
- **CTA hierarchy**: A page/screen should have one primary CTA, optionally one secondary, and supplemental links. More than one primary CTA causes action paralysis.
- **Action placement convention**: Primary actions belong in the bottom-right (desktop forms), top-right (headers), or center (landing/empty states). Placing them elsewhere requires strong justification.
- **Empty state entry points**: Empty states must contain an entry point to begin filling that state. A blank list with no "Add first item" CTA is a dead zone.
- **Contextual actions**: Actions that apply to specific items (edit, delete, view) must be co-located with those items, not separated into a distant toolbar.
- **No placebo buttons**: Buttons that appear active but trigger no meaningful action (idiot buttons), or buttons that are always visible but only sometimes meaningful, erode trust. Disable or hide them contextually.

**AI-generated failure pattern**: AI places actions wherever there's visual space rather than where user attention flows. Entry points end up buried below the fold or absent from empty states.

---

## 4. Button & Control Matrix on Lists

> Source: *Tactical UI Design Patterns*; *Web UI Design Patterns 2014*; *Mobile UI Design Patterns – A Deeper Look At The Hottest Apps Today* (Mobile Design)

- **Per-row action economy**: List rows should expose a maximum of 2–3 contextual actions. More than 3 visible actions per row creates visual noise and cognitive load.
- **Action overflow**: When more than 2–3 actions exist per item, use an overflow menu (ellipsis / kebab). Showing all actions simultaneously is a matrix antipattern.
- **Consistency of row actions**: Every row in the same list must offer the same set of actions, unless there is a clear data-driven reason for variance (e.g., role-based access). Inconsistent action sets across rows confuse users.
- **Bulk action separation**: Bulk actions (delete all, export, archive selected) must be visually separated from row-level actions and activated only when items are selected.
- **Destructive action distinction**: Delete/remove buttons in lists must be visually distinct from non-destructive actions (color, icon, placement). They should not be the default or most prominent action in a row.
- **Action labels vs icons**: In lists, use icons only if they are universally understood (edit pencil, trash for delete). Ambiguous icons without labels in list rows are a usability failure.
- **Touch target sizing**: Interactive controls in lists must be minimum 44×44px (iOS HIG) / 48×48dp (Material). Cramped list actions are a High severity issue on mobile.

**AI-generated failure pattern**: AI generates button-per-action patterns with every possible operation exposed inline, creating visual clutter that no real design system would produce.

---

## 5. Color Usage

> Source: *Color Theory in Web UI Design* (User Interface); *Flat Design and Colors*; *Web UI Trends Present & Future – The Vibrancy of Color*; *Web UI Design for the Human Eye*

- **Palette discipline**: Interfaces should use a maximum of 2–3 brand colors plus neutral grays plus semantic colors (red/green/yellow for status). More colors signal absence of a system.
- **60/30/10 rule**: 60% dominant neutral/background, 30% secondary brand color, 10% accent. Deviation causes visual fatigue.
- **Color contrast (WCAG AA)**: Text on background must meet 4.5:1 contrast ratio (normal text) or 3:1 (large text / UI components). This is a High/Critical issue.
- **Color as not the only differentiator**: Color alone must never be the only way to convey information. A colorblind user must be able to use the interface fully (add icons, labels, or patterns as secondary differentiators).
- **Semantic color consistency**: If red means error anywhere, it must mean error everywhere. Using red decoratively in a context that also uses red for errors destroys the semantic signal.
- **Background-text pairing**: Low-contrast color combinations (light gray text on white, yellow text on white) are accessibility failures regardless of brand guidelines.
- **Gradient overuse**: Gradients used without purpose (not indicating depth, state, or brand identity) add visual noise. AI-generated UIs tend to add gratuitous gradients.

**AI-generated failure pattern**: AI pulls colors from prompts without enforcing palette discipline. Each generated component may be individually beautiful but together they resemble a color picker explosion.

---

## 6. Color Coding & Semantic Color

> Source: *Color Theory in Web UI Design*; *Consistency UI Design: Creativity Without Confusion*; *Tactical UI Design Patterns*

- **Status color standards**: Use established conventions unless there is a strong domain reason not to: red = error/danger, yellow/amber = warning, green = success/active, blue = info/primary action, gray = disabled/neutral.
- **Semantic color map**: Every color with semantic meaning must be documented and applied consistently. If "blue" means "primary action", blue must never appear as a decorative element.
- **Badge and tag color consistency**: Status badges (e.g., "Active", "Pending", "Cancelled") must use the same color for the same status everywhere in the app. Changing badge color per context is a High severity issue.
- **Color coding with legend**: When color is used to encode categories in charts, lists, or maps, a legend must always be present. Color-only encoding without labels fails colorblind users and new users alike.
- **Priority / severity coding**: If the interface uses color to convey priority (critical/high/medium/low), the mapping must be consistent with system-wide conventions and never inverted.
- **Interactive vs informational color**: Colors used to signal interactivity (links, buttons) must not be used for purely decorative or informational elements, and vice versa.

**AI-generated failure pattern**: AI applies status colors inconsistently — the same concept gets different colors in different parts of a generated UI because each component was generated independently.

---

## 7. Information Structure & Visual Hierarchy

> Source: *The Building Blocks of Visual Hierarchy* (User Interface); *Web UI Design for the Human Eye*; *Zen of White Space in Web UI Design – Balance, Contrast, Hierarchy*; *Interaction Design Best Practices: Mastering Words, Visuals, Space*

- **Clear typographic hierarchy**: Use a maximum of 3 type sizes per screen (heading, body, caption/label). More levels flatten contrast and obscure structure.
- **Visual weight flow**: The user's eye must be guided from most important to least important. Size, weight, and color should decrease as importance decreases.
- **Proximity grouping**: Related items must be grouped closer together than unrelated items (Gestalt proximity). Fields belonging to the same logical group must be visually adjacent.
- **White space as structure**: Whitespace is not waste — it creates separation, groups elements, and reduces cognitive load. Cramped UIs (especially AI-generated) pack elements without breathing room.
- **F-pattern and Z-pattern reading**: Critical information and primary actions should be placed in F-pattern (content pages) or Z-pattern (landing/sparse pages) hotspots, not peripherally.
- **Section labeling**: Distinct sections of a page must be clearly labeled or visually separated. Unmarked transitions between unrelated content groups cause disorientation.
- **Information density**: Each screen should have one primary purpose. Packing multiple distinct workflows onto one screen without clear separation is a structural failure.
- **Card and container discipline**: Cards should group related information. Do not use cards purely for aesthetic decoration if the content doesn't form a logical unit.
- **Form field ordering**: Forms must follow a logical sequence (general before specific, simple before complex, required before optional). Random field ordering signals absent information architecture thinking.

**AI-generated failure pattern**: AI generates information-dense layouts with equal visual weight across all elements, creating screens where nothing stands out because everything does.
