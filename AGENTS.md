# Agent instructions

Instructions for agents (and humans) working on this repo.

## Start with CONTEXT.md

[CONTEXT.md](./CONTEXT.md) is the glossary — the canonical vocabulary for this repo (Skill vs Plugin, Marketplace, Experimental, Guide, Task note).
Use its terms exactly; don't substitute synonyms it lists under _Avoid_.
When a design discussion changes or sharpens a term, update CONTEXT.md in the same change.
It is a glossary only: no implementation details, no decisions, no TODOs.

## Repo structure

| Path | What it is |
|---|---|
| `skills/experimental/<name>/` | One directory per skill: `SKILL.md` (agent-facing, loaded into model context) plus supporting files. Everything here is alpha. |
| `.claude-plugin/marketplace.json` | The single source of plugin metadata. Plugins are defined inline (`strict: false`); there is deliberately **no** `plugin.json` — one manifest can't describe two plugins. |
| `.claude-plugin/mcp.json` | Canonical `joplin` MCP config, referenced explicitly by the `workflow` plugin. |
| `skills.sh.json` | Groupings for the [skills.sh](https://skills.sh) listing. Must mirror `.claude-plugin/marketplace.json`'s plugins: same titles and same skill membership per group. |
| `docs/` | Human-facing guides (setup, worked examples). Human docs go here, never into `SKILL.md`. |
| `docs/adr/` | Architecture decision records. Doesn't exist yet; create it with the first ADR. |

## ADRs

Record a decision as `docs/adr/NNNN-kebab-title.md` only when all three hold:

1. **Hard to reverse** — changing course later costs something real (renaming published plugins, changing note formats in the wild).
2. **Surprising without context** — a future reader would ask "why did they do it this way?"
3. **A real trade-off** — genuine alternatives existed and one was chosen for specific reasons.

If any leg is missing, a log line in the commit message is enough.

## Skill conventions

- `SKILL.md` is written for agents: imperative, concise, no marketing prose.
  Frontmatter needs `name` and `description`; add `disable-model-invocation: true` for skills that must only run when a user invokes them.
- Supporting files (formats, references) live beside `SKILL.md` and are linked relatively, so vendored copies stay self-contained.
- Adding a skill means updating four places: the skill directory, the README table, (if it should install via Claude Code) a `skills` path in the right marketplace entry, and the matching group's `skills` array in `skills.sh.json`.
- All new skills start in `skills/experimental/`.
  Graduation to `skills/` is informal — earned through real use — and is cheap: nothing consumer-facing references paths.

## Pitfalls

- **Never add a root `.mcp.json`.**
  It's a default plugin MCP location, so every plugin sourced at `./` auto-discovers it — this once leaked the joplin server into `development`.
  The canonical config lives at `.claude-plugin/mcp.json`.
- Marketplace `skills` paths replace the default `skills/` scan only because each entry's `source` is the marketplace root; don't assume that behavior elsewhere.
- `skills.sh.json` and `.claude-plugin/marketplace.json` drift silently — nothing enforces the mirror. Renaming, adding, removing, or regrouping a plugin in one requires the same edit in the other in the same change.

## Contributing and committing

- Conventional Commits (`type(scope): subject`); `!`/`BREAKING CHANGE:` when renaming or removing published plugins or changing note formats.
- **Bump plugin versions with every change**, following semver on the affected marketplace entries: patch for fixes and doc tweaks to bundled skills, minor for new skills or backward-compatible behavior, major for renames, removals, or breaking format changes.
  A change to a shared file (e.g. `.claude-plugin/mcp.json`) bumps every plugin that references it.
- Before committing changes to `.claude-plugin/` or skill layout, run `claude plugin validate .`.
- After marketplace changes, smoke test in a scratch project: add the marketplace from the local path, install both plugins, then check `claude mcp list` (the `joplin` server must appear under `plugin:workflow:` only) and that skills resolve.
- Markdown: one sentence per line; `.yaml` over `.yml`; no inline HTML.
- Don't commit or push on behalf of the user unless asked.
