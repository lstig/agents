---
status: implemented
owner: Luke Stigdon
created: 2026-09-07
spec: 0001
---

# 0001 - Plan execution and adversarial review

## Approach

Three new files: one skill, `execute`, and two subagent definitions, `worker` and `judge`.
`execute` runs in the main session and owns the loop; the subagents own the work and the review.

The spec's hard properties are carried by structure rather than by prose, because requirement 22 caps how much prose there can be:

- **Context separation (req 8)** comes free from dispatching the judge as its own agent.
  `execute` passes it a plan path and a diff range — never the worker's report.
- **The judge cannot repair what it finds** because its `tools:` frontmatter is read-only (`Read, Glob, Grep, Bash`).
  A judge that could edit would quietly become the worker.
- **Lens coverage (reqs 9, 10)** is the judge's output shape: it returns one section per lens, so a skipped lens is visible as a missing section rather than as silence.
- **Model rules (reqs 3, 4)** are `execute`'s job at dispatch time.
  Both agent files declare `model: inherit`; `execute` overrides per dispatch and refuses to send a judge weaker than the worker.

The subagent files live at `skills/experimental/execute/agents/`, listed explicitly in the marketplace entry's `agents` key.

Alternatives rejected:

- **A root `agents/` directory.**
  This is the default discovery path and needs no manifest entry, which is exactly the problem: both plugins declare `source: "./"`, so `development` would silently acquire `worker` and `judge`.
  That is the leak `AGENTS.md` already records for `.mcp.json`.
- **An `agents` key pointing at a directory.**
  Rejected on evidence: `claude plugin validate` accepts `"./path/agent.md"` and rejects `"./path/"` with `plugins.1.agents.0: Invalid input`.
- **One judge subagent per lens, dispatched in parallel.**
  Six agents per round is faster to read but multiplies an already uncapped loop, and the lenses need each other's context — a scope finding is often a correctness finding seen from another angle.
- **A fixed model pair (worker sonnet, judge opus).**
  Simpler, and it satisfies req 4 trivially, but req 3 asks the worker to be sized to the plan; a fixed pair spends opus on trivial plans and starves complex ones.
- **`execute` running the work itself and dispatching only a judge.**
  Cheaper by one agent, but then the loop's driver holds the implementation context, and the judge's independence depends on the driver not leaking it.

## Steps

1. Write `skills/experimental/execute/SKILL.md`: resolve the plan, check `approved`, pick the worker model and say why, run the round loop, halt conditions, commit on a clean finish.
2. Write `agents/worker.md`: implement the plan's steps, run its verification commands, report per step and per command, never touch `docs/sdlc/`, escalate a wrong plan instead of working around it.
3. Write `agents/judge.md`: the six lenses as the output's section headings, findings anchored to code or a plan step, an explicit empty result, read-only `tools:`.
4. Register in `.claude-plugin/marketplace.json`: add the skill path to the `sdlc` entry's `skills`, add both agent files to a new `agents` key, bump `0.1.2` -> `0.2.0`.
5. Mirror the skill into `skills.sh.json`'s `sdlc` grouping.
6. Update `CONTEXT.md` with the terms this change introduces: subagent, worker, judge, lens.
7. Update `AGENTS.md`: a repo-structure row for subagent files, the four-places rule extended to agents, and a pitfall entry for the root `agents/` leak.
8. Update `README.md`: the skill table row, and the subagent line the intro already promises.
9. Update `docs/sdlc.md`: `execute` in the gate table and the worked example, plus what a skills.sh or vendored install does not get.

## Affected files

| Path | Change |
|---|---|
| `skills/experimental/execute/SKILL.md` | New. The loop, the gates, the model choice. |
| `skills/experimental/execute/agents/worker.md` | New. Implements a plan and reports against it. |
| `skills/experimental/execute/agents/judge.md` | New. Six lenses, read-only tools. |
| `.claude-plugin/marketplace.json` | `sdlc` entry gains a skill path, an `agents` key, and version `0.2.0`. |
| `skills.sh.json` | `execute` added to the `sdlc` grouping, mirroring the marketplace. |
| `CONTEXT.md` | Glossary entries for subagent, worker, judge, lens. |
| `AGENTS.md` | Structure row, four-places rule, root-`agents/` pitfall. |
| `README.md` | Skill table row; subagents named in the intro. |
| `docs/sdlc.md` | `execute` in the gate table, worked example, and install caveats. |

## Risks

- **Validation is not runtime.**
  The `agents` key passing `claude plugin validate` does not prove the agents resolve once installed, and no plugin in the official marketplace uses the key — every one relies on default discovery.
  Mitigation: the smoke test below installs from a local path and dispatches both agents before the change is called done.
- **The dispatch name is unconfirmed.**
  Official agents are referenced namespaced (`claude-security:explore`), implying `sdlc:worker` and `sdlc:judge`, but that is inference, not something read from a manifest.
  Mitigation: confirm during the smoke test and write the confirmed form into `SKILL.md`; do not ship the guess.
- **skills.sh and vendored installs get the skill without the subagents.**
  `skills.sh.json` carries skills only, so `execute` would arrive with nothing to dispatch — the same shape of degradation as the hook.
  Mitigation: `docs/sdlc.md` says so plainly; `execute` stops with that explanation rather than silently doing the work itself.
- **Twenty-two requirements will not fit in three short files if transcribed.**
  Mitigation: the structural choices above carry most of them; word counts are a verification step, not an afterthought.
- **An uncapped loop on an equal-or-stronger judge can run long and expensive.**
  Accepted in the spec's policy notes.
  Mitigation is visibility: findings surface verbatim each round, so a human can see a cycle failing to converge and stop it.
- **A judge that never returns empty.**
  Style opinions dressed as findings would make the loop non-terminating by construction.
  Mitigation: the lens list is closed, findings must anchor to code or a plan step, and `judge.md` states that a lens with nothing to report is the expected result, not a failure to look hard enough.

## Verification

This repo has no task runner; these are the commands it actually uses.

```bash
claude plugin validate .
```

Manifest mirror — the two files must agree on skill membership:

```bash
jq -r '.plugins[] | select(.name=="sdlc") | .skills[]' .claude-plugin/marketplace.json | sed 's|.*/||' | sort
jq -r '.groupings[] | select(.title=="sdlc") | .skills[]' skills.sh.json | sort
```

Brevity budget — nothing new may exceed the longest existing skill (`pr`, 496 words):

```bash
wc -w skills/experimental/execute/SKILL.md skills/experimental/execute/agents/*.md skills/stable/pr/SKILL.md
```

Smoke test in a scratch project, per the repo's contributing rules:

```bash
claude plugin marketplace add /Users/lstigdon/Code/lstig/agents
claude plugin install sdlc@lstig-agents
claude plugin list   # sdlc must report enabled, not "failed to load"
```

Then, in that scratch project, run `execute` against a small approved plan and confirm: both subagents dispatch under their namespaced names, the judge's output carries all six lens sections, a seeded defect produces a second round, and the run ends with a commit and an unmodified plan file.
