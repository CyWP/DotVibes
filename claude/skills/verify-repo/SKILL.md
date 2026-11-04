---
name: verify-repo
description: Check the user's understanding/assumption/statement about the current repo. If wrong, correct it; if unsure, propose the simplest check; if correct, record it in INFO.md (and AGENTS.md when agent-useful, with permission). Use when the user states how they think something in the repo works and wants it confirmed.
---

# verify-repo

Goal: verify a statement the user makes about the repo, then persist it only if it is true.

## Steps
1. **Investigate** just enough code/config to judge the statement. Cite `file:line`.
2. **Give a verdict** in chat, plain and concise, as exactly one of:
   - **Correct:** say so in a line, add nuance or caveats if any, and go to step 3.
   - **Incorrect (or partly):** state what is actually true, with `file:line` refs, and what the user's version gets wrong. Or, if the statement is ambiguous, ask one focused follow-up question. **Stop here: write nothing.**
   - **Unsure:** say what cannot be determined from reading alone (including when the key point would rest on inference), and propose the simplest way to verify (e.g. a one-line print/shape assert, a single command, a tiny test, a grep). Offer to run it if cheap and safe. **Stop here: write nothing** until verified.
3. **Record in `INFO.md`** (repo root; create with `# INFO: <repo>` if missing; never touch the `## SUMMARY` section, which belongs to map-repo; theme blocks go after SUMMARY, or directly under the header if there is no SUMMARY yet). Recorded content must be verified; only minor side caveats may carry *(inferred)*.
4. **AGENTS.md:** if the fact helps a future agent act (commands, contracts, shapes, conventions, gotchas, do-not-touch areas), ask "Want me to add this to AGENTS.md?" unless the prompt already said yes or no. If yes, append terse bullets under a `## <topic>` section (reuse a matching one; create if absent). Never overwrite or reorder other content; update a related bullet rather than duplicating or contradicting it. Skip purely explanatory facts.
5. **Tell the user** in one line which INFO block and AGENTS bullet(s) were written/updated.

## Block format
Each theme is one `##` block:
```markdown
## THEME: <short topic title>
**Claim:** <the statement, condensed>
**Verdict:** <correct, plus nuance/caveats, with `file:line` refs>

**Follow-up Claim:** <statement>
**Verdict:** <...>
```
A theme may also contain `**Q:**`/`**A:**` entries written by ask-repo; treat them as part of the theme.
Keep entries short: record the durable fact, not the conversation. Don't duplicate README content; link to it.

## Same theme vs. new theme
- Same topic as an existing theme: fold into that block. Merge/refine rather than stacking, and fix earlier entries that new findings show to be wrong.
- Clearly different topic: start a new `## THEME:` block.
- **Unsure: ask the user** whether it belongs to an existing theme or a new one. Do not guess.
- If an existing block already covers the statement, reuse and update it instead of adding a duplicate.
