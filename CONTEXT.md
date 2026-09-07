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
The alpha maturity tier. An experimental skill lives under `skills/experimental/` and may change prompts, formats, or names without notice. Graduation to `skills/` is informal — earned through real use.
_Avoid_: beta, unstable, draft

**Guide**:
A human-facing document under `docs/` covering setup and example usage, possibly spanning several skills. Distinct from `SKILL.md`, which is agent-facing and loaded into model context.
_Avoid_: readme, manual

**Artifact chain**:
The three linked markdown files describing one change — intent, then spec, then plan — sharing a number and slug under `docs/sdlc/`. Owned by the `intent`, `spec`, and `plan` skills.
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

**Gate**:
A `status` value in an artifact's frontmatter that only a human moves forward. An agent writes artifacts and reports them; it never accepts, approves, or rejects its own work.
_Avoid_: state, phase, approval step
