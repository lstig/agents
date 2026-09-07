# The SDLC artifact chain

Three skills — `intent`, `spec`, `plan` — write one chain of reviewed markdown per change:

```
docs/sdlc/intent/0007-workload-token-issuer.md   what problem is worth solving
docs/sdlc/spec/0007-workload-token-issuer.md     what the solution must do
docs/sdlc/plan/0007-workload-token-issuer.md     how it gets built
```

One number and slug span the chain, so `rg 0007 docs/sdlc/` returns all of it.
The format lives in [SDLC-FORMAT.md](../skills/experimental/intent/SDLC-FORMAT.md).

## The gates are the point

Each artifact carries a `status`, and **only a human moves it forward**.
An agent writes artifacts and reports them; it never accepts, approves, or rejects its own work.

| Gate | Requirement |
|---|---|
| write a spec | its intent is `accepted` |
| write a plan | its spec is `approved` |
| start building | its plan is `approved` |

The first two are enforced by a `PreToolUse` hook, not by asking the model nicely.
Install the plugin and a write to `docs/sdlc/spec/0007-*.md` is blocked outright while intent `0007` still reads `proposed`.

## Worked example

```
/intent add short-lived tokens for service-to-service auth
```

Writes `docs/sdlc/intent/0007-workload-token-issuer.md` with `status: proposed` and stops.
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
Approve it, then implement in a fresh session that starts from the approved plan.

Rejected ideas keep their files and their numbers.
`status: rejected` is a record; deleting the file is not.

## Installing

```
/plugin marketplace add lstig/agents
/plugin install sdlc@lstig-agents
```

Installing via skills.sh or vendoring gets the skills but not the hook, so the gates become instructions rather than enforcement.
To keep enforcement, copy [`.claude-plugin/hooks/`](../.claude-plugin/hooks) into your project and register `sdlc-gate.sh` as a `PreToolUse` hook on `Write|Edit`; [`sdlc.json`](../.claude-plugin/hooks/sdlc.json) is that registration, ready to paste.
The hook needs `jq`; without it, it exits without blocking.
