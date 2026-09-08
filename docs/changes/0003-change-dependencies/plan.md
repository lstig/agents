---
status: draft
change-id: 0003
owner: Luke Stigdon
created: 2026-09-08
---

# 0003 - Change dependencies

## Approach

All enforcement lands in `.claude-plugin/hooks/sdlc-gate.sh`, which already has every piece this needs: it normalises a target path, decomposes it into container / chain / stage, reconstructs the text a write proposes, and reads a frontmatter key with `key_of`.
The change adds one parser and two checks on top of that machinery.

The gate currently recognises two stage files and does the same two things to both.
It grows a third recognised file and a second axis:

- **`intent.md`** becomes recognised for one purpose only — validating the `depends-on` it proposes.
  No `change-id` check and no upstream check are added to it (spec requirement 17), so the `case` has to route by stage rather than fall through into the existing checks.
- **`spec.md` and `plan.md`** keep everything they do today, and gain one check afterwards: read the chain's `intent.md` from disk, resolve each declared dependency, and block while any is unmet.

Reading the intent from disk rather than from the proposed text is deliberate and is the asymmetry to keep straight while implementing.
For `intent.md` the file being written *is* the declaration, so the check must read the proposal or it would block the edit that repairs a bad one.
For `spec.md` and `plan.md` the declaration is a different file that this write does not touch, so disk is the only correct source.

Parsing stays hand-rolled in bash.
`key_of` already returns `[0004, 0011]` as a scalar string, so a `deps_of` built on it needs only to strip the brackets, split on commas, and trim — no YAML library, and no new runtime dependency beyond the `jq` the hook already requires.

**Alternatives rejected:**

- **Enforce in the skills instead of the hook.** The spec's first policy note forbids softening enforcement to advisory, and a skill instruction is exactly that — the gate exists because instructions are not enforcement.
- **Parse frontmatter with `yq`.** Correct YAML for free, but it adds a second hard dependency to a hook whose stated failure mode is `command -v jq || exit 0`. Requirement 2 pinned the value to a single-line flow sequence precisely so bash can read it.
- **Support block-style lists** (`depends-on:` then `  - 0004`). Requirement 2 says flow sequence; accepting both doubles the parser and the ways a file can be wrong.
- **Resolve dependencies transitively.** Requirement 18 caps it at one hop, and the spec puts transitive enforcement out of scope.
- **Check `depends-on` on `spec.md`/`plan.md` writes against proposed text too.** Those files never carry the key (requirement 3); reading them for it would invite someone to add one there.

## Steps

1. **Add `deps_of` to the gate**, beside `key_of`.
   Takes a document on stdin, returns the declared numbers one per line, and signals malformed input distinguishably from absent input — absent is the common case and must stay silent.
   Reject: a value not wrapped in `[...]`, an entry that is not four digits, and an empty `[]` (requirement 1 says an empty list is never written, so accepting it would let one exist).

2. **Add `chain_dir_for`**, resolving a number to a chain directory inside a given container path.
   One glob of `<container>/NNNN-*`; prints the path or nothing.
   Guard the glob against `set -e` and against matching nothing.

3. **Route `intent.md` in the stage `case`.**
   Add an `intent.md` arm that runs only the declaration checks and then `continue`s, leaving the `change-id` and upstream blocks reachable only from the `spec.md` and `plan.md` arms.
   This is a restructure of the loop body, not an insertion: today the checks sit below the `case` and run for every recognised stage.

4. **Implement the write-time declaration checks** for `intent.md`, against proposed text only, in requirement order: malformed (14), self-reference (13), unresolvable (12).
   Each message names the file and the offending entry (15).
   With no proposed text — a shell write — do nothing, matching how `change-id` already declines to guess.

5. **Implement the dependency block** for `spec.md` and `plan.md`, after the existing upstream status check so the more fundamental failure reports first.
   Read the sibling `intent.md`, `deps_of` it, and for each number resolve the chain and read its `plan.md` status.
   Block unless every one reads `implemented`; the message names the dependency and the status it actually has (requirement 9).
   A dependency whose chain no longer resolves, or which has no `plan.md`, is unmet — say which of the two it is, since the remedies differ.

6. **Update `SDLC-FORMAT.md`**: a `## Dependencies` section covering shape, intent-only placement, what "met" means, that declaring is binding and omitting is the way to stay unblocked, and that only a human decides the field's contents.
   Add the optional `depends-on` line to the intent template.

7. **Update the four `SKILL.md` files.**
   `intent`: may write `depends-on` when the user asks, may suggest one, never adds one unasked.
   `spec`, `plan`, `execute`: report the chain's declared dependencies with each status, marked met or unmet, when reading the chain (requirement 19).
   One or two lines each — these skills are already terse.

8. **Update `docs/sdlc.md`**: add the dependency block to the gate table, and a short passage saying the field is optional, binding once declared, and cleared by removing it.

9. **Add the `dependency` term to `CONTEXT.md`**, after **Artifact chain** where the chain vocabulary sits.

10. **Write `docs/adr/0002-optional-but-binding-dependencies.md`**, recording why the field is opt-in yet enforced, and the three rejected readings (advisory-only, spec-approved threshold, per-reference thresholds).

11. **Bump `sdlc` to `0.4.0`** in `.claude-plugin/marketplace.json`.
    `skills.sh.json` needs no edit: no skill is added, removed, or regrouped.

## Affected files

| Path | Change |
|---|---|
| `.claude-plugin/hooks/sdlc-gate.sh` | `deps_of`, `chain_dir_for`, `intent.md` routing, both new checks. The only behavioural change in the repo. |
| `skills/experimental/intent/SDLC-FORMAT.md` | `## Dependencies` section; `depends-on` in the intent template. |
| `skills/experimental/intent/SKILL.md` | Who may write the field, and that it is never assumed. |
| `skills/experimental/spec/SKILL.md` | Report declared dependencies with statuses. |
| `skills/experimental/plan/SKILL.md` | Same. |
| `skills/experimental/execute/SKILL.md` | Same, at the point it reads the plan and its chain. |
| `docs/sdlc.md` | Gate table row; passage on the optional-but-binding field. |
| `CONTEXT.md` | **Dependency** term with its _Avoid_ list. |
| `docs/adr/0002-optional-but-binding-dependencies.md` | New ADR. |
| `.claude-plugin/marketplace.json` | `sdlc` version `0.3.0` -> `0.4.0`. |

No test files: this repo has none, and no task runner to add them to.

## Risks

- **The loop restructure in step 3 can fail open.**
  The `change-id` and upstream checks currently run for every recognised stage; moving them under a stage arm risks a path that recognises a `spec.md` and then checks nothing.
  Mitigation: the verification below re-runs the existing gate cases explicitly, not just the new ones.

- **Globbing under `set -euo pipefail`.**
  An unmatched glob expands to the literal pattern, and a `find` that matches nothing exits non-zero and kills the script — the failure mode `sdlc-next.sh` already documents.
  A gate that dies mid-check blocks nothing, which is the fail-open this hook exists to avoid.

- **Container path assembly.**
  The existing code derives `parent` textually and never has to *use* it as a path; step 2 does.
  A relative target combined with `cwd`, as the `abs` line already handles, is the shape to copy rather than reinvent.

- **A deadlocking cycle.**
  Two intents declaring each other block both chains, and the message describes one hop.
  Accepted by the spec; the mitigation is that the message names what to remove.

- **Shell writes remain best-effort.**
  A `depends-on` written by a heredoc is not validated, exactly as `change-id` is not.
  Consistent with today's behaviour, and worth stating in the ADR so it is not read as an oversight.

- **The intent's own repair path.**
  If step 4 ever reads disk instead of the proposal, a bad `depends-on` becomes unfixable by the tool that wrote it.
  This is the single highest-value case in the verification list.

## Verification

There is no `Makefile`, `Taskfile.yaml`, `justfile`, or `package.json` in this repo, so verification is `shellcheck`, `claude plugin validate`, and hand-driven hook payloads.

```sh
shellcheck .claude-plugin/hooks/sdlc-gate.sh
claude plugin validate .
```

Drive the hook the way Claude Code does — a JSON payload on stdin, exit 2 meaning blocked:

```sh
gate() {
  jq -n --arg cwd "$PWD" --arg f "$1" --arg c "$2" \
    '{cwd:$cwd, tool_input:{file_path:$f, content:$c}}' |
    .claude-plugin/hooks/sdlc-gate.sh
  echo "exit=$?"
}
```

Build the fixtures in a scratch container so no real chain is touched:

```sh
export SDLC_DIR=tmpchanges
mkdir -p tmpchanges/0004-landed tmpchanges/0005-unlanded tmpchanges/0006-dependent
printf -- '---\nstatus: implemented\nchange-id: 0004\n---\n' > tmpchanges/0004-landed/plan.md
printf -- '---\nstatus: accepted\nchange-id: 0004\n---\n'    > tmpchanges/0004-landed/intent.md
printf -- '---\nstatus: approved\nchange-id: 0005\n---\n'    > tmpchanges/0005-unlanded/plan.md
printf -- '---\nstatus: accepted\nchange-id: 0005\n---\n'    > tmpchanges/0005-unlanded/intent.md
```

Cases, each with its expected exit:

| Case | Expect |
|---|---|
| intent declaring `[0004]` | 0 |
| intent declaring `[0099]` — no such chain | 2, message names 0099 |
| intent in chain 0006 declaring `[0006]` | 2, self-reference |
| intent declaring `[4]`, `0004`, or `[]` | 2, malformed |
| intent with no `depends-on` | 0 |
| spec in a chain whose intent declares `[0004]` | 0 |
| spec in a chain whose intent declares `[0005]` | 2, names 0005 and `approved` |
| plan in that same chain | 2, same reason |
| spec in a chain whose intent declares a chain with no `plan.md` | 2, says so |
| after `0005/plan.md` -> `implemented`, both writes | 0 |
| removing the declaration from the intent, both writes | 0 |
| **regression:** spec whose intent reads `proposed` | 2, existing message |
| **regression:** spec whose `change-id` disagrees with its directory | 2, existing message |
| **regression:** intent write repairing its own bad `depends-on` | 0 |
| **regression:** a path outside any container | 0 |

Finish by removing `tmpchanges/` and confirming the real chains are unaffected:

```sh
rm -rf tmpchanges
rg -n 'depends-on' docs/changes/*/spec.md docs/changes/*/plan.md    # expect no matches
```
