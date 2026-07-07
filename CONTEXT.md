# Agents

Portable customizations for AI coding agents, distributed as skills packaged into installable plugins.

## Language

**Skill**:
A self-contained directory under `skills/` holding a `SKILL.md` (agent-facing instructions) and supporting files.
_Avoid_: plugin, command, prompt

**Plugin**:
A named, installable unit defined in the marketplace that bundles a selection of skills and any config they need (e.g. MCP servers). The repo ships two: `development` and `workflow`.
_Avoid_: skill, package

**Marketplace**:
The repo's catalog of plugins (`.claude-plugin/marketplace.json`), named `lstig-agents` and addressed as `<plugin>@lstig-agents`.

**Experimental**:
The alpha maturity tier. An experimental skill lives under `skills/experimental/` and may change prompts, formats, or names without notice. Graduation to `skills/` is informal — earned through real use.
_Avoid_: beta, unstable, draft

**Guide**:
A human-facing document under `docs/` covering setup and example usage, possibly spanning several skills. Distinct from `SKILL.md`, which is agent-facing and loaded into model context.
_Avoid_: readme, manual

**Task note**:
A Joplin to-do that is the durable, single source of truth for one task. Owned by the `task-notes` skill; consumed by `task-work`.
_Avoid_: ticket, issue, todo
