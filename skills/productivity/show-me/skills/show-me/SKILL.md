---
name: show-me
description: Show the current topic visually, and re-pitch it in simple English. Asks you for the requirements when the conversation carries no ticket.
disable-model-invocation: true
---

Help the user understand the current topic of conversation visually. Skip the preamble. Pick the smallest view that makes the key point clear.

@../../checklists/re-pitch.md

### render in the terminal

Write the answer in the terminal. For the full answer as a styled page, the user runs `/athkatla-skills:show-me-html`.

- For a visual UI, layout, state comparison, or concept too dense for Mermaid, write one focused HTML file — a diagram, an infographic, or a short slide deck, whichever fits the point. Match the product's colors, type, spacing, and components; use real labels and data; support desktop and mobile. Then open it for the user (macOS `open`; `xdg-open` on Linux):

```
Bash(open path/to/show-me-{description}.html)
```
