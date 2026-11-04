---
name: compact-tests
description: Reduce the size of a test suite by removing redundant, overlapping, or overly specific tests while keeping code coverage within 5% of the baseline. Use when the user says tests are bloated, redundant, or too numerous, or asks to compact, prune, dedupe, consolidate, or slim down tests.
---

# Compact tests

Models tend to write many overlapping and over-specific tests during development. Goal: **the fewest tests that keep coverage within 5% of baseline** (absolute percentage points, for line coverage, plus branch coverage if the project measures it), without losing meaningful behavioral checks.

Scope: the path/package/test files the user names; otherwise the whole test suite. If the scope is ambiguous, pick the most reasonable one and state it.

## Safety

- Work on a clean state. If there are uncommitted changes in test files, note them and do not discard them. Do not create branches or worktrees yourself (the user manages worktrees); work in the current checkout and never delete tests without them being recoverable via git.
- Never change production code. Only tests (and test helpers/fixtures made unused by removals).
- Do not remove a test just because coverage doesn't change if it is the only one asserting a distinct, important behavior (error handling, edge case tied to a bug fix, regression test referencing an issue, security/validation checks). Coverage is a floor, not the only criterion.

## Procedure

1. **Detect tooling.** Identify the test runner and coverage tool (pytest + coverage.py/pytest-cov, jest/vitest `--coverage`, go test `-cover`, cargo llvm-cov/tarpaulin, etc.). If none is installed, try installing it locally in a dev environment; if impossible, say so and fall back to a manual, conservative pass (exact duplicates and trivially subsumed tests only), clearly noting that coverage was not verified.
2. **Baseline.** Run the full suite with coverage. Record: number of tests, runtime, total line coverage, branch coverage if available, and per-file coverage. Make sure the suite is green first; if tests already fail or are flaky, exclude/note them and don't count them.
3. **Per-test coverage map.** Get coverage attributable to each test so overlap can be computed:
   - Python: `coverage run --context=test` (or pytest-cov `--cov-context=test`), then `coverage json --show-contexts`.
   - Others: run each test (or file) individually with coverage, or use the tool's per-test/context feature.
   Store the map as sets of covered lines (and branches) per test in the scratchpad/temp dir, not in the repo.
4. **Find candidates** (in order of safety):
   - **Exact duplicates:** same arrangement/assertions repeated under different names.
   - **Subsumed tests:** a test whose covered lines/branches are a subset of another test's (or of the union of the remaining tests) and which asserts nothing distinct.
   - **Parametrization candidates:** several near-identical tests differing only by input/expected values; merge into one parametrized test, or drop cases that hit the same branches.
   - **Overly specific tests:** tests pinned to implementation details (exact log strings, private helper internals, call counts on mocks, exact error message text) that duplicate a behavior check elsewhere.
   - **Trivial tests:** asserting constants, getters/setters, or that a mock returns what it was configured to return.
5. **Select a minimal set.** Greedy set cover: repeatedly keep the test that adds the most uncovered lines/branches until the coverage target (baseline minus the 5-point allowance, but aim to stay as close to baseline as is cheap) is reached. Then apply the safety judgment above to restore any removed tests that guard distinct behavior. Prefer keeping tests that are clearer, faster, and more behavior-oriented over equivalent ones.
6. **Apply in small batches.** Remove/merge tests per file or per batch, re-run the suite with coverage after each batch, and revert the batch if coverage would drop below the allowance or tests fail. Delete fixtures/helpers/imports that become unused.
7. **Verify.** Run the full suite once more: all green, coverage within 5 points of baseline (state the actual delta for lines and branches). Run a linter/formatter if the project uses one on touched files.
8. **Commit** the result on the working branch only if the user asked you to commit; otherwise leave changes uncommitted for review.

## Report

Write the report as a markdown file at `<repo_root>/.claude/compact_tests_REPORT.md` (create the `.claude/` folder at the repo root if missing and make sure `.claude/` is gitignored, adding it to `.gitignore` if not; use `git rev-parse --show-toplevel` for the root, and if the current checkout is a linked worktree, also copy it to the main worktree's root `.claude/`, found via `git worktree list | head -1`). Then give the user a short summary in chat. Contents, concise:

- Before → after: test count, runtime, line coverage, branch coverage (with deltas).
- What was removed/merged, grouped by reason (duplicate, subsumed, parametrized, over-specific, trivial), with counts, plus a short list of notable examples.
- Tests deliberately kept despite zero marginal coverage, and why.
- Any caveats (coverage tool missing, flaky tests excluded, manual-only pass).

If coverage can't be kept within 5 points while removing meaningful numbers of tests, stop at the point where it holds and report that rather than forcing reductions.
