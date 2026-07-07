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
| [`task-notes`](./skills/experimental/task-notes) | Create and update Joplin task notes — the durable record of one task (description, checklist, log, links). |
| [`task-work`](./skills/experimental/task-work) | Drive work from a Joplin task note, one checklist item at a time. Pairs with `task-notes`. |

`task-notes` and `task-work` form the task workflow — a Joplin note as the single source of truth for each task.
See [docs/task-workflow.md](./docs/task-workflow.md) for setup and a worked example.

## Installing

### skills.sh

```bash
npx skills add lstig/agents
```

Add `-g` to install globally instead of per-project, `--skill <name>` to pick individual skills, or `--list` to see what's available.
Works across Claude Code, Cursor, Codex, Copilot, Gemini CLI, and Cline.

If you install `task-notes` or `task-work` this way, wire up the `joplin` MCP server yourself — skills.sh installs skills only.
It's a native HTTP server; see [.claude-plugin/mcp.json](./.claude-plugin/mcp.json) or run `claude mcp add --transport http joplin "http://127.0.0.1:41184/mcp?token=$JOPLIN_MCP_TOKEN"`.

### Claude Code plugins

The repo is a Claude Code plugin marketplace ([`.claude-plugin/marketplace.json`](./.claude-plugin/marketplace.json)) named `lstig-agents`, offering two plugins:

- **`development`** — the general development skills: `pr`, `shipit`.
- **`workflow`** — the task workflow: `task-notes`, `task-work`, plus the `joplin` MCP server config so the Joplin dependency travels with them.

```
/plugin marketplace add lstig/agents
/plugin install development@lstig-agents
/plugin install workflow@lstig-agents
```

### Vendored

Point your agent's skills directory at these, or copy individual skills into your own dotfiles.
For example, to install one for Claude Code:

```bash
git clone https://github.com/lstig/agents.git
cp -R agents/skills/experimental/pr ~/.claude/skills/pr
```

Pi and Codex read the same `SKILL.md` layout; see your agent's docs for its skills location.
As with skills.sh, vendoring `task-notes` or `task-work` means bringing [`.claude-plugin/mcp.json`](./.claude-plugin/mcp.json) (or an equivalent HTTP MCP config) along.

## License

[MIT](./LICENSE)
