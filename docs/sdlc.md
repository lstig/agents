# The SDLC artifact chain

Three skills — `intent`, `spec`, `plan` — write one chain of reviewed markdown per change, and a fourth, `execute`, builds what they approved:

```
docs/changes/0007-workload-token-issuer/intent.md   what problem is worth solving
docs/changes/0007-workload-token-issuer/spec.md     what the solution must do
docs/changes/0007-workload-token-issuer/plan.md     how it gets built
```

One change is one directory: the number and slug name it, the stage is the filename, and every artifact repeats the number as `change-id`, so `rg 0007 docs/changes/` returns all of it.
The container above is a directory *named* `changes` — put it somewhere else in the tree and the gates follow it, or set `SDLC_DIR` to call it something else entirely.
The format states where a fresh repo puts it, along with the templates and the status values: [SDLC-FORMAT.md](../skills/experimental/intent/SDLC-FORMAT.md).

## The gates are the point

Each artifact carries a `status`, and **only a human moves it forward**.
An agent writes artifacts and reports them; it never accepts, approves, or rejects its own work.

| Gate | Requirement |
|---|---|
| write a spec | its intent is `accepted` |
| write a plan | its spec is `approved` |
| start building | its plan is `approved` |

The first two are enforced by a `PreToolUse` hook, not by asking the model nicely.
Install the plugin and a write to `docs/changes/0007-*/spec.md` is blocked outright while the `intent.md` beside it still reads `proposed`.

The hook recognises an artifact by shape — `<container>/NNNN-slug/spec.md` or `plan.md` — so nothing outside a `changes` container is gated, and a file in a chain directory that is not one of the three stages is not gated either.
It also blocks a spec or plan whose `change-id` disagrees with the directory it sits in, which is how a chain that has been half-moved gets caught.
That check reads the text the write proposes, not the file on disk, so the edit that repairs a wrong or missing `change-id` is never the one blocked.

The hook watches `Write`, `Edit`, and `Bash`.
Shell coverage is best-effort: it catches a gated path sitting next to a redirect or a mutating command, and misses one assembled from a variable.
The third gate is not enforced at all — implementation writes go to ordinary source paths, which no path-matching hook can tell apart from any other editing session.

## Worked example

```
/intent add short-lived tokens for service-to-service auth
```

Writes `docs/changes/0007-workload-token-issuer/intent.md` with `status: proposed` and stops.
You read it, and if it is worth doing, change the line to `status: accepted` and commit.

```
/spec 0007
```

Reads the intent, loads whatever security and API standards the repo carries, and writes the spec — with any policy conflict called out under `## Policy notes` rather than quietly resolved.
Approve it the same way.

```
/plan 0007
```

Reads the codebase without touching it and writes the plan: approach, rejected alternatives, steps, affected files, risks, verification commands.
Approve it, then build it:

```
/execute 0007
```

`execute` sizes a `worker` subagent to the plan, puts it to work in a git worktree, and hands the result to a `judge` subagent that never sees the worker's account of what it did.
The judge reviews through six fixed lenses — plan conformance, correctness, scope, conventions, best practices, security — and reports every one of them each round, including the lenses that found nothing.
Findings go back to the worker; the loop ends only when a review comes back empty.
The judge is read-only by construction and runs on the worker's model or a stronger one, never a weaker one.

What comes out is a commit on a branch.
Pushing it, opening a pull request, merging, and moving the plan to `implemented` stay with you — an empty review is evidence for that decision, not the decision.

Rejected ideas keep their files and their numbers.
`status: rejected` is a record; deleting the file is not.

## Installing

```
/plugin marketplace add lstig/agents
/plugin install sdlc@lstig-agents
```

Installing via skills.sh or vendoring gets the skills but neither the hook nor the subagents, so the gates become instructions rather than enforcement and `execute` stops instead of dispatching.
To keep enforcement, copy [`.claude-plugin/hooks/`](../.claude-plugin/hooks) into your project and register `sdlc-gate.sh` as a `PreToolUse` hook on `Write|Edit|Bash`; [`sdlc.json`](../.claude-plugin/hooks/sdlc.json) is that registration, ready to paste.
The hook needs `jq`; without it, it exits without blocking.
