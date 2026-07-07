---
name: task-work
description: Drive work from a Joplin task note, one checklist item at a time.
argument-hint: "note id, note title, or a description of new work"
allowed-tools: mcp__joplin__semantic_search_notes mcp__joplin__search_notes mcp__joplin__read_note mcp__joplin__update_note mcp__joplin__create_note mcp__joplin__list_notebooks
---

Work a task while keeping its Joplin task note the single source of truth.
The `task-notes` skill owns the note format (its TASK-FORMAT.md) and the update mechanics — load it first and follow its conventions for every note change.

1. **Resolve the note.**
   A bare number (`42`) or `[NNNN]` handle resolves by searching titles for the zero-padded `[NNNN]` prefix (`search_notes`, `notebook:Agents title:"[NNNN]"`).
   Otherwise treat the arguments as a description of the work and find it with `semantic_search_notes` scoped to the `Agents` notebook's id (get it from `list_notebooks`), then confirm the match is still an open todo with `read_note` or `search_notes` (`notebook:Agents type:todo iscompleted:0 <keywords>`).
   If semantic search errors (embeddings not enabled) or turns up nothing relevant, fall back to plain `search_notes` with `notebook:Agents type:todo iscompleted:0 <keywords>`.
   `read_note` the match.
   If nothing matches, create a note for the described work per `task-notes`.
   Done when you hold the note id and its full body.

2. **Orient.**
   Switch to the note's working directory, check out its working branch if one is recorded, and read the whole log — it is a record of what already happened, not a suggestion.
   Check the frontmatter `status` before proceeding:
   - `working`: another agent may already be active — warn the user and ask permission before continuing.
   - `blocked`: a previous worker was waiting on input — surface the blocked section to the user, wait for their response, then unblock the note per `task-notes`'s conventions (restore the title, log the response, remove the blocked section) before continuing.
   - `available`: proceed normally.
   Set status to `working` and log a pickup entry: `- <ts> — Picked up task; starting <item>`.
   Done when you can state which unchecked item is next and why.

3. **Work the loop.**
   Take the topmost unchecked **leaf** item — if the topmost item has unchecked sub-items, those sub-items are the actual units of work; descend to them first.
   When an item is done, check it off and log the outcome before taking the next one.
   Check a parent item only after every one of its sub-items is checked.
   If the work surfaces new tasks, add them to the checklist instead of doing them silently.
   If you get blocked (user input needed, outage, missing access), set status to `blocked`, block the note per `task-notes`'s conventions, then poll: periodically re-read the note and re-check the blocker.
   A changed `updated_time` while you were idle means the user edited the note — read the response under `**Response:**` (a ticked option, or text on the freeform line).
   Resume once the user has responded or the blocker has cleared on its own; set status back to `working` and unblock the note before touching the next item.
   If you must stop before every item is complete (session ending, hard blocker you cannot poll through), set status back to `available` so the next worker can pick up cleanly.
   When you think the work is finished, re-read the note and review the whole checklist: confirm every item is genuinely complete, checked off, and has a matching log entry — an update lost to a tool failure looks identical to one you never made.
   Done when that review finds no unchecked items and no gaps.

4. **Close out.**
   Add links for any artifacts produced (PRs, commits, docs), close the task per `task-notes`'s conventions, and tell the user what changed and what to do next.
