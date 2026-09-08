---
name: execute
description: Drive an approved plan to committed code with a worker subagent and an adversarial judge, looping until the judge finds nothing. Use when the user wants to implement, build, or execute a plan that has been approved.
argument-hint: "plan number, or a description of the approved plan"
---

`execute` owns the loop and writes no code itself: `sdlc:worker` implements, `sdlc:judge` reviews, and neither one is you.

1. **Resolve and read the plan**, its spec, and its intent.
   The plan's status must be `approved`; anything else stops here and gets reported, never self-approved.

2. **Size the worker to the work**: how many steps, how wide their blast radius, how much is judgment rather than transcription.
   Say which model you picked and what in the plan decided it.
   The judge gets that model or a stronger one — never a weaker one, or the review is worth less than the work.

3. **Put the work where this repo says.** Absent an instruction in `CLAUDE.md` or `AGENTS.md`, create a git worktree.

4. **Dispatch `sdlc:worker`** with the plan path and the working directory.
   If the subagents are missing — a vendored or skills.sh install carries skills only — stop and say so rather than doing the work here.

5. **Dispatch a fresh `sdlc:judge`** each round, given the plan path and the diff range and nothing else.
   Never pass the worker's report; the judge's independence is the point.
   Show its findings to the human verbatim.

6. **Loop.** Findings go back to the same worker for repair, then a new judge round.
   There is no round cap; the stage ends only when a judge returns `FINDINGS: 0`.

7. **Halt** if either subagent reports the plan itself is wrong, and hand it back to the human.
   Never edit the plan, reinterpret it, or improvise around it.

8. **Commit** on a clean finish, Conventional Commits, subject naming the plan number.
   Pushing, opening a pull request, merging, and moving the plan to `implemented` all belong to the human — do none of them.
