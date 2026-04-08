# Claude Code Skills

Skills installed here are symlinked into `~/.claude/skills/` by `ln.sh` so they're available globally across all projects.

## Installed Skills

| Skill | Source | Description |
|---|---|---|
| [frontend-design](./frontend-design/) | [anthropics/skills](https://github.com/anthropics/skills) | Production-grade web UI design with high design quality |
| [pdf](./pdf/) | [anthropics/skills](https://github.com/anthropics/skills) | Read, create, merge, split, fill forms, OCR PDF files |
| [skill-creator](./skill-creator/) | [anthropics/skills](https://github.com/anthropics/skills) | Create, modify, eval, and benchmark skills |
| [webapp-testing](./webapp-testing/) | [anthropics/skills](https://github.com/anthropics/skills) | Test local web apps with Playwright (screenshots, logs, interaction) |

## Adding new skills

1. Browse available skills at https://github.com/anthropics/skills
2. Copy the skill directory here
3. Run `ln.sh` to symlink into `~/.claude/skills/`
4. Invoke with `/skill-name` in Claude Code

## Updating skills

Pull the latest from the upstream repo and re-copy:

```bash
cd /tmp && git clone --depth 1 https://github.com/anthropics/skills.git
cp -r /tmp/skills/skills/<skill-name> ~/dotfiles/skills/
```
