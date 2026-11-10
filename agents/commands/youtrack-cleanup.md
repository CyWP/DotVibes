---
description: Walk back through recent commits in the current repo until they look clean, and tidy the messy ones — assign each to the right YouTrack ticket, rewrite vague messages so they explain what was implemented, and squash small fix-up commits into the commit they belong to. Rewrites history only after the user approves a plan, with a backup ref. Uses the youtrack and commit skills.
---

# youtrack-cleanup

Tidy up recent commit history: proper ticket references, messages that explain what was implemented, and small fix-up commits folded into the work they belong to.

Extra instructions from the user, if any: `$ARGUMENTS` (e.g. a base like `origin/main` or a commit count, "only reword, no squashing", a ticket to force). An explicit range there replaces the automatic stopping point in step 2.

Load and follow two skills: **youtrack** (finding/matching tickets, never changing ticket state) and **commit** (message format, identity rules, no Claude attribution, never `--no-verify`). This command only sequences them and adds the history-rewriting safety rules below.

## Safety rules (non-negotiable)

- **Nothing is rewritten before the user approves a concrete plan** (step 5).
- **Back up first:** create `backup/youtrack-cleanup-<timestamp>` pointing at the current HEAD before rewriting. Never delete it; tell the user it exists and how to restore (`git reset --hard <backup>`).
- **Unpushed commits only by default.** Commits that exist on any remote branch (`git branch -r --contains <sha>`) are already shared; rewriting them forces a force-push. Exclude them from the plan. Include them only if the user explicitly says so, and even then **never force-push yourself on your own initiative**; report that a force push would be needed and leave it to them. If the user then asks for the push, use `git push --force-with-lease origin <branch>` (never plain `--force`), after checking the diff against the backup is empty.
- **Stop at merge commits.** By default never rewrite across one (no `--rebase-merges`); the range ends right after the newest merge. Only if the user explicitly approves it (see "Below a merge" in step 2), rebuild the merges with `--rebase-merges`, with the extra rules there.
- **Only the current branch.** No other branches or refs are touched; no stash/reset of the user's uncommitted work: if the working tree is dirty, stop and ask the user to commit or stash first.
- **Authorship stays the user's.** Rewrite with `git rebase` and `git commit --amend -F` only: no `--author`, `--reset-author`, identity overrides, or config changes (commit skill). Squashing keeps the first commit's author, which is the user's anyway. If a commit in range has a different author, leave it out of the plan.
- **No Claude attribution** in any rewritten message. Also strip existing `Co-Authored-By: Claude ...` trailers from every commit the rewrite touches (step 6).
- Don't skip hooks. If a hook fails mid-rebase, `git rebase --abort`, report, and stop.

## Steps

1. **Refresh tickets.** Run `youtrack-update` (youtrack skill) and read the active tickets' summary, state and description. On failure (e.g. `YOUTRACK_URL` unset in this shell), `ls $YOUTRACK_OUT_DIR` (default `~/.dev/youtrack_tickets`) and use whatever ticket files are there, flagged as possibly stale; look again before asking the user for IDs (the user may have refreshed the folder in the meantime). Ask for IDs only if no ticket files exist. Note: tickets that were active when a commit was made may have since left the active states, so also accept an ID that already appears in a commit message or the branch name as a valid candidate.
2. **Find where "clean" starts.** Walk back from HEAD one commit at a time (`git log --format='%h %an %s%n%b' ...`, checking each diff with `git show --stat`). A commit is **clean** when all hold:
   - the message has a ticket reference in the commit skill's format (or the user chose "none" for it),
   - the summary is imperative, specific, ≤72 chars and says what was implemented (not "fix", "wip", "stuff", "update", "changes", "asdf") and has no typos,
   - the message has no Claude attribution trailer,
   - it isn't a small fix-up of its immediate predecessor (same files, tiny diff, message like "fix typo", "oops", "forgot", "review comments", "fixup!").
   **A WIP commit (subject starting with or containing "WIP", "wip", "WIPy", ...) is never clean and never stays**: it is squashed into the commit it leads to, or if a run of WIPs forms the base of the history, squashed into one commit with a real message describing what the run implemented. Look for them with `git log --all -i --grep=wip`; they often sit at the very bottom, below merges.
   Stop at the first run of ~3 consecutive clean commits (or at a pushed commit, a merge, the root, or the user's explicit range). Everything newer than that boundary, minus the exclusions in the safety rules, is the **cleanup range**. If the whole range is already clean, say so and stop. Don't touch commits older than the boundary.
   **Below a merge.** If the WIP/typo commits are older than a merge, rewriting them changes every later commit, so the merges must be rebuilt (`--rebase-merges`). Only do it when the user approves it explicitly, and say in the plan: all later commits get new hashes (pushed ones need a force-push by the user), and other local branches/worktrees keep the old hashes (list them with `git rev-list --count <current>..<branch>`; don't touch them). Commits by another author (e.g. a GitHub PR merge) stay as they are; the rebuilt merge keeps its author.

3. **Understand each commit in range.** For each, read the message and `git show` the diff. Work out what it actually implements.
4. **Draft the plan**, per commit, using the youtrack skill's matching rules (substance of the diff vs. ticket summary/description; branch name, existing refs and conversation as tie-breakers; never invent an ID):
   - **keep** (already fine), **reword** (new message), or **squash into** another commit (fixup, with a combined message when the squashed result changes what is implemented). Only squash adjacent or clearly belonging commits into the one they fix or extend, and only when the combined commit has one clear purpose: don't merge unrelated work to reduce the count, and don't reorder commits unless a fix-up clearly belongs to an earlier one and reordering applies cleanly.
   - the assigned ticket(s) for each resulting commit and a one-line reason.
   - the full new message for every reworded/squashed result, per the commit skill's format: summary ≤72 chars **including the `ID: ` prefix** (measure it, e.g. `awk '{print length}'`, before applying; kept commits whose subject is longer are flagged, not silently left), a body explaining *what was implemented and why* (derived from the diff, not from the old vague message), `Refs:` line. No YouTrack state commands.
   - Where a ticket is ambiguous or absent, mark it (`none`) and ask in step 5. A commit with no matching active ticket (tooling, gitignore, unrelated fixes) gets no reference; don't force one. One change serving several tickets references all of them: prefix with the main one, list all in `Refs:`.
5. **Get approval.** Show the plan compactly: a table `old sha | old subject → action → new subject | ticket`, the new messages, the backup ref name, and any pushed/merge exclusions. Put the merge-rebuild consent (if needed) and ticket choices in the same question. Resolve ambiguities and get approval in one AskUserQuestion (options: apply as shown, apply with changes via "Other", cancel). Never rewrite on a guess.
6. **Apply** (non-interactive; the shell can't open an editor):
   1. Create the backup ref.
   2. Write the new messages to files in the scratchpad/temp dir.
   3. Build a rebase todo (without merges): `pick <sha>` for kept and base commits, `fixup <sha>` for squashed-in commits placed directly under their target, and after each reworded or squashed target a line `exec git commit --amend -F <msgfile>` (no `--no-verify`, no identity flags). Run `GIT_SEQUENCE_EDITOR="cp <todo-file>" git rebase -i <boundary-commit>` (or `--root` if the range starts at the root).
      With `--rebase-merges` the todo is generated by git: use a `GIT_SEQUENCE_EDITOR` script that `sed`-edits it (`pick <wip>` → `fixup <wip>`, and `/^fixup <last>/a exec git commit --amend -F <msgfile>`) and rebase onto the commit below the range.
   4. On conflict or hook failure in a plain rebase: `git rebase --abort`, confirm HEAD equals the backup, report, stop. Don't resolve conflicts creatively.
      Exception, rebuilt merges only (user approved): a conflict while recreating a merge (`merge -C <orig>`) means the user's hand resolution is lost. Restore exactly that resolution, no new one: `git checkout <orig-merge-sha> -- $(git diff --name-only --diff-filter=U)`, check `git diff --cached <orig-merge-sha>` is empty (the tree must equal the original merge's, since the squashed base has the same tree), then `GIT_EDITOR=true git rebase --continue`. If the check is not empty, abort. Don't enable `rerere` or change config.
   5. **Strip attribution.** If any commit message in the rewritten history still has `Co-Authored-By: Claude` (`git log --format=%B | grep -ci claude`), remove the lines with `FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch -f --msg-filter '<sed deleting the line and trailing blank lines>' <boundary>..HEAD`, then `git update-ref -d refs/original/refs/heads/<branch>`. Messages only, trees unchanged.
7. **Verify.**
   - `git diff <backup> HEAD` must be **empty** (also after the attribution strip): cleanup changes history, never content. If not, restore from the backup and report.
   - `git log --format='%h %an <%ae>%n%B' <boundary>..HEAD`: author/committer are the user, references are present and match the plan, no Claude attribution (`git log --format=%B | grep -ci 'claude\|co-authored'` is 0), no `wip` in any subject, every subject ≤72 chars. `git status --short` is still clean.
8. **Report briefly:** old → new commit count, what was reworded/squashed and which tickets each commit now references, the backup ref and how to restore, and, if any rewritten commits were already pushed (only possible when the user opted in), that a force push is needed and was **not** done. **Don't push** and don't ask to; pushing rewritten history is the user's call. Mention that the ticket references only show on GitHub after a force-push (`git push --force-with-lease origin <branch>`), that other clones must reset, and that other local branches still point at the old commits.

## Limits

- Never modify ticket state, assignee or comments, and never print `YOUTRACK_TOKEN`.
- If there's nothing to clean, or the plan is cancelled, change nothing and say so.
