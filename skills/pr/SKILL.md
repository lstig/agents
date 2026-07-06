---
name: pr
description: Open a pull request or merge request on the repo's forge (GitHub, GitLab, Gitea, Forgejo). Use when the user wants to open/create a PR or MR, ship a branch for review, or submit changes upstream.
---

Opens a pull/merge request using the forge's native CLI, never a raw API call. Every forge speaks a different noun for the same thing (PR vs MR) — resolve the forge first, then use its verb throughout.

## Steps

1. **Check the current branch against the primary-branch list**: `main`, `master`, `dev`, `develop`, `trunk`, `staging`, `production`, and glob `release/*`, `hotfix/*`. Get it with `git branch --show-current`.
   - Not primary → this is the head branch; skip to step 3.
   - Primary → a new branch is required; go to step 2.
   Done when: you know whether a new branch is needed.

2. **Create the head branch** off the primary branch, *before* committing anything (never commit to a primary branch directly). Name it `<type>/<kebab-case-summary>`, where `<type>` is the Conventional Commits type the change belongs to (`fix`, `feat`, `docs`, `refactor`, `chore`, `test`, etc.) — e.g. `feat/add-login-page`, `fix/null-check-on-parse`. Then `git checkout -b <type>/<kebab-case-summary>`.
   Done when: `git branch --show-current` prints the new branch name.

3. **Ensure everything is committed.** Run `git status --porcelain`; if anything is unstaged or uncommitted, stage the relevant files (review — don't blindly `git add -A`), show the staged diff, and commit with a Conventional Commits message (`type(scope): subject`). If a commit already covers the change, don't make an empty one.
   Done when: `git status --porcelain` is empty.

4. **Push the branch** with upstream tracking: `git push -u origin "$(git branch --show-current)"`.
   Done when: the push succeeds and the remote reports the branch.

5. **Resolve the forge from the remote URL** (`git remote get-url origin`) by host, and use that forge's CLI for every remaining action — never `gh`/`glab`/`tea`/`fj` interchangeably:

   | Host | Forge | CLI | Create command |
   |---|---|---|---|
   | `github.com`, or host contains `github` | GitHub | `gh` | `gh pr create` |
   | `gitlab.com`, or host contains `gitlab` | GitLab | `glab` | `glab mr create` |
   | `codeberg.org`, or host contains `forgejo` | Forgejo | `fj` | `fj pr create` |
   | Host contains `gitea` | Gitea | `tea` | `tea pr create` (alias `tea pulls create`) |

   If the host matches none of these, ask the user which forge it is rather than guessing.
   Done when: exactly one CLI is selected.

6. **Open the PR/MR** with the resolved CLI, title in Conventional Commits format (matching the commit(s) — `type(scope): subject`), targeting the repo's default base branch (all four CLIs infer this; only pass `--base`/`--target-branch` if the user wants a non-default base):
   - GitHub: `gh pr create --title "<type>(<scope>): <subject>" --body "<body>"`
   - GitLab: `glab mr create --title "<type>(<scope>): <subject>" --description "<body>"`
   - Forgejo: `fj pr create "<type>(<scope>): <subject>" --body "<body>"`
   - Gitea: `tea pr create --title "<type>(<scope>): <subject>" --description "<body>"`
   Done when: the command prints the created PR/MR URL.
