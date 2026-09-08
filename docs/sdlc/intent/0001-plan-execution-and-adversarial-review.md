---
status: accepted
owner: Luke Stigdon
created: 2026-09-07
---

# 0001 - Plan execution and adversarial review

## Problem
The artifact chain stops at an approved plan.
Everything after that — building the thing and judging whether it was built right — happens in an ordinary session with no defined shape.

Two costs follow.
The plan stops being load-bearing: an implementing session drifts from it, and nothing notices, so the approved record and the shipped code diverge silently.
And review is self-review: the same context that wrote the code assesses it, which reliably produces agreement rather than scrutiny.
A human is left to do the adversarial reading themselves, at the point where they have the least information about what the agent actually did versus what it claims it did.

The gates the chain does enforce are all pre-implementation.
The stage with the most room for error is the one with no structure at all.

## Outcome
Implementation is a defined stage of the chain, not a free-form session.

- An approved plan can be handed to the execution stage and comes back with the work done and a statement of what was done against each step of the plan.
- The work is reviewed by something that did not do it and is pointed at finding fault — unmet plan steps, missing verification, defects, unrequested scope — rather than at confirming success.
- Findings are not advice.
  A review that finds anything sends the work back for repair, and the cycle repeats until a review comes back empty; the stage does not finish on unresolved findings.
- The stage's durable output is the code itself — a commit on a branch, or a pull request — not another markdown artifact under `docs/sdlc/`.
- Discovering that the approved plan is wrong stops the stage and returns to the human.
  The stage never edits or reinterprets a plan to make the work fit.
- A human still decides what happens next; nothing in the stage marks its own output as accepted, merges it, or moves the plan to `implemented`.

## Constraints
- Fits the existing chain: consumes an `approved` plan, uses the same `NNNN` and slug, keeps human status transitions.
- The reviewer must not inherit the implementer's context, or the adversarial property is lost.
- The repair cycle has no fixed round limit, so the human needs enough visibility to interrupt a cycle that is not converging.
- New skills start in `skills/experimental/`, and shipping one means updating the README, the marketplace entry, and `skills.sh.json` together.
