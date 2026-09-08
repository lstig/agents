# Agents

Portable customizations for AI coding agents, distributed as skills packaged into installable plugins.

## Language

**Skill**:
A self-contained directory under `skills/` holding a `SKILL.md` (agent-facing instructions) and supporting files.
_Avoid_: plugin, command, prompt

**Plugin**:
A named, installable unit defined in the marketplace that bundles a selection of skills and any config they need (e.g. hooks). The repo ships two: `development` and `sdlc`.
_Avoid_: skill, package

**Marketplace**:
The repo's catalog of plugins (`.claude-plugin/marketplace.json`), named `lstig-agents` and addressed as `<plugin>@lstig-agents`.

**Experimental**:
The alpha maturity tier. An experimental skill lives under `skills/experimental/` and may change prompts, formats, or names without notice.
_Avoid_: beta, unstable, draft

**Stable**:
The settled maturity tier. A stable skill lives under `skills/stable/`; its prompts and name change only with a version bump on the plugins that ship it. Graduation from experimental is informal — earned through real use.
_Avoid_: released, GA, v1

**Guide**:
A human-facing document under `docs/` covering setup and example usage, possibly spanning several skills. Distinct from `SKILL.md`, which is agent-facing and loaded into model context.
_Avoid_: readme, manual

**Change**:
The unit the SDLC skills work in: one number, one slug, one directory (`<container>/NNNN-slug/`). Every artifact in it carries `change-id: NNNN`, the number the directory name already states.
_Avoid_: ticket, issue, story, feature

**Container**:
The directory holding every change directory — a directory named `changes`, wherever it sits in the tree, renamed by name with `SDLC_DIR`. Where a fresh repo puts it is stated once, in the artifact format.
_Avoid_: root, sdlc dir, artifact dir

**Artifact chain**:
The three linked markdown files inside one change directory — `intent.md`, then `spec.md`, then `plan.md`. Owned by the `intent`, `spec`, and `plan` skills.
_Avoid_: pipeline, workflow, SDLC docs

**Intent**:
The first artifact in the chain: the problem worth solving, with no mechanism in it. Cheap by design, so rejecting one costs nothing.
_Avoid_: proposal, RFC, ticket

**Spec**:
The second artifact: what the solution must do, with no file paths or code. Written only once its intent is `accepted`.
_Avoid_: design doc, requirements doc, PRD

**Plan**:
The third artifact: how the change gets built, written read-only against the real codebase. Written only once its spec is `approved`, and the baseline a reviewer later checks the diff against.
_Avoid_: strategy, approach doc

**Subagent**:
A separately-dispatched agent with its own context, defined as a markdown file with frontmatter and shipped by a plugin's `agents` key. The repo ships two: `worker` and `judge`.
_Avoid_: agent, task, helper

**Worker**:
The subagent that implements an approved plan and reports against its steps. It never judges its own output.
_Avoid_: implementer, builder, executor

**Judge**:
The subagent that reviews a worker's changes adversarially, in a context that never sees the worker's account of the work. Read-only by construction. An empty review is evidence for a human, never an approval.
_Avoid_: reviewer, critic, validator

**Lens**:
One of the fixed angles a judge reviews through — plan conformance, correctness, scope, conventions, best practices, security and data handling. Every lens is reported every round, including the ones that find nothing.
_Avoid_: category, dimension, check

**Gate**:
A `status` value in an artifact's frontmatter that only a human moves forward. An agent writes artifacts and reports them; it never accepts, approves, or rejects its own work.
_Avoid_: state, phase, approval step
