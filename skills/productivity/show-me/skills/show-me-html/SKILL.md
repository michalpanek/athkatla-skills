---
name: show-me-html
description: Show the current topic visually and re-pitch it in simple English, as one styled HTML page that opens in the browser. Asks you for the requirements when the conversation carries no ticket.
disable-model-invocation: true
---

Help the user understand the current topic of conversation visually. Pick the smallest view that makes the key point clear. The answer goes to a page, not to the terminal.

@../../checklists/re-pitch.md

### render as one HTML page

1. **Copy the template.** Copy `template.html` from this skill's base directory to `${TMPDIR:-/tmp}/show-me/show-me-{topic}.html`. Write `{topic}` in kebab-case, three words or fewer. Keep the page in the OS temp folder: macOS deletes old files from `$TMPDIR` on its own, so the user never cleans up.
2. **Fill the slots.** Replace each `{{…}}` slot in the template. The template comments name what goes in each slot.
   - Put the description in the lead paragraph.
   - Put the steps in the `<ol class="steps">` list, one `<li>` per step.
   - Put each shape in its own `<section>`, with a short heading and its supporting text next to it.
3. **Render each shape with its matching block.**
   - Mermaid: `<pre class="mermaid">` with the diagram source. Give `flowchart` nodes the classes from the data flow table only. The template adds their colours and a colour key for the classes the page uses. Leave out `classDef` and `style` lines.
   - File relations: draw a `flowchart TB`. Put each folder in a `subgraph`. Draw one edge from each importing file to the file it imports, and only for an import you read in the code. Link a test to its subject with a dotted edge. Use the data flow classes for the files.
   - `diff`, pseudocode, trees, and code: `<pre><code class="language-{lang}">`. Use `diff`, `plaintext`, `tsx`, `ts`, or the real language of the code.
   - Escape `<`, `>`, and `&` inside every `<code>` and `<pre class="mermaid">` block. An unescaped `-->` in a Mermaid arrow closes HTML comments and breaks the page.
   - Visual UI, layout, or state comparison: build it with HTML and CSS in the section. Use the product's colors, real labels, and real data.
4. **Open the page.** Run `open <path>` on macOS, `xdg-open <path>` on Linux.
5. **Reply with the path.** Write one line in the terminal: the absolute path to the page.

The page is done when it carries the description, the numbered steps, and every shape, and the terminal carries only the path.
