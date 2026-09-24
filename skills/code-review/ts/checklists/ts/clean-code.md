# Clean-Code Fallback (TypeScript)

Apply this list when the `athkatla-skills:clean-code` skill is not available. Judge only what the change introduces or worsens.

- Intention-revealing names for variables, functions, types, files. Flag vague names (data, info, temp, handle, process) and misleading names.
- Self-explanatory code instead of comments. Apply the comment review scan (`comments.md`) to every comment line the change adds or edits.
- Declarative / functional style over imperative nesting: early returns over nested if/else chains, map/filter/reduce over index loops where it reads better, no flag-argument branching.
- Clear structure: one responsibility per function and file; related logic colocated; no grab-bag utils additions.
- Size: flag functions over ~50 lines and files over ~800 lines, or any function/file the change makes meaningfully harder to follow.
- DRY: duplicated or near-identical blocks introduced or extended by this change.
