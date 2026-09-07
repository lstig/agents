# agents

[![skills.sh](https://skills.sh/b/lstig/agents)](https://skills.sh/lstig/agents)

Portable customizations for AI coding agents.
Today that's a set of [Agent Skills](https://agentskills.io/specification) under [`skills/`](./skills); subagents, prompts, and themes may follow.

Each skill is a self-contained directory holding a `SKILL.md` (frontmatter + instructions) and any supporting files.
The format is agent-agnostic: Pi, Claude Code, and OpenAI Codex all discover `SKILL.md` directories.

## Skills

**Everything under [`skills/experimental/`](./skills/experimental) is alpha**: prompts, formats, and names may change without notice.
A skill graduates to `skills/` once it has proven itself through real use.

| Skill | What it does |
|---|---|
| [`pr`](./skills/experimental/pr) | Open a pull/merge request on the repo's forge (GitHub, GitLab, Gitea, Forgejo) using the forge's native CLI. |
| [`shipit`](./skills/experimental/shipit) | Commit changes, merge the branch into its base, and remove the worktree. |
| [`intent`](./skills/experimental/intent) | Capture an idea as a version-controlled intent — the first artifact in the intent -> spec -> plan chain. |
| [`spec`](./skills/experimental/spec) | Turn an accepted intent into a spec: what the solution must do, checked against organizational policy. |
| [`plan`](./skills/experimental/plan) | Turn an approved spec into a read-only implementation plan — the audit trail and review baseline. |

`intent`, `spec`, and `plan` form the SDLC artifact chain — one numbered chain of reviewed markdown per change, with the stage gates enforced by a hook rather than by asking the model.
See [docs/sdlc.md](./docs/sdlc.md) for a worked example.

## Installing

### skills.sh

```bash
npx skills add lstig/agents
```

Add `-g` to install globally instead of per-project, `--skill <name>` to pick individual skills, or `--list` to see what's available.
Works across Claude Code, Cursor, Codex, Copilot, Gemini CLI, and Cline.

### Claude Code plugins

The repo is a Claude Code plugin marketplace ([`.claude-plugin/marketplace.json`](./.claude-plugin/marketplace.json)) named `lstig-agents`, offering two plugins:

- **`development`** — the general development skills: `pr`, `shipit`.
- **`sdlc`** — the artifact chain: `intent`, `spec`, `plan`, plus the `PreToolUse` hook that enforces their gates.

```
/plugin marketplace add lstig/agents
/plugin install development@lstig-agents
/plugin install sdlc@lstig-agents
```

### Vendored

Point your agent's skills directory at these, or copy individual skills into your own dotfiles.
For example, to install one for Claude Code:

```bash
git clone https://github.com/lstig/agents.git
cp -R agents/skills/experimental/pr ~/.claude/skills/pr
```

Pi and Codex read the same `SKILL.md` layout; see your agent's docs for its skills location.
Vendoring `intent`, `spec`, or `plan` gets the skills but not the gate hook; bring [`.claude-plugin/hooks/`](./.claude-plugin/hooks) too, or the gates become instructions rather than enforcement.

## License

[MIT](./LICENSE)
