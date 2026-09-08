---
name: plan
description: Turn an approved spec into an implementation plan, read-only — the audit trail and baseline for later review. Use when the user wants an implementation strategy, approach, or plan for a spec that has been approved.
argument-hint: "spec number, or a description of the approved spec"
---

A plan is the strategy for satisfying a spec, written without touching a line of source.
It records what was approved and is the baseline a reviewer checks the diff against.
The `intent` skill owns the artifact format (its SDLC-FORMAT.md); load it now if it is not in context.
Resolve the container as that file describes; `<container>` below means the directory you resolved, never a path you assumed.

1. **Resolve and read the spec**, and its intent — a bare number is the chain directory `<container>/NNNN-*/`, and both artifacts are files inside it.
   Read the intent too; it holds the *why* the spec assumes.
   The spec's status must be `approved`; anything else stops here and gets reported, never self-approved.

2. **Investigate read-only**: the patterns the change touches, the tests covering them, the seams it will use.
   Make no edits — a plan is cheap to rewrite only while nothing has been built.
   Every path you name must be one you opened.

3. **Write** `plan.md` beside that spec, in its chain directory, from the plan template.
   `change-id` is the chain's number; the gate rejects a plan that disagrees with the directory holding it.
   Name the alternatives you rejected; a plan showing only the chosen path cannot be argued with, which makes review theatre.
   `## Verification` holds commands that actually run here — from the `Makefile`, `Taskfile.yaml`, `justfile`, or `package.json`.

4. **Report** the path and walk the user through the approach and risks.
   The plan is `draft`; implementation is a separate session starting from the approved file.
