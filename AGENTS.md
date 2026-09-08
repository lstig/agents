# Agent instructions

Instructions for agents (and humans) working on this repo.

## Start with CONTEXT.md

[CONTEXT.md](./CONTEXT.md) is the glossary — the canonical vocabulary for this repo (Skill vs Plugin, Marketplace, Experimental vs Stable, Guide, Artifact chain).
Use its terms exactly; don't substitute synonyms it lists under _Avoid_.
When a design discussion changes or sharpens a term, update CONTEXT.md in the same change.
It is a glossary only: no implementation details, no decisions, no TODOs.

## Repo structure

| Path | What it is |
|---|---|
| `skills/<tier>/<name>/` | One directory per skill: `SKILL.md` (agent-facing, loaded into model context) plus supporting files. `<tier>` is `experimental` (alpha) or `stable` (settled). |
| `skills/<tier>/<name>/agents/*.md` | Subagent definitions shipped beside the skill that dispatches them. Registered by listing each **file** in a marketplace entry's `agents` key — the directory form is rejected by `claude plugin validate`. |
| `.claude-plugin/marketplace.json` | The single source of plugin metadata. Plugins are defined inline (`strict: false`); there is deliberately **no** `plugin.json` — one manifest can't describe several plugins. |
| `.claude-plugin/hooks/` | The `sdlc` plugin's gate script, plus `sdlc.json` as a copy-paste registration example for people vendoring the skills. The marketplace entry's `hooks` key inlines the registration — a marketplace entry can't reference a hooks file by path. |
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
  A skill that ships subagents adds a fifth: each agent file listed in that entry's `agents` key.
  `skills.sh.json` has no equivalent, so skills.sh and vendored installs get the skill without its subagents — say so in the docs rather than letting it fail at dispatch.
- All new skills start in `skills/experimental/`.
  Graduation to `skills/stable/` is informal — earned through real use — but not free: every marketplace entry pinning the old path needs the new one, plus a patch bump, and the README's skill links carry the tier so they move too.

## Pitfalls

- **Never add a root `agents/` directory.**
  It is a default plugin location, so every plugin sourced at `./` would pick up every agent in it — `development` would silently acquire `worker` and `judge`.
  Subagent files live beside their skill and are named file-by-file in the owning marketplace entry.
- **Never add a root `.mcp.json` or a root `hooks/hooks.json`.**
  Both are default plugin locations, so every plugin sourced at `./` auto-discovers them — this once leaked an MCP server into `development`.
  The canonical configs live under `.claude-plugin/` and are referenced explicitly by the plugins that want them.
- Marketplace `skills` paths replace the default `skills/` scan only because each entry's `source` is the marketplace root; don't assume that behavior elsewhere.
- `skills.sh.json` and `.claude-plugin/marketplace.json` drift silently — nothing enforces the mirror. Renaming, adding, removing, or regrouping a plugin in one requires the same edit in the other in the same change.

## Contributing and committing

- Conventional Commits (`type(scope): subject`); `!`/`BREAKING CHANGE:` when renaming or removing published plugins or changing artifact formats.
- **Bump plugin versions with every change**, following semver on the affected marketplace entries: patch for fixes and doc tweaks to bundled skills, minor for new skills or backward-compatible behavior, major for renames, removals, or breaking format changes.
  A change to a shared file (e.g. anything under `.claude-plugin/hooks/`) bumps every plugin that references it.
- Before committing changes to `.claude-plugin/` or skill layout, run `claude plugin validate .`.
- After marketplace changes, smoke test in a scratch project: add the marketplace from the local path, install both plugins, then check `claude plugin list` (every plugin must report enabled, not "failed to load") and that skills resolve.
- Markdown: one sentence per line; `.yaml` over `.yml`; no inline HTML.
- Don't commit or push on behalf of the user unless asked.
