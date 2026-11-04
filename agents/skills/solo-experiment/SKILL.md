---
name: solo-experiment
description: Run a long, unattended, low-stakes experiment in a git worktree — reuse the worktree you're already in, create one (branch experiment/<name>) only if the current checkout is the main one — while the user is away. Never asks the user questions; makes and documents assumptions; writes a report in .agents/<experiment_name>/ and copies that folder into .agents/ in the main repo. Use when the user describes an experiment to run autonomously ("while I'm away", "solo experiment", "run this overnight", "try this out on your own").
---

# Solo experiment

The user will give you an experiment description along with this skill. Run it start to finish **without the user present**.

## Experiment setup (shared contract)

An experiment always runs in a linked git worktree of the target repo — never
the main checkout. The same conventions are recorded by archive-experiment;
both skills assume this contract:

1. **Detect first, create only if needed.**
   `MAIN=$(git worktree list --porcelain | awk '/^worktree /{print $2; exit}')`.
   If the current checkout is already a linked worktree (i.e. not `$MAIN`) —
   e.g. one set up in herdr — it IS the experiment workspace: use it and
   create nothing.
2. **Create only when in the main checkout**, with plain git (portable across
   harnesses), using the names both skills expect:
   ```bash
   cd "$MAIN"
   git worktree add "../$(basename "$MAIN")-<experiment_name>" -b "experiment/<experiment_name>"
   cd "../$(basename "$MAIN")-<experiment_name>"
   ```
   `<experiment_name>` is the snake_case session name. Path: sibling of the
   main checkout; branch: `experiment/<experiment_name>`. Never recreate an
   existing worktree.
3. **Record the setup** at the start of the report: worktree path, branch,
   base sha, and any pre-existing uncommitted changes. If creation isn't
   possible, stop with the reason — never fall back to running in the main
   checkout silently.
4. **Shared state every experiment carries:** `.agents/` gitignored at the
   repo root, checkpoints committed to `experiment/<experiment_name>` (never
   pushed), assumptions logged as they arise, and the report plus small
   supporting files at
   `<worktree>/.agents/<experiment_name>/` copied at the end into the main
   repo's `.agents/`.

## Hard rules

1. **Never ask the user anything.** Do not use AskUserQuestion, do not end a turn with a question, do not wait for confirmation. If something is ambiguous, pick the most reasonable interpretation and keep going.
2. **Every assumption MUST be recorded** in the report (see below). This is non-negotiable: any time you resolve ambiguity, choose a default, pick a parameter, skip something, or interpret the instructions, log it as you go, not at the end.
3. **The worktree created in setup (or the one you found yourself in) is the only worktree/branch change you make.** Work in the experiment worktree on `experiment/<experiment_name>`; commit checkpoints to that branch. No other branches, no switching mid-run, no stash, no pushes.
4. **Only the experiment folder goes to the main repo.** On completion, copy only the `.agents/<experiment_name>/` subfolder into `<main_repo_root>/.agents/` (create `.agents/` if missing; don't clobber an existing folder of the same name). Do not copy, merge, cherry-pick, or push anything else.
5. **No outward-facing or irreversible actions**: no pushing, no opening PRs, no sending messages, no deleting anything outside the repo, no touching shared/production resources, no spending money beyond the normal cost of local compute and this session. If the experiment seems to require one, skip that step and log it as a blocker/assumption.

## Procedure

1. **Name the experiment.** Derive a short snake_case `<experiment_name>` from the prompt (e.g. `faster_tokenizer`). Use it for the report name.
2. **Orient.** Follow the Experiment setup (shared contract): end up in the experiment worktree (reusing it if you landed in one), on branch `experiment/<experiment_name>`. Record the worktree path, branch, base sha and any pre-existing uncommitted changes as an assumption.
3. **Start the report immediately** at `<workdir>/.agents/<experiment_name>/REPORT.md` (ensure `.agents/` is gitignored) and keep appending to it as you work (so it exists even if you get cut off). The `.agents/<experiment_name>/` subfolder is the experiment's home: small supporting files (figures, tables, notes, tiny result files) live next to `REPORT.md` as they appear; big artifacts (checkpoints, datasets) stay out — record their paths instead. Use the template below.
4. **Run the experiment.** Make assumptions where needed, log each one. Commit checkpoints to the experiment branch (`experiment/<experiment_name>`) at sensible checkpoints so changes are traceable. Run relevant tests/benchmarks; record both what passed and what failed, plus what you did not run.
5. **Know when to quit.** These are low-stakes experiments. If you are looping without progress (e.g. same failure after ~3 distinct fix attempts, an approach that is clearly infeasible, or cost is growing with no signal), stop. Abandoning is acceptable. You MUST document exactly where you got stuck: what you tried, the error/evidence, and what you'd try next.
6. **Finish.** Finalize the report. If `<workdir>` is a linked worktree, copy it to the main worktree:
   ```bash
   MAIN=$(git worktree list --porcelain | awk '/^worktree /{print $2; exit}')
   mkdir -p "$MAIN/.agents"
   git -C "$MAIN" check-ignore -q .agents || echo ".agents/" >> "$MAIN/.gitignore"   # .agents/ must always be gitignored
   cp -r "<workdir>/.agents/<experiment_name>" "$MAIN/.agents/"
   ```
   If `<workdir>` is the main worktree, the experiment folder is already in place. Leave all work in place for the user to inspect.
7. **Final message** to the user: 3-6 lines — outcome (succeeded / partial / abandoned), headline result, key assumptions, working directory/branch, report path.

## Report template (`<experiment_name>_REPORT.md`)

```markdown
# <experiment_name> — Experiment Report

- **Status:** completed | partial | abandoned
- **Date/time:** <start> → <end>
- **Start state:** <path> @ <commit sha>, uncommitted changes: <none | summary>
- **Worktree / branch:** <workdir> / experiment/<experiment_name>
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
