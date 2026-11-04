---
name: merge-worktree
description: Merge a finished experiment worktree back into the main checkout. Sketch status — the merge flow is not fully specified yet; the one rule that already applies is not leaving experiments behind. Use when the user says "merge the experiment", "merge the worktree", or asks to wrap an experiment worktree back in.
---

# merge-worktree

Bring an experiment worktree (created per the Experiment setup shared
contract in solo-experiment / archive-experiment: sibling worktree on branch
`experiment/<experiment_name>`) back into the main checkout.

**Status: sketch.** The detailed merge flow (rebase vs merge, conflict policy,
report handling) is still to be specified. Until then, the binding rule is:

**Do not leave experiments behind.** A merged experiment must not linger as
an orphan: its worktree and its `experiment/<experiment_name>` branch get
cleaned up once the result is safely in the main checkout (`git worktree
remove`, `git branch -d`), and its `.agents/<experiment_name>/` report folder
is copied to the main repo's `.agents/` (solo-experiment usually already did
this — verify, don't assume). If the merge itself isn't possible, report and
leave everything in place; "not leaving experiments behind" never means
destroying unpushed work.

More steps will be added here when the merge flow is decided.
