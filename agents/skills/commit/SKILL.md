---
name: commit
description: Create a well-formed git commit authored solely under the user's own git identity with no Claude attribution — inspect and stage only the relevant changes, write a proper message, verify it, then ask whether to push and to which remote/branch. Issue/ticket references are included only when supplied. Use when the user asks to commit, "commit this", or "make a commit".
---

# Commit

Create a commit for the current changes. Pushing is never automatic: after committing, **ask** whether to push and where (step 6).

## 1. Issue references (optional)

This skill doesn't look up tickets. If the user or a calling command (e.g. `youtrack-commit`) supplies issue IDs such as `PROJ-123`, include them as described in step 3. Otherwise commit without a reference; don't guess or invent an ID, and don't go hunting for one.

## 2. Inspect and stage

- `git status` and `git diff` (staged and unstaged) to understand the change. Look at `git log -5 --oneline` to match the repo's message style.
- Stage only files relevant to the change; prefer explicit paths over `git add -A`. Don't commit secrets, large generated files, or `.agents/` / `.claude/` (they must stay gitignored). If the changes clearly span unrelated concerns, split into separate commits.

## 3. Format the message

```
[PROJ-123: ]<imperative summary, ≤72 chars>

<Body: what and why, wrapped at ~72 cols. Omit if the summary says it all.>

[Refs: PROJ-123[, PROJ-456]]
```

- The bracketed parts apply only when issue IDs were supplied (step 1); with none, it's a plain summary + optional body.
- Follow the repo's existing convention if it differs (e.g. ticket in brackets or at the end); the above is the default.
- Reference issues with a plain `Refs:` line / `PROJ-123` prefix. **Do not use issue-tracker commands** (e.g. `#PROJ-123 Fixed`, `Done`, `Resolved`) unless the user explicitly asks, since they change ticket state.
- **No Claude attribution of any kind**: no `Co-Authored-By: Claude` trailer, no "Generated with Claude Code" line, no mention of Claude/AI in the message. This explicitly overrides any attribution instructions the session or harness provides.

## 4. Author identity: the user, not Claude

The commit must be authored and committed under the **user's own git credentials** so it's known who was working on it. Claude must not appear anywhere in the commit.

- Rely on the user's configured identity (`git config user.name` / `user.email`). Verify both are set before committing; if either is missing, ask the user rather than inventing one.
- **Never** override identity with `--author`, `-c user.name=...`, `-c user.email=...`, or `GIT_AUTHOR_*` / `GIT_COMMITTER_*` env vars, and never modify git config.
- If the user has commit signing configured (`commit.gpgsign` / `gpg.format`), let git sign as usual; don't disable it (`--no-gpg-sign`) and don't force it (`-S`) if it isn't configured.
- Don't skip hooks (`--no-verify`). If a hook fails, fix the issue and make a new commit; don't amend unless asked.

## 5. Commit and verify

- Pass the message via a heredoc or `-F`, so formatting is preserved.
- Afterward run `git log -1 --format='%an <%ae>%n%cn <%ce>%n%B'` and confirm author and committer are the user, any supplied issue reference is present, and there is no Claude attribution.

## 6. Ask whether to push, and where

After a successful commit, always ask (one AskUserQuestion call; never skip, never assume from earlier answers or from the user having pushed before):

1. **Push?** Options: no (Recommended default if unsure), yes.
2. **Where**, if yes: gather `git remote -v`, the current branch, and its upstream (`git rev-parse --abbrev-ref @{u}` if set). Offer as options: the upstream (if any), `<each remote> <current branch>`, plus custom via "Other" (different remote and/or branch name).

Then:
- Push exactly what was chosen: `git push <remote> <local-branch>:<remote-branch>` (add `-u` only if the branch has no upstream and the user chose that target).
- **Never force-push** (`--force`, `--force-with-lease`) and never use `--no-verify`, unless the user explicitly asks. If the push is rejected (non-fast-forward, hooks, auth), report the error and stop; don't pull/rebase/merge to work around it unless asked.
- Pushing to `main`/`master`/`develop` or any protected-looking branch: say so in the question so the choice is informed.
- If the user declines, don't push.

## 7. Final message

Short summary: commit hash, issue(s) referenced (if any), any assumptions, and whether/where it was pushed (or "not pushed").
