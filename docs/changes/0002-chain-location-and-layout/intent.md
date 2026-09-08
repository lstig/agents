---
status: accepted
change-id: 0002
owner: Luke Stigdon
created: 2026-09-07
---

# 0002 - Chain location and layout

## Problem
`SDLC-FORMAT.md` tells a repo it may relocate the artifact chain by saying so in `CLAUDE.md` or `AGENTS.md`.
The gate hook does not read either file.
It matches the literal string `docs/sdlc/(spec|plan)/`, so a repo that takes the offer loses enforcement — not with an error, but with the hook exiting cleanly on every write.
The documented capability and the mechanism disagree, and the failure is silent in the direction that matters: gates that look present and are not.

The same path is written out in eight more places — four `SKILL.md` files, `SDLC-FORMAT.md`, `CONTEXT.md`, `worker.md`, and the guide.
Only `sdlc-next.sh` takes its root as an argument.
So "where the chain lives" is not one decision the repo makes; it is nine copies of an assumption, one of which is load-bearing for enforcement.

Separately, the layout scatters a single change across three directories.
One chain's three artifacts never sit together, so seeing which stages exist means listing three places, a chain's supporting material has nowhere to live, renaming a slug edits three files, and a fourth artifact type would cost a fourth directory and a fourth case in the hook.

## Outcome
- Moving the chain does not silently disable the gates.
  Either the location is genuinely free and enforcement follows it, or the location is fixed and nothing claims otherwise.
- Where the chain lives is stated in one place, not restated in every skill that touches it.
- One change's artifacts are found, listed, and moved together, and a chain has somewhere to keep material that belongs to it rather than to one stage.
- Adding a fourth artifact type later does not require a new directory or a new branch in the gate.
- The existing chain 0001 ends up in whatever the new shape is; nothing is left behind in the old one.

## Constraints
- Breaking changes are free right now, and this window is the reason to act.
  Nothing outside this repo consumes the format yet, so the migration is chain 0001 and nothing else.
  This constraint expires the moment someone installs the plugin and writes an artifact.
- Whatever replaces the current scheme keeps the properties the chain already has: one number and slug per change, numbers never reused, and rejected or superseded artifacts kept as the record.
- The change touches the published format, so it earns the repo's first ADR under `docs/adr/`.

## Open questions
- If the gate stops keying on a fixed path, what tells it that a file is an artifact at all?
  Recognising any `NNNN-slug` chain anywhere in a repo makes relocation real, but it also means an unrelated `rfcs/0012-thing/spec.md` starts being gated.
- Which way should that error?
  Gating only when the upstream artifact exists is permissive, and turns today's loud "spec 0099 has no intent" block into silence.
  Gating whenever the shape matches is strict, and will occasionally block something that was never ours.
- Listing every artifact at one stage — every `proposed` intent, say — is a plain directory listing today.
  Is making that a glob an acceptable trade for keeping each chain together?
