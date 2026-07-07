# The task workflow

A pair of skills that turn a Joplin note into the single source of truth for one task.

- [`task-notes`](../skills/experimental/task-notes) owns the note: its format ([TASK-FORMAT.md](../skills/experimental/task-notes/TASK-FORMAT.md)) and the conventions for every update.
- [`task-work`](../skills/experimental/task-work) drives the work: it resolves a note, works the checklist one item at a time, and keeps the note current as it goes.

The point of the pair is durability.
Any fresh agent — or you, weeks later — can resume a task by reading only its note: what the work is, where it happens, what is done, what happened along the way, and what is blocked on you.

## Setup

The skills need an MCP server named `joplin` backed by Joplin's Web Clipper API.

1. Install [Joplin](https://joplinapp.org/) and enable the Web Clipper service (**Tools → Options → Web Clipper**).
   Copy the authorization token from that screen.
2. Export the token as `JOPLIN_MCP_TOKEN` in your shell environment (don't paste it into files).
3. Install the skills together with the bundled MCP config:

   ```
   /plugin marketplace add lstig/agents
   /plugin install workflow-skills@lstig-agents
   ```

   If you install the skills another way (skills.sh, vendored), wire up the `joplin` server from [.mcp.json](../.mcp.json) yourself.

The skills keep their notes in a Joplin notebook named `Agents`, creating it on first use.

## Anatomy of a task note

A task note is a Joplin **to-do** titled `[NNNN] <short imperative title>`, where `NNNN` is a sequential task number that is never reused.

```md
---
working-directory: /Users/you/Code/acme/api
working-branch: feat/rate-limiting
status: available
---

## Task

Add per-client rate limiting to the public API; done when limits are enforced and documented.

## Checklist

- [x] Add middleware with configurable limits
- [ ] Return 429 with Retry-After header
- [ ] Document limits in the API reference

## Links

- [Design discussion](https://github.com/acme/api/issues/512)

## Log

- 2026-07-06 09:14 — Created task note.
- 2026-07-06 10:02 — Picked up task; starting middleware item.
- 2026-07-06 11:40 — Finding: nginx already rate-limits at the edge; app limits must be lower.
```

The pieces that matter when you read one:

- **Frontmatter** — where the work happens (`working-directory`, `working-branch`) and its lifecycle `status`: `available` (no one has it), `working` (an agent is on it), or `blocked` (waiting on you).
- **Checklist** — the concrete, verifiable units of work.
- **Log** — an append-only record of what happened, with durable knowledge tagged `Decision:`, `Finding:`, or `Dead end:`.
- **Blocked section** — while a task is blocked, the title gains a `🛑` and a `## 🛑 Blocked` section appears with the question and, usually, checkbox options for you to tick.

The full format lives in [TASK-FORMAT.md](../skills/experimental/task-notes/TASK-FORMAT.md).

## Example session

### 1. Create a task note

Ask for one in plain language; the agent invokes `task-notes` on its own:

> Track this as a task: add per-client rate limiting to the public API.
> Work happens in ~/Code/acme/api.

The agent searches for an existing open note first, allocates the next task number, and reports back something like: created `[0017] Add per-client rate limiting`.

You can also create notes for future work you don't intend to start yet — the backlog lives in Joplin, not in your head.

### 2. Work the task

`task-work` is invoked explicitly (it never fires on its own).
Hand it a task number, a title fragment, or a description:

```
/task-work 17
```

The agent then:

1. Resolves the note and reads the whole log before touching anything.
2. Switches to the note's working directory and branch, sets `status: working`, and logs a pickup entry.
3. Works the checklist top-down, one item at a time — checking items off and logging outcomes as it goes, adding newly discovered work to the checklist instead of doing it silently.
4. Closes out: links artifacts (PRs, commits), marks the to-do complete, and summarizes what changed.

### 3. Answer a blocked task

If the agent needs your input, it blocks the note rather than guessing.
In Joplin you'll see `[0017] 🛑 …` with a section like:

```md
## 🛑 Blocked — 2026-07-06 13:05

Should limits apply per API key or per source IP?

**Response:**

- [ ] Per API key
- [ ] Per source IP
- [ ] Other: <type here>
```

Tick a box (or write on the `Other:` line) directly in Joplin.
The waiting agent polls the note, reads your response, unblocks the task, and continues.

### 4. Resume later

Nothing about a task lives in a chat session.
To pick a task back up — same machine, new machine, different agent — run `/task-work <number>` again; step 2's orientation reads the log and continues from the first unchecked item.

## Tips

- A bare number (`17`) or `[0017]` both resolve; so do title keywords.
- `/task-work` with a description of brand-new work creates the note and starts on it in one step.
- Edit the note yourself whenever you like — add checklist items, drop links, fix the task description.
  Agents re-read the note as they work; your edits are part of the record.
- The `status` field is what keeps two agents from trampling each other: a `working` note prompts a warning instead of a silent takeover.
