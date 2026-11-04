---
name: solo-experiment
description: Run a long, unattended, low-stakes experiment in the current checkout (a worktree the user already set up) while the user is away. Never asks the user questions; makes and documents assumptions; writes an <experiment_name>_REPORT.md and copies only that report to .claude/ in the main repo. Use when the user describes an experiment to run autonomously ("while I'm away", "solo experiment", "run this overnight", "try this out on your own").
---

# Solo experiment

The user will give you an experiment description along with this skill. Run it start to finish **without the user present**.

## Hard rules

1. **Never ask the user anything.** Do not use AskUserQuestion, do not end a turn with a question, do not wait for confirmation. If something is ambiguous, pick the most reasonable interpretation and keep going.
2. **Every assumption MUST be recorded** in the report (see below). This is non-negotiable: any time you resolve ambiguity, choose a default, pick a parameter, skip something, or interpret the instructions, log it as you go, not at the end.
3. **Never create worktrees or branches yourself.** The user manages worktrees (in herdr) and has started you inside the one meant for this experiment. Work in the current directory. Do not `git worktree add`, switch branches, or touch stash. Commit checkpoints on the current branch.
4. **Only the report goes to the main repo.** On completion, copy only `<experiment_name>_REPORT.md` into `<main_repo_root>/.claude/` (create the folder if missing). Do not copy, merge, cherry-pick, or push anything else.
5. **No outward-facing or irreversible actions**: no pushing, no opening PRs, no sending messages, no deleting anything outside the repo, no touching shared/production resources, no spending money beyond the normal cost of local compute and this session. If the experiment seems to require one, skip that step and log it as a blocker/assumption.

## Procedure

1. **Name the experiment.** Derive a short snake_case `<experiment_name>` from the prompt (e.g. `faster_tokenizer`). Use it for the report name.
2. **Orient.** Work from the current directory (`git rev-parse --show-toplevel` is `<workdir>`). Record the current branch and commit sha, and any uncommitted changes already present, as an assumption. If `<workdir>` is the main worktree rather than a linked one, proceed anyway and note it.
3. **Start the report immediately** at `<workdir>/.claude/<experiment_name>_REPORT.md` (ensure `.claude/` is gitignored) and keep appending to it as you work (so it exists even if you get cut off). Use the template below.
4. **Run the experiment.** Make assumptions where needed, log each one. Commit on the current branch at sensible checkpoints so changes are traceable. Run relevant tests/benchmarks; record both what passed and what failed, plus what you did not run.
5. **Know when to quit.** These are low-stakes experiments. If you are looping without progress (e.g. same failure after ~3 distinct fix attempts, an approach that is clearly infeasible, or cost is growing with no signal), stop. Abandoning is acceptable. You MUST document exactly where you got stuck: what you tried, the error/evidence, and what you'd try next.
6. **Finish.** Finalize the report. If `<workdir>` is a linked worktree, copy it to the main worktree:
   ```bash
   MAIN=$(git worktree list --porcelain | awk '/^worktree /{print $2; exit}')
   mkdir -p "$MAIN/.claude"
   git -C "$MAIN" check-ignore -q .claude || echo ".claude/" >> "$MAIN/.gitignore"   # .claude/ must always be gitignored
   cp "<workdir>/.claude/<experiment_name>_REPORT.md" "$MAIN/.claude/"
   ```
   If `<workdir>` is the main worktree, the report is already in place. Leave all work in place for the user to inspect.
7. **Final message** to the user: 3-6 lines — outcome (succeeded / partial / abandoned), headline result, key assumptions, working directory/branch, report path.

## Report template (`<experiment_name>_REPORT.md`)

```markdown
# <experiment_name> — Experiment Report

- **Status:** completed | partial | abandoned
- **Date/time:** <start> → <end>
- **Start state:** <path> @ <commit sha>, uncommitted changes: <none | summary>
- **Worktree / branch:** <workdir> / <current branch>
- **Original prompt:** <verbatim or faithful quote of the user's experiment description>

## Summary
<What was tried and the outcome in a few sentences.>

## Assumptions  (REQUIRED)
Numbered list. For each: the ambiguity, what you assumed, and why.
1. ...

## Changes made
Files added/modified/removed, with a one-line purpose each, and commit shas.

## Tests & measurements
- Commands run, with results (pass/fail, numbers).
- Tests/checks that failed and why.
- Tests/checks NOT run, and why.

## Findings
<Results, observations, comparisons, what worked / didn't.>

## Where it got stuck  (include if partial or abandoned)
<What was attempted, evidence/errors, why you stopped, suggested next steps.>

## Next steps / how to review
<How the user can inspect, e.g. `git log <start sha>..HEAD`, `git diff <start sha>..HEAD`, and how to revert: `git reset --hard <start sha>`.>
```

## Style

Be concise and factual in the report. Report failures honestly; do not claim something worked unless you verified it.
