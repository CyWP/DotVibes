---
name: archive-experiment
description: Archive an experiment into a self-contained directory the user chooses, with a high-level REPORT.md of everything tried, plus every script, config, image, plot, table and log, each documented as to when and how it was produced, and enough metadata (repo, commit, diff, environment, commands) to recreate the experiment without keeping the project source. Proposes an experiment name and asks for the destination. Use when the user says "archive this experiment", "save/keep/store this experiment", "wrap up and keep everything", or "make this reproducible".
argument-hint: [experiment description or name]
---

# archive-experiment

Produce a durable, self-contained archive of an experiment. Goal: someone (likely the user in 6 months) can read `REPORT.md`, understand what was tried and found, and recreate it from the archive plus a checkout of the repo at the recorded commit.

Never delete or move originals: **copy** into the archive. Never copy secrets (see below). Do not create worktrees or branches.

## Step 1: Gather evidence (before asking anything)

Reconstruct what happened from all available sources, not just memory:

- This conversation: commands run, scripts written, parameters tried, results, dead ends, failures, assumptions.
- The repo: `git rev-parse --show-toplevel`, remote URL (`git remote -v`), current branch, `git rev-parse HEAD`, `git status --short`, `git log` since the experiment began, and `git worktree list` if relevant.
- Existing notes/reports: `<repo_root>/.claude/*.md`, `AGENTS.md`, `INFO.md`, any `*_REPORT.md`.
- Artifacts: untracked and recently modified files (`git ls-files --others --exclude-standard`, `find -newer`), output dirs (e.g. `outputs/`, `results/`, `runs/`, `plots/`, `wandb/`, `logs/`), temp dirs and the scratchpad used during the session.
- Shell history is not available; rely on the conversation for exact commands.

If the experiment spans several repos or directories, cover all of them.

## Step 2: Ask the user (one AskUserQuestion call)

Ask both together:

1. **Experiment name**: propose 2-3 short snake_case names derived from the work (first is recommended).
2. **Destination directory**: propose sensible options (e.g. `~/experiments`, `<repo_root>/../experiments`, a path you saw the user use) and allow custom. The archive goes in `<destination>/<experiment_name>/`. If it exists and is non-empty, ask whether to merge into it or pick another name; never overwrite silently.

Do not ask anything else. Resolve other ambiguity yourself and log it under **Assumptions** in the report.

## Step 3: Build the archive

Layout:

```
<destination>/<experiment_name>/
  REPORT.md            # high-level narrative + index of everything below
  repro/
    REPRODUCE.md       # exact step-by-step recreation instructions
    environment/       # lockfiles, requirements, pip freeze / conda env export, tool versions, GPU/OS info
    patch.diff         # uncommitted tracked changes vs the recorded commit (git diff HEAD --binary)
    commits.patch      # commits made during the experiment, if any (git format-patch)
    untracked/         # new source files not in git, if they matter to the experiment
  configs/             # every config used, in the form actually used (resolved/overrides included)
  scripts/             # every script written or used (experiment scripts, launchers, analysis, plotting)
  results/
    figures/           # images, plots
    tables/            # csv, tsv, markdown, json tables, metrics
    logs/              # relevant run logs (trimmed if huge, say so)
    other/             # checkpoints/data only if small; otherwise referenced, see below
```

Rules for what to include:

- **Always keep**: scripts, configs (including resolved/effective ones and CLI overrides), figures, plots, tables, metric files, relevant logs, lockfiles/environment specs, patch of uncommitted changes.
- **Do not keep project source code** that is reproducible from the recorded commit (record remote URL + full SHA instead). Keep source only if it is uncommitted/untracked (it lives in `patch.diff`/`untracked/`) or from an unreachable commit (then keep `commits.patch`).
- **Large or unrecoverable files** (datasets, checkpoints, >50 MB): don't copy by default. Record path, size, checksum (`sha256sum`) and how it was produced or obtained in the report, and flag clearly in the report if it cannot be regenerated.
- **Secrets**: never copy `.env`, tokens, API keys, credentials. Keep a redacted example (keys with values replaced by `<redacted>`) and list the required variable names in `REPRODUCE.md`.
- Preserve original filenames where possible; if two files collide, prefix with a step number or timestamp and record the mapping in the report. Keep file mtimes (`cp -p`).
- Absolute paths inside scripts/configs: leave the files unmodified, and note in `REPRODUCE.md` which paths must be adapted.

## Step 4: Write REPORT.md

High level, readable top to bottom. Sections:

```markdown
# <experiment_name>

- **Archived:** <date>   **Experiment period:** <start> → <end, best knowledge>
- **Repo(s):** <path>, remote <url>, branch <branch>, commit <full sha>, uncommitted changes: yes/no (see repro/patch.diff)
- **Goal:** <one or two sentences>
- **Outcome:** <succeeded / partial / negative result / abandoned> — <headline result>

## Summary
<Short narrative of what was tried and what was learned.>

## Timeline of attempts
Chronological numbered list. For each attempt: what was tried and why, the exact command/script and key parameters, result (numbers), what it led to next. Include failures and dead ends, and why they were abandoned.

## Artifact index
Every file kept, grouped by type. Table columns:
| File | What it is | When created | How created (script + command + params) | Referenced in attempt # |
Cover all scripts, configs, figures, tables, logs. Embed the key figures inline with relative links (`![](results/figures/x.png)`).

## Results
Key findings, comparisons, best configuration, numbers with tables.

## Assumptions and gaps
Everything inferred rather than verified (e.g. exact timestamps, commands reconstructed from conversation), anything NOT preserved (large files, secrets) and how to regenerate it, anything that may not reproduce (nondeterminism, external services, data versions).

## Next ideas
Open questions and what to try next.
```

"When" = a timestamp or date from file mtime/log/conversation (say which); "how" = the script and command that produced it. If unknown, write "unknown" rather than guessing.

## Step 5: Write repro/REPRODUCE.md

Concrete, ordered steps: clone URL, `git checkout <sha>`, apply `patch.diff` / `commits.patch`, create environment from `repro/environment/`, required env var names and external data/services with versions, where to place configs/scripts, then the exact commands in order with the expected outputs/time/hardware. Note known pitfalls hit during the experiment.

## Step 6: Verify and finish

- Check every file mentioned in REPORT.md exists in the archive and every archived file is mentioned in the index (`find` vs. report). Fix mismatches.
- Dry-check `patch.diff` applies: `git apply --check` against a clean checkout state if feasible without touching the user's tree (e.g. `git stash`-free: use `git apply --check -R` in the original tree when the patch is currently applied).
- Scan the archive for secrets (`grep -rEi 'api[_-]?key|secret|token|password|BEGIN .*PRIVATE'`) and remove or redact hits.
- Final chat message, 3-6 lines: archive path, outcome, number of scripts/figures/tables kept, what was deliberately not copied (and why), and any gaps that block reproduction.

If the archive directory is inside a git repo, don't commit it unless asked.
