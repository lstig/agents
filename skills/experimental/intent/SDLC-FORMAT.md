# SDLC Artifact Format

Three chained artifacts: **intent** (problem worth solving) -> **spec** (what the solution must do) -> **plan** (how it gets built).

## Location and numbering

```
docs/sdlc/intent/NNNN-kebab-slug.md
docs/sdlc/spec/NNNN-kebab-slug.md
docs/sdlc/plan/NNNN-kebab-slug.md
```

A repo may relocate these in its `CLAUDE.md` or `AGENTS.md`; check there first.

The intent allocates `NNNN` and the slug; its spec and plan inherit both, so `rg 0007 docs/sdlc/` returns the whole chain.
Numbers are never reused — rejected and superseded artifacts stay in the repo as the record of what was considered.

## Status

Status is the gate, and only a human moves an artifact through one.

| Artifact | Values | Gate |
|---|---|---|
| intent | `proposed`, `accepted`, `rejected`, `superseded` | `accepted` before its spec |
| spec | `draft`, `approved`, `superseded` | `approved` before its plan |
| plan | `draft`, `approved`, `implemented`, `superseded` | `approved` before implementation |

A superseded artifact adds `superseded-by: NNNN`.

## Templates

```md
---
status: proposed
owner: <name>
created: YYYY-MM-DD
---

# NNNN - <title>

## Problem
What is wrong today, and who feels it.

## Outcome
What is observably true once it is solved.

## Constraints
Optional. Hard limits known now.

## Open questions
Optional. What must be answered before this can be specified.
```

```md
---
status: draft
owner: <name>
created: YYYY-MM-DD
intent: NNNN
---

# NNNN - <title>

## Summary
The solution in a few sentences.

## Requirements
Numbered, each independently checkable.

## Out of scope
What this deliberately does not do.

## Acceptance criteria
How anyone confirms the requirements are met.

## Policy notes
Optional. Policy conflicts found while drafting, and each one's resolution or waiver.
```

```md
---
status: draft
owner: <name>
created: YYYY-MM-DD
spec: NNNN
---

# NNNN - <title>

## Approach
The strategy, and the alternatives rejected.

## Steps
Ordered units of work.

## Affected files
Paths to create or change, with a phrase on each.

## Risks
What could go wrong, and the mitigation.

## Verification
Commands that prove it works, taken from this repo's task runner.
```

## Boundaries

- An intent holds no mechanism; a spec holds no file paths or code; neither holds implementation.
- No logs or changelogs — git history is the record.
- No progress checkboxes — these are decision records, not task trackers.
