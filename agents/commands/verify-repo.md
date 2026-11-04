---
description: Verify a statement the user makes about how the current repo works — if wrong, correct it; if unsure, propose the simplest check; if correct, record it as a themed block in INFO.md (and AGENTS.md when agent-useful, with permission). Use when the user states how they think something in the repo works and wants it confirmed.
---

# verify-repo

Verify a statement about this repo, then persist it **only if it is true**.

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

1. **Investigate** just enough code/config to judge the statement. Cite
   `file:line`.
2. **Give a verdict in chat**, exactly one of:
   - **Correct:** say so in a line, add nuance/caveats, go to step 3.
   - **Incorrect (or partly):** state what is actually true with `file:line`
     refs and what the user's version gets wrong; or, if the statement is
     ambiguous, ask one focused follow-up question. **Stop here: write
     nothing.**
   - **Unsure:** say what reading alone cannot determine and propose the
     simplest check (one command, one grep, a tiny test). Offer to run it if
     cheap and safe. **Stop here: write nothing** until verified.
3. **Record in INFO.md** per the conventions above — recorded content must be
   verified; only minor side caveats may carry *(inferred)*. Same topic →
   fold into the existing theme; new topic → new `## THEME:` block; unsure →
   ask which.
4. **AGENTS.md** per the conventions above.

## Claim to verify

$ARGUMENTS
