Athkatla-skills

This is a personal agent skills marketplace repo.

## Structure
- `skills/` — individual skill folders, each with a SKILL.md
- `.claude-plugin/marketplace.json` — marketplace config for Claude Code

## Adding a new skill
1. Create a folder under `skills/your-skill-name/`
2. Add a `SKILL.md` with YAML frontmatter (name + description)
3. Register it in `.claude-plugin/marketplace.json`
