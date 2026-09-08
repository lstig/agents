---
status: approved
owner: Luke Stigdon
created: 2026-09-07
spec: 0002
---

# 0002 - Chain location and layout

## Approach

The gate's path rule becomes a shape rule.
Today it matches the literal `docs/sdlc/(spec|plan)/`; after this it matches `<...>/<container>/NNNN-slug/(spec|plan).md`, where `<container>` is `${SDLC_DIR:-changes}` compared as a *directory name*, not a path.
Everything else follows from that: the upstream is a sibling file rather than a glob in another directory, `change-id` is one more frontmatter read next to the `status` read the hook already does, and no component needs to know where the container lives.

The five artifacts move with `git mv` so history follows the file rather than reading as delete-plus-add.
Chain 0002 migrates itself: the spec and plan describing this change are among the files being moved, which is fine because the move is mechanical and their content is already written in the new vocabulary.

Skills stop restating the path.
`SDLC-FORMAT.md` states the default once; every other skill says "the container" and resolves it the same way — an existing `changes/` directory if there is one, `docs/changes/` otherwise.

Alternatives rejected:

- **A config file (`.sdlc.json`) naming the container.**
  Explicit and unambiguous, but it adds a config surface this repo does not otherwise have, and a file to keep in sync with the marketplace entry.
  A directory name already carries the information.
- **An absolute path in `SDLC_DIR`.**
  Simpler to implement than a name comparison, but it re-hardcodes the path one level up — every checkout with a different layout needs the env var set, and unset means broken rather than defaulted.
  Comparing the name means the common case needs no configuration at all.
- **Keeping `docs/sdlc/` and only fixing the false relocation claim.**
  The cheapest option, and it was the fallback if the layout stayed flat.
  Rejected once the layout changed: chain directories are what make the shape rule possible.
- **Blocking any unrecognised file inside a chain directory.**
  Tempting for strictness, but it forecloses the fourth artifact type spec 0001 anticipated, and requirement 6 says the opposite.
- **Rewriting the hook to read a manifest of chains.**
  Would catch a misfiled directory as well as a misfiled file, but it needs a file that must be regenerated on every change, and the `change-id` check already covers the case that actually happens.

## Steps

1. Rewrite `.claude-plugin/hooks/sdlc-gate.sh`: match `<container>/NNNN-slug/(spec|plan).md`, resolve `${SDLC_DIR:-changes}` by directory name, take the upstream from the sibling file, and add the `change-id` check with its own message.
2. Rewrite `.claude-plugin/hooks/sdlc-next.sh`: scan the container's `NNNN-*` directories instead of three stage directories, keeping the argument-taking root.
3. Update `SDLC-FORMAT.md`: the new location and layout, `change-id` in all three templates, the upstream keys gone, and the single statement of the default container.
4. Update `intent`, `spec`, and `plan` `SKILL.md`s to resolve the container rather than name a path, and to write `change-id`.
5. Update `execute`'s `worker.md`, whose read-only rule names `docs/sdlc/`.
6. `git mv` the five artifacts into `docs/changes/NNNN-slug/<stage>.md`, then edit frontmatter: add `change-id`, drop `intent:` and `spec:`.
7. Write `docs/adr/0001-one-directory-per-change.md`, creating `docs/adr/`.
8. Update `CONTEXT.md` (**change** as the unit, **artifact chain** kept for the files), `AGENTS.md` (the artifact paths in its structure table), `README.md`, and `docs/sdlc.md`.
9. Bump the `sdlc` marketplace entry to `0.3.0`.

## Affected files

| Path | Change |
|---|---|
| `.claude-plugin/hooks/sdlc-gate.sh` | Shape rule, sibling upstream, `change-id` check. |
| `.claude-plugin/hooks/sdlc-next.sh` | Scans chain directories. |
| `skills/experimental/intent/SDLC-FORMAT.md` | The format: layout, templates, the one statement of the default container. |
| `skills/experimental/intent/SKILL.md` | Resolves the container; writes `change-id`. |
| `skills/experimental/spec/SKILL.md` | Same, plus the sibling-file resolution of an intent. |
| `skills/experimental/plan/SKILL.md` | Same. |
| `skills/experimental/execute/agents/worker.md` | Read-only rule names the container. |
| `docs/sdlc/**` -> `docs/changes/NNNN-slug/` | Five artifacts moved and their frontmatter edited. |
| `docs/adr/0001-one-directory-per-change.md` | New. The decision, its alternatives, its consequences. |
| `CONTEXT.md` | **Change** as the unit; **artifact chain** narrowed to the files. |
| `AGENTS.md` | Artifact paths in the structure table. |
| `README.md`, `docs/sdlc.md` | New layout in the prose and the worked example. |
| `.claude-plugin/marketplace.json` | `sdlc` to `0.3.0`. |

## Risks

- **The live hook is the installed one, not the one in this tree.**
  Editing `sdlc-gate.sh` here changes nothing until `claude plugin marketplace update lstig-agents && claude plugin update sdlc@lstig-agents` runs; the cache holds 0.1.0, 0.1.1, and 0.2.0 side by side.
  Mitigation: test the script directly with synthetic payloads, then update the plugin and re-test before calling it done.
- **A gap in enforcement while the migration runs.**
  Between step 1 and step 6 the tree and the rule disagree, and during step 6 the artifacts are neither where the old rule looks nor fully in the new shape.
  Mitigation: the whole change is one commit on a branch, and the acceptance criteria are checked after it, not during.
- **Comparing a directory *name* gates any `changes/` directory in any repo.**
  A repo with an unrelated `changes/0001-foo/spec.md` would find writes gated.
  Accepted in the spec's policy notes as the trade against a config file; `SDLC_DIR` is the escape hatch, and the `change-id` message will say plainly why a write was blocked.
- **`change-id` is easy to write and easy to forget.**
  A skill that omits it makes every subsequent write to that chain fail the check.
  Mitigation: the templates in `SDLC-FORMAT.md` carry the key, and requirement 11's error names both values so the fix is obvious.
- **Chain 0002 rewrites the artifacts describing chain 0002.**
  The plan being executed is one of the files moving.
  Mitigation: step 6 is `git mv` plus a frontmatter edit — no content changes — so the plan a reviewer reads after the move is the plan that was approved.
- **`rg 0002 docs/changes/` must keep working**, since the guide promises it.
  The number lives in the directory name and now in `change-id`, so it survives; verified below rather than assumed.

## Verification

```bash
bash -n .claude-plugin/hooks/sdlc-gate.sh
claude plugin validate .
```

The gate, driven directly with synthetic payloads — blocked cases must exit 2 and allowed cases 0:

```bash
h=.claude-plugin/hooks/sdlc-gate.sh
p() { jq -nc --arg c "$1" --arg w "$PWD" '{cwd:$w,tool_input:{command:$c}}'; }
p "touch docs/changes/0003-x/spec.md"    | bash "$h"   # blocked while intent.md is proposed
p "touch changes/0003-x/spec.md"         | bash "$h"   # blocked the same at the repo root
p "touch docs/changes/0003-x/notes.md"   | bash "$h"   # not gated
p "touch rfcs/0012-thing/spec.md"        | bash "$h"   # not gated
p "touch docs/changes/0004-y/spec.md"    | bash "$h"   # blocked: no intent.md beside it
```

Migration is complete and reversible-looking in history:

```bash
ls docs/changes/0001-plan-execution-and-adversarial-review/   # intent.md spec.md plan.md
test ! -d docs/sdlc && echo "old tree gone"
git log --follow --oneline docs/changes/0001-*/spec.md | tail -3
rg '^status:' docs/changes/*/[isp]*.md
rg -c '^change-id:' docs/changes/*/*.md
rg '^(intent|spec):' docs/changes/ || echo "upstream keys gone"
rg -l 'docs/sdlc' . || echo "no stale references"
bash .claude-plugin/hooks/sdlc-next.sh docs/changes   # 0003
```

Then update the installed plugin and confirm the gate is live end to end:

```bash
claude plugin marketplace update lstig-agents
claude plugin update sdlc@lstig-agents
claude plugin list   # sdlc 0.3.0, enabled
```
