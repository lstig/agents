---
status: draft
owner: Luke Stigdon
created: 2026-09-07
intent: 0002
---

# 0002 - Chain location and layout

## Summary
One change gets one directory: `<container>/NNNN-slug/`, holding `intent.md`, `spec.md`, and `plan.md`.
The container is a directory named `changes`, defaulting to `docs/changes/` but recognised wherever it sits, so moving it keeps the gates working instead of silently switching them off.
The gate identifies an artifact by the shape around it — a chain directory inside a `changes` container — rather than by a hardcoded path, and the default location is stated once instead of nine times.

## Requirements

1. A change's artifacts live at `<container>/NNNN-slug/intent.md`, `spec.md`, and `plan.md`.
   The number and slug belong to the directory; the stage is the filename.
2. The container is a directory named `changes`.
   The default is `docs/changes/`, and a repo may place it anywhere.
3. The gate treats a write as an artifact write when the path is `<...>/changes/NNNN-slug/<stage>.md`, wherever that sits in the tree.
   A path that does not match is not gated.
4. `SDLC_DIR` overrides the container name for repos that must call it something else.
   Unset, the gate uses `changes`.
5. Inside a chain directory, `spec.md` requires `intent.md` to read `accepted`, and `plan.md` requires `spec.md` to read `approved`.
   A missing upstream file blocks, and says which file is missing.
6. Files in a chain directory that are not one of the three stages are never gated, so a later artifact type costs no change to the gate.
7. The default location is stated in exactly one file.
   Every skill that reads or writes artifacts derives the location rather than restating it.
8. Numbering scans the container's chain directories, and the next number is one above the highest.
   Numbers are still never reused.
9. The chain keeps the properties it has today: one number and slug per change, a shared slug across stages, and rejected or superseded artifacts left in place as the record.
10. Chain 0001 moves to the new layout, keeping its number, slug, and each artifact's status.
    Nothing is left in the old location.
11. `CONTEXT.md` gains **change** as the unit — one number, one slug, one directory — with **artifact chain** kept for the files inside it.
12. The change is recorded as the repo's first ADR under `docs/adr/`.
13. The `sdlc` plugin's version bump reflects a breaking format change, and the guide documents the new layout as the only layout.

## Out of scope
- Migrating anyone else's artifacts, or a migration script.
  Chain 0001 is the whole population.
- Changing artifact content: the templates, the status values, and the gate thresholds are untouched.
- Enforcing the plan-approved gate, still out of reach for a path-matching hook (spec 0001).
- Per-repo configuration beyond `SDLC_DIR` — no config file, no manifest key.
- Reorganising `docs/adr/`, which keeps its flat `NNNN-title.md` shape.

## Acceptance criteria
- `ls docs/changes/0001-plan-execution-and-adversarial-review/` lists exactly `intent.md`, `spec.md`, and `plan.md`, and `docs/sdlc/` no longer exists.
- `rg 0001 docs/changes/` returns the whole chain, and the three statuses are `accepted`, `approved`, `implemented` as before the move.
- A write to `docs/changes/0003-x/spec.md` is blocked while `docs/changes/0003-x/intent.md` reads `proposed`, and allowed once it reads `accepted`.
- The same write is blocked identically after moving the container to `changes/` at the repo root — the gate follows the directory rather than the path.
- A write to `docs/changes/0003-x/notes.md` is not gated.
- A write to an unrelated `rfcs/0012-thing/spec.md` is not gated.
- A write to `docs/changes/0004-y/spec.md` with no `intent.md` beside it is blocked, and the message names the missing file.
- `rg -l 'docs/sdlc' -- . ':!docs/changes'` returns nothing, and exactly one file states the default container path.
- `.claude-plugin/hooks/sdlc-next.sh` prints `0003` against the migrated repo.
- `claude plugin validate .` passes, and the `sdlc` entry's version has been bumped.

## Policy notes

- **The carried question about strict versus permissive gating, resolved by the container.**
  Intent 0002 asked whether a missing upstream should block (strict, with false positives on unrelated files) or be ignored (permissive, losing today's loud "spec 0099 has no intent").
  Requirements 3 and 5 take both halves: outside a `changes` container nothing is gated, so the false-positive case disappears; inside one, a missing upstream blocks exactly as it does today.
  This is the one design decision in this spec that a human should confirm rather than skim.

- **Location-freedom is by directory name, not by configured path.**
  Requirement 2 makes `changes` the recognised name anywhere in the tree, which is what lets requirement 3 drop the hardcoded prefix without adding a config file.
  The cost is that the name is now load-bearing: a repo that already uses `changes/` for something else, or that wants a different word, needs `SDLC_DIR`.
  Accepted as the cheaper trade against a config surface nothing else in this repo has.

- **Pre-1.0 versioning conflicts with the repo's own rule.**
  `AGENTS.md` says major for breaking format changes, which would mean `sdlc` 0.2.0 -> 1.0.0.
  That number claims a stability the skills do not have; they are all `experimental` by their own directory.
  Resolution: bump the minor to 0.3.0, the breaking increment while a package is pre-1.0, and let 1.0.0 mean what `skills/stable/` means.
  Requirement 13 asks only that the bump reflect a breaking change; the plan may argue the other way.

- **The third carried question is answered by the layout, not waived.**
  Listing every artifact at one stage becomes `docs/changes/*/intent.md` rather than a directory listing.
  Accepted when the layout was chosen; recorded here so the trade is visible to anyone reviewing the result rather than the discussion.

- **Requirement 12 is the repo's own ADR test, not ceremony.**
  Hard to reverse once artifacts exist elsewhere, surprising without context, and chosen against real alternatives — all three legs hold, and `docs/adr/` does not exist yet, so this change creates it.
