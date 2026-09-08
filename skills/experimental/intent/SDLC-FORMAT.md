# SDLC Artifact Format

Three chained artifacts: **intent** (problem worth solving) -> **spec** (what the solution must do) -> **plan** (how it gets built).

## Location and layout

One change is one directory, holding one file per stage:

```
<container>/NNNN-kebab-slug/intent.md
<container>/NNNN-kebab-slug/spec.md
<container>/NNNN-kebab-slug/plan.md
```

Resolve the container once per session, in this order:

1. **Name it.** `$SDLC_DIR` if that variable is set, otherwise `changes`.
   `SDLC_DIR` holds a name, never a path; the hooks read the same variable, so skipping this step puts artifacts where the gate does not look.
2. **Find it.** Any existing directory with that name, wherever it sits — `fd -td "^$name\$"`, or `find . -type d -name "$name" -not -path '*/.git/*'`.
   A nested one counts; that is what lets a repo place the container anywhere.
   Two matches is a question for the user, not a guess.
3. **Otherwise create `docs/<name>/`.**

Step 3 is the only statement of the default location; nothing else restates it.

## Numbering and identity

The intent allocates `NNNN` and the slug, which name the directory; every stage in it inherits both.
Each artifact's frontmatter carries `change-id: NNNN`, matching the directory it sits in, so an artifact read on its own still names its change.
The gate blocks a `spec.md` or `plan.md` whose `change-id` disagrees with its directory.

Numbers are never reused — rejected and superseded artifacts stay in the repo as the record of what was considered.
Because the number is in the directory name and in every artifact, `rg 0007 <container>/` returns the whole chain.

A file in a chain directory that is not one of the three stages is not an artifact, and is neither gated nor numbered.

## Status

Status is the gate, and only a human moves an artifact through one.

| Artifact | Values | Gate |
|---|---|---|
| intent | `proposed`, `accepted`, `rejected`, `superseded` | `accepted` before its spec |
| spec | `draft`, `approved`, `superseded` | `approved` before its plan |
| plan | `draft`, `approved`, `implemented`, `superseded` | `approved` before implementation |

An artifact's upstream is its sibling in the same directory: `spec.md` reads `intent.md`, `plan.md` reads `spec.md`.

A superseded artifact adds `superseded-by: NNNN`, the number of the change that replaced it.

## Templates

```md
---
status: proposed
change-id: NNNN
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
change-id: NNNN
owner: <name>
created: YYYY-MM-DD
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
change-id: NNNN
owner: <name>
created: YYYY-MM-DD
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
