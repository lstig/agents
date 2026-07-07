# Task Note Format

Every task note follows this format so that partial updates (`append`, `replace_text`) always have exact, unique text to anchor on.

## Title

```md
[NNNN] <short imperative title>
```

- `NNNN` is the task number: four digits, zero-padded, allocated sequentially, and never reused — completed tasks keep their numbers.
- While a task is blocked, a `🛑` marker follows the number: `[NNNN] 🛑 <title>`.
  Restore the plain title when the task is unblocked.

## Body template

```md
---
working-directory: /absolute/path
working-branch: branch-name
status: available
---

## Task

One or two sentences: what the work is and what "done" means.

## Checklist

- [ ] First concrete item
- [ ] Second concrete item

## Links

- [Descriptive title](https://example.com)

## Log

- 2026-07-05 14:02 — Created task note.
```

`## Log` is always the last section so plain `append` operations land entries there.

## Frontmatter

- **`working-directory`** — absolute path where the work happens. Always present.
- **`working-branch`** — the git branch for the work. Omit when the directory is not a git repository.
- **`status`** — the task lifecycle state. Always present; new notes start at `available`.

Valid `status` values:

- `available` — no worker has the task
- `working` — actively being worked
- `blocked` — waiting on the user or an external condition

## Checklist items

- Cover all work known at creation time.
- Make each item concrete and verifiable — "done" must be unambiguous.
- Word each item uniquely; exact-match `replace_text` updates depend on it.
- Sub-items are checked off individually before their parent.

## Notes section

Optional — most tasks never need it; tagged log entries are the default home for durable knowledge.
Create it only when current-state knowledge outgrows the log (typically long or multi-session tasks).
When present, it sits between `## Checklist` and `## Links`:

```md
## Notes

- Embedding calls are mocked in all tests; staging lacks pgvector.
```

- It holds what a resuming worker must know that the checklist doesn't say: decisions in force, constraints, gotchas.
- Unlike the log it is maintained, not appended: revise or delete entries the moment they stop being true.

## Links

- Web links (PRs, issues, docs) use the normal `[title](https://…)` form.
- File links point future workers at files that matter for the task: put the path, **relative to `working-directory`**, in the URL slot.

```md
- [Auth middleware](src/middleware/auth.ts)
```

- No `file://` URLs or absolute paths — they break on re-clones and machine moves; the frontmatter `working-directory` is the base.
- No line-number anchors; they rot fastest.

## Log entries

```md
- <YYYY-MM-DD HH:MM> — <what happened and the outcome>
```

- One entry per event; get the timestamp from `date '+%Y-%m-%d %H:%M'`.
- End every entry with a real line break in the `append` text — appends are verbatim, so that break is all that separates it from the next entry.
  The two characters backslash-`n` are text, not a line break: they print inline and run entries together (`…done.\n- 2026-… next`), and they glue every later append onto the same line.
- Entries recording durable knowledge start the message with a tag so they stand out when skimming: `Decision:` (a choice made and why), `Finding:` (a fact discovered about the system or its constraints), or `Dead end:` (an approach tried and abandoned, so no one retries it).

```md
- 2026-07-06 10:12 — Finding: staging DB lacks the pgvector extension; tests must mock embeddings.
```

## Blocked section

While a task is blocked, this section sits immediately **after the frontmatter and before `## Task`** — never above the frontmatter — and is removed entirely once resolved:

```md
## 🛑 Blocked — <YYYY-MM-DD HH:MM>

<the question for the user, or the outage being waited on>

**Response:**

- [ ] <option 1>
- [ ] <option 2>
- [ ] Other: <type here>
```

When the answers are enumerable, offer them as checkboxes for the user to tick — always with an `Other:` freeform line last.
Skip the checkboxes and leave only the freeform line when options don't fit the question (or it's an outage, not a question).
