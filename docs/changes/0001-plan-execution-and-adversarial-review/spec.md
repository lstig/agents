---
status: approved
change-id: 0001
owner: Luke Stigdon
created: 2026-09-07
---

# 0001 - Plan execution and adversarial review

## Summary
A fourth SDLC skill, `execute`, takes an approved plan and drives it to finished code.
It orchestrates two subagents with separate contexts: a **worker** that implements the plan and a **judge** that reviews the worker's output adversarially.
The judge's findings go back to the worker, and the cycle repeats until a review returns nothing.
The stage's output is committed work on a branch; a human still owns every status transition, the merge, and the decision to publish.

## Requirements

1. `execute` accepts an artifact number and resolves the matching plan, reading the plan, its spec, and its intent.
2. `execute` refuses to start unless the plan's status is `approved`, reporting the actual status.
   It never sets that status itself.
3. The worker's model is chosen to match the complexity of the work the plan describes, not fixed in advance.
   `execute` states the model it picked and what in the plan drove the choice.
4. The judge's model is at least as capable as the worker's, and `execute` refuses to run a judge weaker than the worker that produced the work.
5. The worker implements the plan's `## Steps` and runs the commands under the plan's `## Verification`.
6. The worker reports what it did against each step of the plan, and the result of each verification command, distinguishing "ran and passed" from "not run".
7. The worker treats every artifact under `docs/sdlc/` as read-only for the duration of the stage.
8. The judge reviews with a context that does not include the worker's session or its account of the work.
   It reads the plan, the repo's standing conventions, and the actual changes.
9. The judge's mandate is to find fault, applied through named lenses.
   The set covers at least:
   - **plan conformance** — steps unmet or partially met, verification commands not run or failing
   - **correctness** — defects, wrong behavior, unhandled inputs and edge cases, broken invariants, misused APIs
   - **scope** — changes the plan does not authorize, including unrequested refactors
   - **conventions** — violations of the repo's stated conventions and the user's language and tooling defaults
   - **best practices** — naming, error handling, test coverage for what changed, and dead or commented-out code left behind
   - **security and data handling** — secrets in code or output, unsafe input handling, widened permissions
10. Every lens is applied on every round and accounted for in the judge's output, including the ones that found nothing.
11. The judge returns a list of findings, possibly empty.
    Each finding names its lens, points at specific code or a specific plan step, and states what is wrong in terms someone else can check.
12. A non-empty finding list returns the work to the worker for repair, and the cycle repeats.
    There is no cap on the number of rounds.
13. The stage ends only when a judge round returns an empty list.
    It never ends with findings outstanding.
14. Each round's findings are surfaced to the human as the judge wrote them, never rewritten or summarized by the worker.
15. The human can interrupt between rounds.
    An interrupted stage leaves the work in place and reports where it stopped.
16. If either subagent concludes the plan itself is wrong — its steps cannot be carried out, or carrying them out would not satisfy the spec — the stage halts and reports to the human.
    It does not edit the plan, reinterpret it, or improvise a substitute.
17. Where the work lands follows the repo's and the user's standing instructions.
    Absent an instruction or an explicit request, the stage works in a git worktree.
18. On a clean finish the work is committed with a Conventional Commits message referencing the artifact number.
19. Publishing the work — pushing, or opening a pull request — is a separate opt-in action, not part of a clean finish.
20. `execute` never moves the plan to `implemented` and never merges.
    An empty judge round is evidence for a human's decision, not the decision.
21. `execute` and its two subagents install as part of the `sdlc` plugin, and are reachable by the same install path as the existing three skills.
22. The instructions for `execute` and for each subagent are brief.
    Each states its job, its stop conditions, and nothing else; anything a competent agent already knows is left out.
    The existing three SDLC skills, at roughly 250 words each, are the size to beat.

## Out of scope
- Enforcing the plan-approved gate with a hook.
  Requirement 2 is an instruction the skill follows, not a blocked write; see `## Policy notes`.
- A fourth artifact type or directory under `docs/sdlc/`.
  The commit is the record.
- Prescribing a branch name, or any branch layout of its own.
  Requirement 17 defers to standing instructions and falls back to a worktree.
- Merging, releasing, or any status transition.
- Running more than one plan at a time, or splitting one plan across workers.
- Any language- or project-specific build knowledge.
  The plan's `## Verification` section is the only source of commands.

## Acceptance criteria
- Running `execute` against a plan whose status is `draft` stops with a report naming that status, and changes no files.
- A completed run leaves: a commit whose message names the artifact number, an unmodified plan file still reading `approved`, and no new file under `docs/sdlc/`.
- With no standing instruction covering branches, a completed run leaves the checkout it was invoked from on its original branch with a clean status, and the commit reachable from the worktree it created.
- A judge round names every lens, including those with nothing to report.
- A run where the judge finds something shows at least two worker rounds, with the first round's findings visible in the session in the judge's own words.
- A run against a plan with a step that cannot be carried out halts with a report and leaves the plan file unedited.
- Reading the transcript of a finished run, a human can name every plan step and every verification command, and say for each whether it was done.
- The session states the worker's model and the reason for it, and the judge's model is never the weaker of the two.
- No skill or subagent file added by this change is longer than the longest existing skill in the repo.
- Installing the `sdlc` plugin from the marketplace makes `execute` available; `claude plugin validate .` passes and `claude plugin list` reports the plugin enabled.

## Policy notes

- **Committing on the user's behalf.**
  Both the repo's and the user's standing instructions say not to commit or push unless asked, and the user's global instructions say to do task work in a worktree.
  Requirement 18 has the stage commit without a separate ask.
  Resolved: invoking `execute` is the ask, requirement 19 keeps pushing and pull requests outside its scope since those are the actions that expose work to other people, and requirement 17 keeps the commit inside whatever isolation the repo or the user already mandates.
  Requirement 17 states the worktree default as a fallback rather than a rule of this spec, so a repo that wants something else states it once in its own instructions instead of arguing with the skill.

- **The third gate is not hook-enforced, and cannot be by the current mechanism.**
  `docs/sdlc.md` states that the gates are the point and that the first two are enforced by a `PreToolUse` hook rather than by asking the model nicely.
  The third gate — plan approved before implementation — cannot be enforced the same way: the existing hook decides by file path, and implementation writes go to arbitrary source paths that are indistinguishable from any other editing session.
  Accepted as a waiver: requirement 2 is instruction-level enforcement, weaker than the other two gates.
  `docs/sdlc.md` now states this outright, so the guide no longer claims enforcement the third gate does not have.
  A stronger mechanism is possible but unspecified here.

- **An agent reviewing agent work, next to the rule that an agent never approves its own work.**
  The judge does not violate that rule, because an empty finding list moves no status; requirement 20 keeps `implemented` in human hands.
  The separation in requirement 8 is what makes the judge something other than self-review, so it is a correctness property of this spec, not an implementation detail.

- **Unbounded rounds have no cost policy to check against.**
  The repo has no guidance on agent run cost or duration.
  Requirements 14 and 15 are the mitigation: the human sees each round as it happens and can stop it.
  No round cap is specified, per the accepted intent.
  Requirements 3 and 4 raise the ceiling on that cost rather than lowering it, since the judge is never the cheaper model; this is accepted as the price of the review being worth reading.

- **Twenty-two requirements, written into instructions that must stay short.**
  The repo requires `SKILL.md` to be imperative and concise, and requirement 22 tightens that to a word budget.
  This spec is not a script to be transcribed: most of what it fixes — lens coverage, model ordering, who moves a status — should be structural in how the subagents are defined, not restated as prose the agent has to re-read every round.
  A skill that satisfies this spec by listing all twenty-two requirements has failed requirement 22.
