---
description: Onboard a coworker onto a project by writing an onboarding document (docs/onboarding.md) explaining the problem, why the chosen approach makes sense, the codebase, how to run experiments, and conventions. Explicitly invokes the project-onboarding skill, which explores the repo, reconstructs the approach, and interviews the project owner to fill gaps. Use with "/onboard", or for updating an existing onboarding doc ("/onboard refresh").
argument-hint: [who is joining / focus / "refresh" to update an existing doc]
---

Onboard a coworker onto this project. Load the **project-onboarding** skill
(via the skill tool) and follow it start to finish — the skill owns the whole
flow: scoping, repo exploration, approach reconstruction, owner interview,
and writing the doc.

Notes:

- With no arguments, start from the skill's Step 0 scoping questions.
- If the arguments say "refresh" or "update", run the same skill flow against
  the existing onboarding doc: read it first, update and extend it — never
  rewrite it from scratch or clobber owner-written content.

$ARGUMENTS
