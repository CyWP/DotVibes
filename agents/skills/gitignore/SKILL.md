---
name: gitignore
description: Make sure the repo's .gitignore covers what the DotVibes skills generate — .agents/ report folders, experiment/output dirs, env files with secrets. Use when starting experiments, writing reports, or when asked to check or fix the gitignore.
---

# gitignore

Verify the repo's `.gitignore` actually ignores the artifacts our skills
produce, and append anything genuinely missing. Never delete or un-ignore
existing entries; this is additive hygiene only.

## What must be ignored (based on the other skills' conventions)

- **`.agents/`** — session output: solo-experiment report folders
  (`.agents/<experiment_name>/`), archive-evidence copies, compact-tests
  reports. Personal scratch, never versioned.
- **Experiment & tool output dirs** that archive-experiment treats as
  evidence and experiments commonly produce: `outputs/`, `results/`,
  `runs/`, `plots/`, `logs/`, `wandb/`.
- **Env/secret files**: `.env`, `.env.*` — archive-experiment forbids copying
  secrets; the gitignore is the first line of defense before that rule even
  applies.

## Process

1. Read the repo's `.gitignore` (repo root; also honor global excludes —
   `git config core.excludesFile`).
2. For each entry above, check `git check-ignore -q <path>`; anything not
   covered is missing.
3. Append the missing ones under a `# agent artifacts (DotVibes skills)`
   comment block. Match the repo's layout in the patterns (anchored
   `/results/` vs bare `results/`) so unrelated dirs elsewhere don't get
   ignored by accident.
4. Report exactly which lines were added — add nothing else.

Run this check proactively when starting an experiment or writing a report.
