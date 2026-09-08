# 0001 - One directory per change

Status: accepted
Date: 2026-09-07

## Context

The artifact chain shipped as three stage directories under a hardcoded path: `docs/sdlc/intent/NNNN-slug.md`, `docs/sdlc/spec/NNNN-slug.md`, `docs/sdlc/plan/NNNN-slug.md`.
Nine files restated that path — the gate hook, the numbering hook, four skills, and the human docs — and the format file claimed a repo could relocate the chain by saying so in its `CLAUDE.md`.
That claim was false: the gate matched the literal string `docs/sdlc/`, so relocating the chain turned enforcement off silently, which is the worst way for a gate to fail.
The stage directories also split one change across three places, so nothing but a shared filename tied a spec to the intent it answers.

## Decision

One change is one directory: `<container>/NNNN-slug/` holding `intent.md`, `spec.md`, and `plan.md`.
The container is a directory *named* `changes`, recognised wherever it sits in the tree, and `SDLC_DIR` overrides that name for a repo that needs a different word.
A repo with no container yet gets one in a default location, which the artifact format states — and, so that it cannot drift, states alone.

The gate matches shape rather than path: a write to `<...>/changes/NNNN-slug/(spec|plan).md` is an artifact write anywhere in any repo, and anything else is not gated at all.
An artifact's upstream becomes its sibling in the same directory instead of a glob in another one.
Every artifact carries `change-id: NNNN`, and the gate blocks a spec or plan whose `change-id` disagrees with the directory holding it.

## Alternatives

- **A config file naming the container.**
  Explicit and unambiguous, but it adds a config surface this repo does not otherwise have, and a second place to keep in sync with the marketplace entry.
  A directory name already carries the information.
- **An absolute path in `SDLC_DIR`.**
  Simpler than comparing a name, but it re-hardcodes the path one level up: every checkout with a different layout needs the variable set, and unset means broken rather than defaulted.
- **Keeping `docs/sdlc/` and only fixing the false relocation claim.**
  The cheapest option, and the fallback had the layout stayed flat.
  Chain directories are what make the shape rule possible, so it was rejected once the layout changed.
- **Blocking any unrecognised file inside a chain directory.**
  Stricter, but it forecloses the fourth artifact type the chain anticipates; a non-stage file is deliberately not gated.

## Consequences

- Relocating the chain no longer disables the gate, and vendored installs get the same enforcement without editing the script.
- The name `changes` is load-bearing: a repo already using `changes/` for something else finds writes to `changes/NNNN-slug/spec.md` gated, and must set `SDLC_DIR`.
  This is the accepted cost of not adding a config file.
- `change-id` duplicates the number that is already in the directory name.
  That is deliberate — the duplication is checkable, so requirement 11 makes the gate check it, and an artifact read in a diff or on its own still names its change.
- The `change-id` check is enforced on structured file writes — Write and Edit, which name the target and the text they propose.
  A Bash-driven write names neither, so it is not intercepted and a mismatched `change-id` can reach disk that way.
  The guarantee is best-effort rather than absolute; the next Write or Edit to that file catches what the shell slipped past.
- Listing every artifact at one stage is now `<container>/*/intent.md` rather than a directory listing.
- The stage-specific `intent:` and `spec:` frontmatter keys are gone, and with them the only way an artifact could say which *other* change it assumed.
  Ordering between changes is a separate problem, left open.
- Anyone with artifacts in the old layout moves them; the skills, hooks, and docs describe the new layout as the only layout.
