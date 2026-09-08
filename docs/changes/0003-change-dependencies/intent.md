---
status: accepted
change-id: 0003
owner: Luke Stigdon
created: 2026-09-08
---

# 0003 - Change dependencies

## Problem
Nothing in a change says that it assumes another change is already done.

Change 0002 dropped the `intent:` and `spec:` upstream numbers because a sibling file in the chain directory is the link, and it named ordering between changes as deliberately out of scope: "dropping the upstream number leaves no way to say one change assumes another; that gap is deliberate here and is its own change."
This is that change.

Today the ordering lives only in the prose of whoever wrote the chain, or in someone's head.
A reader picking up an accepted intent cannot tell whether it is ready to specify or whether it is waiting on work that has not landed.
Someone scheduling work has to read every open chain to reconstruct an order that the author already knew.
The person who wrote the chain feels it least; everyone who reads it later feels it most.

## Outcome
A change can state which other changes it assumes are already done, and a reader sees that ordering without reconstructing it.

Specifically:

- Reading one change tells you what it waits on, and how far along those changes are.
- A reference to a change that does not exist is caught when it is written, not discovered later by a confused reader.
- Nothing is blocked by an unmet dependency. Two related changes can still be specified in parallel; the record describes sequence, it does not schedule work.

## Constraints
- The chain stays plain files in git, readable without tooling. Whatever expresses the ordering has to survive being read as text.
- `superseded-by` is the only cross-chain reference in the format today. Adding a second is a deliberate widening, not an accident.
- The gate matches on path shape and reads frontmatter of the file being written. Anything requiring it to traverse other chains is a larger change to the gate than this warrants.

## Decisions carried into the spec
Settled with the owner while proposing this. Each is a boundary on the solution, not the solution itself; the spec owns the mechanism.

1. The ordering belongs to the change, so it is declared once at the head of the chain rather than per artifact. A dependency found later is added in place, without superseding anything.
2. A dependency is met when the change it names has actually landed — its work is implemented, not merely designed. This is the strict reading, chosen so a reader knows the ground a change stands on exists.
3. A reference naming a change that has no chain, or naming its own change, is rejected at write time. Whether a dependency is *met* is never gated: depending on unfinished work is the ordinary case, and blocking it would put the gate in the business of scheduling.
4. Only the forward reference is recorded. The reverse view — what is waiting on this change — is derived by searching the container, so there is one source of truth and nothing to keep in sync.
