---
name: run-script
description: Runs a CLI command, bash script, or shell one-liner in the current checkout and handles failures. Small local problems (config typo, missing env var, wrong path, missing dependency, trivial syntax error) get fixed and the command is rerun; anything structural or requiring refactoring is reported without being fixed. Use whenever the user asks to "run", "execute", "try", or "check if this works" for a command, script, test suite, build, lint, migration, or npm/make/cargo/pytest-style invocation, or "and fix it if it's something simple".
argument-hint: <command or script to run>
---

# run-script

Run a command in the current directory. If it fails, either apply a small local fix and rerun, or stop and report. The user manages their own worktrees (herdr), so the current checkout is already the sandbox: **never create worktrees or branches**.

The command to run is: `$ARGUMENTS`

If `$ARGUMENTS` is empty, take the command from the user's message. If it is still ambiguous (e.g. "run it"), ask which command, once.

## Principles

- **Run exactly what was asked.** Don't "improve" the command, add flags, or swap tools.
- **Fix small, report big.** Judgment about which is which is the core of this skill (see below).
- **Never make a failure disappear by weakening the check.** No skipping tests, loosening assertions, disabling lint rules, adding `|| true`, or deleting failing code.
- **Don't commit.** Leave fixes as uncommitted changes so the user can review them with `git diff`.

## Step 1: Run the command

Run from the current directory. Capture output to a log while still seeing it:

```bash
TS=$(date +%Y%m%d-%H%M%S)
LOG="/tmp/run-script-$TS.log"
bash -c "$CMD" 2>&1 | tee "$LOG"; STATUS=${PIPESTATUS[0]}
```

Notes:
- Before the first fix, note `git status --short` so you can tell your edits from the user's pre-existing changes.
- Add a sensible timeout for commands that might hang. If the command is a long-running process (dev server, watcher), start it in the background, confirm it came up healthy, report that, and stop it. Don't treat "still running" as failure.
- Exit code 0 means success. Also treat output that clearly signals failure despite exit 0 (e.g. a test runner printing failures) as a failure, and say so.

## Step 2: On failure, classify

Read the error carefully and find the root cause before deciding. Then pick exactly one path.

### Path A: Small local fix, apply it and rerun

A fix qualifies only if **all** of these hold:

- The cause is clear and the fix is obvious (not a guess).
- It touches **at most 2 files** and roughly **10 lines total**.
- It doesn't change a public interface, function signature, data schema, or the behavior the code is meant to have.
- It doesn't require new abstractions, moving code, or touching code outside the failing area.

Typical qualifying cases:

- Typo or wrong value in a config file, wrong path, wrong filename or casing
- Missing env var that has an obvious default or example (e.g. in `.env.example`)
- Missing dependency that's already declared in the manifest/lockfile (run the install)
- Missing executable bit, wrong shebang, missing trailing newline or similar tooling quirk
- Trivial syntax error, missing import, stale/incorrect import path
- Obvious off-by-one or null-check in a one-line spot where the intent is unambiguous

After fixing, rerun the **same** command.

**Limits:** at most **3 fix attempts** total. If the same error recurs after a fix, or each fix just reveals a bigger problem, stop and switch to Path B. Don't thrash.

**Don't auto-rerun non-idempotent commands.** If the command may have partially applied side effects (deploys, publishes, database migrations, sending messages, `rm`-style cleanup, anything touching external or shared state), do not fix-and-retry. Report what happened and what state things may be in, and let the user decide.

### Path B: Structural or unclear, report only

Don't fix. Report instead if any of these apply:

- The fix needs refactoring, changes to more than ~2 files, or changes across module boundaries
- The failure comes from a genuine logic bug, design problem, or incompatible API/signature
- A test fails and it's unclear whether the test or the code is wrong
- It needs a migration, schema change, or dependency version change/upgrade
- It needs a secret, credential, permission, or access you don't have
- It needs system-level changes (global installs, `sudo`, editing files outside the project)
- You're not confident about the root cause

Briefly note what you think the fix would involve so the user can decide, but don't make it.

## Step 3: Report

Keep the report short and concrete. Include:

1. **Result**: passed, passed after N fix(es), or failed.
2. **Command** as run, and the directory it ran from.
3. **If fixes were applied**: for each, what was wrong, what you changed, and the file(s). They are uncommitted in the working tree; show the relevant `git diff`.
4. **If it failed**: the relevant error excerpt (not the whole log, just the lines that matter), your diagnosis of the root cause, and why you didn't fix it (or why you stopped retrying). Point to the full log at `$LOG`.

## Quick example

> User: `/run-script npm test -- --run auth`

1. Run `npm test -- --run auth`. Fails: `Cannot find module './config/auth.json'`.
2. The file exists as `./config/auth.config.json`; the import in one file has the wrong name. One-line fix, one file. Rerun. Passes.
3. Report: passed after 1 fix, show the diff, note it is uncommitted.

Counter-example: the same run fails because `validateToken()` returns the wrong type and 6 callers depend on it. That's structural: report the diagnosis and leave the code untouched.
