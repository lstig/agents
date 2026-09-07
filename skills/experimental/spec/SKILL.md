---
name: spec
description: Turn an accepted intent into a spec — what the solution must do, checked against organizational policy. Use when the user wants to specify, design, or write requirements for an intent that has been accepted.
argument-hint: "intent number, or a description of the accepted intent"
---

A spec states what must be true for an intent to be satisfied, and nothing about how to build it.
The `intent` skill owns the artifact format (its SDLC-FORMAT.md); load it now if it is not in context.

1. **Resolve and read the intent** — a bare number is `docs/sdlc/intent/NNNN-*.md`, otherwise search that directory.
   No match means offering `/intent`, not inventing one.
   Its status must be `accepted`; anything else stops here and gets reported, never self-accepted.

2. **Load the policy that applies** — whatever skills or standards this repo carries for security, API design, data handling, or compliance.
   Conflicts go under `## Policy notes` with their resolution or waiver.
   Surfacing a conflict is the point; quietly resolving one hides the decision from review.

3. **Read enough of the codebase to be concrete.**
   Requirements must be checkable against the system that exists.
   Write no code.

4. **Write** `docs/sdlc/spec/NNNN-slug.md` from the spec template, inheriting the intent's number and slug.
   Carry unresolved open questions forward explicitly; never drop one.

5. **Report** the path, naming the policy conflicts and carried-over questions in your message — they are why a human reads this.
   The spec is `draft` until a human approves it.
