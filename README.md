# agents

Portable customizations for AI coding agents. Today that's a set of
[Agent Skills](https://agentskills.io/specification) under [`skills/`](./skills);
subagents, prompts, and themes may follow.

Each skill is a self-contained directory under [`skills/`](./skills) with a
`SKILL.md` (frontmatter + instructions) and any supporting files.
The format is agent-agnostic: Pi, Claude Code, and OpenAI Codex all discover
`SKILL.md` directories.

The repo is also a plugin per the [Open Plugin Specification](https://github.com/vercel-labs/open-plugin-spec)
([`.plugin/plugin.json`](./.plugin/plugin.json)), bundling every skill under
`skills/` plus the MCP server config in [`.mcp.json`](./.mcp.json) as one
installable unit, for hosts that support it.

## Skills

| Skill | What it does |
|---|---|
| [`pr`](./skills/pr) | Open a pull/merge request on the repo's forge (GitHub, GitLab, Gitea, Forgejo) using the forge's native CLI. |
| [`shipit`](./skills/shipit) | Commit changes, merge the branch into its base, and remove the worktree. |
| [`task-notes`](./skills/task-notes) | Create and update Joplin task notes — the durable record of one task (description, checklist, log, links). |
| [`task-work`](./skills/task-work) | Drive work from a Joplin task note, one checklist item at a time. Pairs with `task-notes`. |

`task-notes` and `task-work` assume [Joplin](https://joplinapp.org/) with a
notebook named `Agents`, reachable via the `joplin` MCP server defined in
[`.mcp.json`](./.mcp.json). That server expects Joplin's Web Clipper API
running locally and a `JOPLIN_MCP_TOKEN` env var holding its API token. The rest
are general-purpose.

## Using a skill

**As a plugin:** install this repo through your host's plugin mechanism (e.g.
Claude Code's `/plugin marketplace add` / `/plugin install`) so the skills and
`.mcp.json` install together as one unit.

**Vendored:** point your agent's skills directory at these, or copy individual
skills into your own dotfiles. For example, to install one for Claude Code:

```bash
git clone https://github.com/lstig/agents.git
cp -R agents/skills/pr ~/.claude/skills/pr
```

Pi and Codex read the same `SKILL.md` layout; see your agent's docs for its
skills location. If you vendor `task-notes` or `task-work` this way, bring
`.mcp.json` (or equivalent MCP config) along with them.

## License

[MIT](./LICENSE)
