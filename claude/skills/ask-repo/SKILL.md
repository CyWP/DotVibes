---
name: ask-repo
description: Answer a specific question about something in the current repo, and record the Q&A as a themed block in INFO.md at the repo root (and agent-useful facts in AGENTS.md, with permission). Use when the user asks how/why/where something works in the repo, or follows up on an earlier answer.
---

# ask-repo

Goal: answer a specific question about the repo, then record it in `INFO.md` so the knowledge persists.

## Steps
1. **Investigate** just enough code/config to answer accurately. Cite `file:line`. Mark anything not verified as *(inferred)*.
2. **Answer in chat** as plain text: direct, concise, no padding.
3. **Record in `INFO.md`** (repo root; create with `# INFO: <repo>` if missing; never touch the `## SUMMARY` section, which belongs to map-repo; theme blocks go after SUMMARY, or directly under the header if there is no SUMMARY yet).
4. **AGENTS.md:** if the answer holds facts that help a future agent act (commands, contracts, shapes, conventions, gotchas, do-not-touch areas), ask "Want me to add this to AGENTS.md?" unless the prompt already said yes or no. If yes, append terse bullets under a `## <topic>` section (reuse a matching one; create if absent). Never overwrite or reorder other content; update a related bullet rather than duplicating or contradicting it. Skip purely explanatory facts.
5. **Tell the user** which block (and AGENTS bullet) was written/updated, in one line.

## Block format
Each theme is one `##` block:
```markdown
## THEME: <short topic title>
**Q:** <question, condensed>
**A:** <answer, a few lines, with `file:line` refs>

**Follow-up Q:** <question>
**A:** <answer>
```
A theme may also contain `**Claim:**`/`**Verdict:**` entries written by verify-repo; treat them as part of the theme.
Keep entries short: record the durable answer, not the conversation. Don't duplicate README content; link to it.

## Follow-up vs. new theme
- Same topic as an existing theme: fold into that block. Merge/refine rather than just stacking, and fix earlier entries that new findings show to be wrong.
- Clearly different topic: start a new `## THEME:` block.
- **Unsure: ask the user** whether it is a follow-up or a new section. Do not guess.
- If an existing block already covers the question, reuse and update it instead of adding a duplicate.
