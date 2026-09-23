# Clean Code (fallback checklist)

Apply this list when the `clean-code` skill is not available. Judge only what the change introduces or worsens.

- Intention-revealing names for variables, methods, classes, packages. Flag vague names (data, info, temp, handle, process, Manager, Util) and misleading names.
- Self-explanatory code instead of comments. A comment explaining WHAT the code does is a naming/structure smell; comments only earn their place stating constraints the code cannot express (and Javadoc on public API).
- Declarative / functional style over imperative nesting: early returns / guard clauses over nested if/else chains, Streams or Vavr over index loops where it reads better, no flag-argument branching.
- Clear structure: one responsibility per method and class; related logic colocated; no grab-bag utils additions.
- Size: flag methods over ~50 lines and classes over ~800 lines, or any method/class the change makes meaningfully harder to follow.
- DRY: duplicated or near-identical blocks introduced or extended by this change.
