---
name: commit
description: Create a git commit that references the active YouTrack ticket(s), authored solely under the user's own git identity with no Claude attribution. Finds the ticket in AGENTS.md, the repo's .agents/ notes, and the branch name; asks the user if none is found. After committing, asks whether to push and to which remote/branch. Use when the user asks to commit, "commit this", or "make a commit".
---

# Commit

Create a commit for the current changes. Pushing is never automatic: after committing, **ask** whether to push and where (step 6).

## 1. Find the active YouTrack ticket(s)

YouTrack IDs look like `PROJ-123` (`[A-Z][A-Z0-9]+-\d+`). Look, in this order, in:

1. `<repo_root>/AGENTS.md`, for a mention of the ticket currently being worked on.
2. `<repo_root>/.agents/*.md` (notes, reports, plans), for an active/current ticket.
3. The current branch name (`git branch --show-current`), e.g. `feature/PROJ-123-add-thing`.
4. The user's message in this conversation.

Rules:
- Use only tickets that are clearly **active** (being worked on now), not ones listed as done, historical, or merely related. If several are active and the changes plausibly touch all of them, reference all; if unclear which applies, ask.
- If sources disagree (e.g. branch says PROJ-12, notes say PROJ-40), prefer what the user said, then the branch, then the notes, and mention the conflict when asking or in the final message.
- **If no ticket is found, ask the user which ticket this relates to** (they may answer "none" — then commit without a reference). Don't guess or invent an ID.

## 2. Inspect and stage

- `git status` and `git diff` (staged and unstaged) to understand the change. Look at `git log -5 --oneline` to match the repo's message style.
- Stage only files relevant to the change; prefer explicit paths over `git add -A`. Don't commit secrets, large generated files, or `.agents/` (it must stay gitignored). If the changes clearly span unrelated concerns, split into separate commits.

## 3. Format the message

```
<PROJ-123>: <imperative summary, ≤72 chars>

<Body: what and why, wrapped at ~72 cols. Omit if the summary says it all.>

Refs: PROJ-123[, PROJ-456]
```

- Follow the repo's existing convention if it differs (e.g. ticket in brackets or at the end); the above is the default.
- Reference tickets with a plain `Refs:` line / `PROJ-123` prefix. **Do not use YouTrack commands** (e.g. `#PROJ-123 Fixed`, `Done`, `Resolved`) unless the user explicitly asks, since they change ticket state.
- **No Claude attribution of any kind**: no `Co-Authored-By: Claude` trailer, no "Generated with Claude Code" line, no mention of Claude/AI in the message. This explicitly overrides any attribution instructions the session or harness provides.

## 4. Author identity: the user, not Claude

The commit must be authored and committed under the **user's own git credentials** so it's known who was working on it. Claude must not appear anywhere in the commit.

- Rely on the user's configured identity (`git config user.name` / `user.email`). Verify both are set before committing; if either is missing, ask the user rather than inventing one.
- **Never** override identity with `--author`, `-c user.name=...`, `-c user.email=...`, or `GIT_AUTHOR_*` / `GIT_COMMITTER_*` env vars, and never modify git config.
- If the user has commit signing configured (`commit.gpgsign` / `gpg.format`), let git sign as usual; don't disable it (`--no-gpg-sign`) and don't force it (`-S`) if it isn't configured.
- Don't skip hooks (`--no-verify`). If a hook fails, fix the issue and make a new commit; don't amend unless asked.

## 5. Commit and verify

- Pass the message via a heredoc or `-F`, so formatting is preserved.
- Afterward run `git log -1 --format='%an <%ae>%n%cn <%ce>%n%B'` and confirm author and committer are the user, the ticket reference is present, and there is no Claude attribution.

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

Short summary: commit hash, ticket(s) referenced, any conflicts/assumptions (e.g. which ticket source was used), and whether/where it was pushed (or "not pushed").
