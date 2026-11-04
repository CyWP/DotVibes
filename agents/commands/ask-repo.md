---
description: Answer a specific question about something in the current repo, and record the Q&A as a themed block in INFO.md at the repo root (and agent-useful facts in AGENTS.md, with permission). Use when the user asks how/why/where something works in the repo, or follows up on an earlier answer.
---

# ask-repo

Answer a specific question about this repo, then persist the answer in
INFO.md so the knowledge outlives the session.

## INFO.md conventions (shared by ask-repo / map-repo / verify-repo)

INFO.md lives at the repo root; create it with `# INFO: <repo>` when missing.
The `## SUMMARY` section is owned by map-repo — never touch it. THEME blocks
go after SUMMARY, or directly under the header when no SUMMARY exists yet.
One `##` block per theme, titled `## THEME: <short topic>`:

- ask-repo writes **Q:** / **A:** entries (plus **Follow-up Q:** / **A:**).
- verify-repo writes **Claim:** / **Verdict:** entries.
- A theme may hold both kinds: fold follow-ups into the matching theme, never
  stack duplicates, and fix earlier entries that new findings prove wrong.
- Cite `file:line`; mark anything unverified as *(inferred)*.
- Record the durable fact, not the conversation; don't duplicate README
  content — link to it.

AGENTS.md: when a fact helps a future agent act (commands, contracts, shapes,
conventions, gotchas, do-not-touch areas), ask "Want me to add this to
AGENTS.md?" unless the prompt already said yes or no; then append terse
bullets under a matching `## <topic>` section (create if absent) — never
overwrite or reorder existing content; update a related bullet rather than
duplicating.

Always end with a one-line note of which INFO block (and any AGENTS bullet)
was written or updated.

## Flow

1. **Investigate** just enough code/config to answer accurately. Cite
   `file:line`; anything not verified gets *(inferred)*.
2. **Answer in chat** as plain text: direct, concise, no padding.
3. **Record in INFO.md** per the conventions above: same topic → fold into the
   existing theme (and fix earlier entries the answer proves wrong); clearly
   new topic → new `## THEME:` block; if unsure whether it belongs to an
   existing theme, ask the user instead of guessing. If an existing block
   already covers the question, update it rather than duplicating.
4. **AGENTS.md** per the conventions above.

## Question

$ARGUMENTS
