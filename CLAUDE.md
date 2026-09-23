Athkatla-skills

This is a personal agent skills marketplace repo. It ships ONE plugin, `athkatla-skills`, that contains every skill.
Users invoke a skill as `/athkatla-skills:<skill-name>`.

## Structure
- `skills/<area>/<group>/skills/<skill-name>/SKILL.md` — individual skills, grouped by area
- `skills/<area>/<group>/checklists/` — shared files that SKILL.md loads with relative `@../../` paths
- `.claude-plugin/plugin.json` — the single plugin manifest; its `skills` array lists every `.../skills/` directory; it owns the plugin `version`
- `.claude-plugin/marketplace.json` — marketplace config with one entry (`source: "./"`); do not set `version` there

## Adding a new skill
1. Create `skills/<area>/<group>/skills/<skill-name>/SKILL.md` with YAML frontmatter (name + description)
2. If `<area>/<group>` is new, add `./skills/<area>/<group>/skills/` to the `skills` array in `.claude-plugin/plugin.json`
3. Do not add a nested `.claude-plugin/plugin.json`. Do not add a new plugin entry to `marketplace.json`
4. Run `claude plugin validate .`
