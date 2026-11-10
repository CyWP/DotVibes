---
description: Create a git commit and reference the YouTrack ticket(s) it belongs to, chosen from the user's active tickets (refreshed via youtrack-update) based on what the changes actually do. Combines the youtrack and commit skills. Use when the user wants a commit linked to tickets.
---

# youtrack-commit

Commit the current changes and tie the commit to the right YouTrack ticket(s).

Extra instructions from the user, if any: `$ARGUMENTS` (e.g. a ticket ID to force, "split by ticket", a message hint). Take an explicit ticket ID there as authoritative.

Load and follow two skills: **youtrack** (finding/matching tickets) and **commit** (message format, staging, identity, push question). This command only sequences them; don't restate their rules.

## Steps

1. **Refresh tickets.** Run `youtrack-update` (youtrack skill). On failure, follow that skill's failure handling: use the existing ticket files, flag them as possibly stale, and continue. If there are none, go to step 3 with no candidates.
2. **Read the active tickets.** From the output folder, read each ticket's summary, state and description (and recent comments if the summary is ambiguous).
3. **Understand the change.** `git status`, `git diff` (staged + unstaged), `git log -5 --oneline`.
4. **Match changes to tickets** per the youtrack skill's matching rules: what the diff does vs. what each ticket asks for, with the branch name / conversation / notes as tie-breakers. Outcomes:
   - Clear match(es): proceed.
   - Changes split cleanly across unrelated tickets or concerns: make **separate commits**, each with its own ticket(s), staging explicit paths (commit skill).
   - Ambiguous or no match: ask the user (one AskUserQuestion: list candidate tickets as `ID — summary`, plus "none"). Don't guess.
5. **Commit** following the commit skill: message format with the ticket prefix and `Refs:` line, no YouTrack state commands, no Claude attribution, the user's own git identity, verify afterwards.
6. **Ask about pushing** exactly as the commit skill's final push step says. Never push automatically.
7. **Report briefly:** commit hash(es), which ticket(s) each references and why (one line each), whether the ticket data was fresh or stale, and pushed / not pushed.

## Limits

- Never modify ticket state, assignee or comments.
- Never print or log `YOUTRACK_TOKEN`.
- If the working tree has nothing to commit, say so and stop.
