---
name: intent
description: Capture an idea as a version-controlled intent — the first artifact in the intent -> spec -> plan chain. Use when the user wants to record a proposal, feature idea, or problem worth solving, before any design or implementation work.
argument-hint: "a description of the idea, or nothing to work from the conversation"
---

An intent records a problem worth solving, cheaply enough that rejecting it costs nothing.
Format, numbering, and templates: [SDLC-FORMAT.md](./SDLC-FORMAT.md).

1. **Pin down the idea** from the arguments or the conversation: what is wrong today, who feels it, what is observably true once fixed.
   Ask only for what is genuinely missing — unknowns belong under `## Open questions`, not in a stalled session.
   Reaching for a mechanism means you are writing a spec, not an intent.

2. **Check for an existing intent** on the same ground (`rg -il <keywords> docs/sdlc/intent/`).
   Update it in place, or supersede it, rather than filing a near-duplicate.

3. **Allocate the number** with `.claude-plugin/hooks/sdlc-next.sh` if the plugin is installed, otherwise by scanning all three artifact directories for the highest `NNNN`.

4. **Write** `docs/sdlc/intent/NNNN-slug.md` from the intent template.
   `owner` is the person whose idea it is — ask if unclear, never assume it is you.

5. **Report** the path and number, and stop.
   The intent is `proposed`; a human accepts or rejects it before `/spec`.
