---
name: agent-correct
description: Record a mistake the agent made, or a user preference, as a short note in the repo's AGENTS.md so it isn't repeated. Use when the user says the agent was wrong about something, corrects its behavior, or states a preference to remember.
---

# agent-correct

Goal: turn a correction or preference from the current conversation into a durable, terse rule in `AGENTS.md`.

## Steps
1. **Extract from the conversation:** what the agent did/assumed, what is actually true or preferred, and why (if the user said).
2. **Write one rule** per lesson: actionable and specific, so a future agent can follow it without the conversation. Prefer the form "Do/Don't X; because Y".
3. **Save to `AGENTS.md`** at the repo root (create if missing):
   - Append under a `## Corrections & preferences` section (create it if absent). Never overwrite or reorder other content.
   - Check for an existing related note first; update it rather than adding a duplicate or contradiction.
4. **Tell the user** the exact line(s) added, in one line, so they can object.

## Entry format
```markdown
- **<topic>:** <rule>. _Why:_ <reason/mistake>. (<date>)
```
- Mistakes: state the correct fact and the wrong assumption it replaces.
- Preferences: state the preference and scope (e.g. "always", "in this repo's tests").

## Notes
- Keep entries to one or two lines; no narrative or blame.
- If the correction is clearly not repo-specific (a general user preference), ask whether it belongs in this repo's AGENTS.md or somewhere global.
- If it's unclear what the right behavior is, ask before recording. Don't write guesses as rules.
