---
status: approved
change-id: 0003
owner: Luke Stigdon
created: 2026-09-08
---

# 0003 - Change dependencies

## Summary
An intent may declare `depends-on`, a list of change numbers whose work it assumes has already landed.

The field is optional and nothing infers it.
Declaring one, though, is an assertion the tooling honours: while a declared dependency has not landed, the chain's spec and plan cannot be written.
Not declaring a dependency is how a change says it does not need one.

This closes a gap left open when the upstream numbers came out of frontmatter: a chain says which stage follows which, and nothing says which change follows which.

## Requirements

### The field

1. An intent may carry a `depends-on` key in its frontmatter, holding the change numbers this change assumes have landed.
   It is omitted when the change has none; an empty list is never written.
2. The value is a single-line flow sequence of four-digit numbers — `depends-on: [0004]`, `depends-on: [0004, 0011]` — so it stays readable as text and parseable without a YAML library.
   Quoted and bare numbers are the same value, matching how `change-id` is already read.
3. `depends-on` is declared only on the intent.
   `spec.md` and `plan.md` carry no dependency key; the chain inherits its intent's.
4. A dependency is added to or removed from an intent in place, at any status, without superseding it.
5. Absence means the change declares no dependency, and is never inferred.
   An agent writes one when a human directs it to, and may suggest one when the chain makes it likely — but never adds a dependency on its own judgement.

### What a dependency means

6. A dependency is **met** when the change it names has landed: that change's `plan.md` reads `status: implemented`.
   A chain with no `plan.md` yet is unmet, not an error.
7. There is no looser threshold, and a reference cannot state its own.

### What declaring one enforces

8. Declaring a dependency opts the chain into enforcement.
   While any dependency an intent declares is unmet, writes to that chain's `spec.md` and `plan.md` are blocked.
9. A block names the unmet dependency and the status it actually has, so the reason is legible without opening the other chain.
10. The only way past a block is for the dependency to land, or for the declaration to be removed from the intent.
    There is no override flag.
    Removal is a human's call, carried out by an agent if asked; an agent never removes a declaration on its own initiative to unblock work.
11. Enforcement reaches as far as the hook can see.
    Implementation writes go to ordinary source paths and are not gated — the same limit the existing plan-approved gate already has.

### What is checked when a dependency is written

12. A write to an `intent.md` is rejected when its proposed `depends-on` names a number with no chain directory in the same container.
    A dependency that cannot be resolved cannot be honoured, so it is refused at the point it is written rather than blocking the chain later for a reason nobody can act on.
13. A write to an `intent.md` is rejected when its proposed `depends-on` includes the change's own number.
14. A write to an `intent.md` is rejected when its proposed `depends-on` is malformed — not a flow sequence, or holding an entry that is not four digits.
15. Every rejection names the file and the offending entry.
16. These checks read the text the write proposes, not the file on disk, so the edit that repairs a bad `depends-on` is never the one blocked.
    Shell writes stay best-effort, exactly as the `change-id` check already is.
17. Recognising `intent.md` introduces no upstream gate on intents.
    An intent still has no upstream; it is recognised only for this field.
18. Resolving a chain's dependencies reads, per number declared, one directory listing in the container and that chain's `plan.md` status.
    Enforcement stops at one hop: a dependency's own dependencies are not consulted.

### What is reported

19. The `spec`, `plan`, and `execute` skills report a chain's declared dependencies, each with its current status and marked met or unmet, as part of reading that chain.
    This is a line added to skills that already exist; no new skill, no new command.
20. A dependency's status is read when it is needed, from the named chain, never cached or copied into the depending change.

### Reverse view

21. Only the forward reference is recorded.
    There is no `blocks` or `required-by` key, and nothing is kept in sync.
22. The reverse view — what is waiting on a change — is a search over the container's intents.

### Repo changes

23. The artifact format documents `depends-on`: its shape, that it lives on the intent, what "met" means, and that declaring one is enforced.
    The intent template shows it as optional.
24. The guide documents the field and lists the dependency block alongside the existing gates, including that removing the declaration is the way out.
25. `CONTEXT.md` gains **dependency** as a term, with the vocabulary to avoid.
26. The decision is recorded as an ADR: the field is optional, declaring it is binding, and a future reader will ask why it works that way round.
27. The `sdlc` plugin version is bumped, and `claude plugin validate .` passes.

## Out of scope
- **Cycle detection.**
  Closing a loop means walking the graph, which requirement 18 rules out.
  Two changes declaring each other deadlock both chains until a human removes a declaration; the block message names what to remove, and that is the whole remedy.
- **Per-reference thresholds.**
  `depends-on: [{change: 0004, needs: spec}]` was considered and rejected; the threshold is fixed at implemented for every reference.
- **An override or force flag.**
  Requirement 10 is the only escape, deliberately: a bypass that leaves the declaration in place would make the field mean nothing.
- **Transitive enforcement.**
  A dependency's own dependencies are its problem, not this chain's.
- **A reverse index**, a dependency graph rendering, or any ordering report across all changes.
- **Dependencies on anything that is not a change** — external tickets, upstream repositories, releases.
- **Migrating existing chains.**
  The field is optional and no existing artifact carries it, so every chain in the repo is untouched and unblocked.
- **Changing status values or the existing gate thresholds.**

## Acceptance criteria
- An intent with no `depends-on` behaves exactly as it does today: its spec and plan are gated by its own intent's status only.
- An intent declaring a dependency whose `plan.md` reads `implemented` has its spec and plan written without obstruction.
- An intent declaring a dependency whose `plan.md` reads `approved` has a write to its `spec.md` blocked, and the message names the dependency and reports `approved`.
- The same chain's `plan.md` write is blocked for the same reason.
- When that dependency's `plan.md` is moved to `implemented`, both writes succeed with no edit to the depending chain.
- Removing the declaration from the intent unblocks the chain immediately, and is the only other thing that does.
- An intent declaring a dependency on a chain that has no `plan.md` at all is blocked, not errored.
- A write to `docs/changes/0003-change-dependencies/intent.md` proposing `depends-on: [0099]` is blocked, and the message names 0099.
- A write to that file proposing `depends-on: [0003]` is blocked as a self-reference.
- A write proposing `depends-on: [3]`, or an unbracketed scalar instead of a list, is blocked as malformed.
- `rg -l 'depends-on' docs/changes/*/spec.md docs/changes/*/plan.md` returns nothing.
- Searching the container's intents for a change's number returns every chain waiting on it, which is the whole reverse view.
- The existing gate behaviour is unchanged: a spec whose intent is `proposed` is still blocked, and a `change-id` disagreeing with its directory is still blocked.
- `claude plugin validate .` passes and the `sdlc` entry's version has been bumped.

## Policy notes

- **This gives up specifying two related changes in parallel, for the chains that declare a dependency.**
  Blocking a spec until another change is implemented is exactly what makes parallel design impossible, and it is the cost of requirement 8.
  Resolution: accepted, on the grounds that the field is opt-in.
  A chain that wants to be specified alongside its neighbour simply does not declare the dependency, and requirement 5 guarantees none appears unless a human asks for it.
  The judgement moves to the person writing the intent, which is where it belongs.
  A plan may not soften this by making enforcement advisory.

- **The hook grows from checking one file to reading another chain.**
  Today the gate reads the artifact being written and its sibling; requirement 8 makes it resolve a number to a directory and read a third file's status.
  Requirement 18 caps that at one hop and no graph walk, but it is still the first time the hook's answer depends on a part of the tree the write does not name.
  Resolution: accepted as the minimum that makes a declaration binding.

- **A cycle deadlocks, and nothing detects it.**
  Two intents declaring each other block both chains permanently.
  The remedy is a human removing one declaration, which the block message points at, but the message describes one hop and cannot say "this is a cycle."
  Accepted rather than solved: detection needs the graph walk requirement 18 rules out, and a cycle between two changes in one repo is loud enough to diagnose by reading two files.

- **Version bump is a minor, not a major.**
  `AGENTS.md` says major for breaking format changes.
  This adds enforcement that can block writes which pass today, which is close to that line — but no existing artifact carries the key, so no chain in the repo changes behaviour.
  Resolution: minor, 0.3.0 -> 0.4.0.
  Pre-1.0, the minor is where a format change lands; 1.0.0 stays reserved for what `skills/stable/` means.

- **Requirement 26 passes the repo's own ADR test.**
  Hard to reverse once chains in the wild are gated on the key; surprising without context, since "optional field, binding once written" is an unusual shape; and a real trade-off, with advisory-only, spec-approved thresholds, and per-reference thresholds all considered and rejected.

- **Carried open questions: none.**
  The intent's four open questions were answered before it was accepted, and requirements 3, 6, 12 through 14, and 21 are those answers.
