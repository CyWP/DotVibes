---
name: project-onboarding
description: Onboard a coworker onto a project by writing an onboarding document that explains the problem, why the chosen approach makes sense (including alternatives considered and rejected), a codebase tour, how to run experiments, and repo conventions. Explores the repo first, drafts its best reconstruction of the approach, then interviews the project owner to fill gaps before finalizing. Use whenever the user mentions onboarding a new colleague, coworker, student or hire ("onboard X", "get X up to speed", "X is joining the project", "show X how our project works"), or asks to prepare a handover / introduction / getting-started doc for someone joining a project — even if they only say "write something so X can get started". Also use when asked to update or refresh an existing onboarding doc.
---

# Project onboarding

Produce one deliverable: an onboarding document a new ML-literate teammate can
read in 30–45 minutes and then be productive without constantly interrupting
the project owner. The hard part is not the code tour — anyone can read code.
The hard part is the *why*: what the problem actually is, and why this
approach was chosen over the alternatives. Code rarely records that, so the
skill reconstructs a best guess from the repo and then interviews the owner
to correct and complete it.

## Step 0 — Scope

Establish, without re-asking what the prompt already answered:

1. **Which project?** The current repo by default; confirm if the cwd is a
   monorepo or workspace with several projects.
2. **Who is the onboardee?** Name/role if known, and what they'll work on.
3. **Background.** Default assumption: ML-literate — they know standard
   methods, training loops, and experimental practice. Never explain what a
   gradient or a cross-validation is. Do explain project-specific choices,
   repo jargon, custom abstractions, and the experimental setup of *this*
   project. If the user says the person is junior or from another field,
   calibrate deeper.

If the owner (the user) is clearly not available or the prompt says not to
interview, skip Step 3 and finish the doc with uncertainty clearly marked —
never invent rationales and present them as fact.

## Step 1 — Explore before asking

Do a real pass over the repo before asking the owner anything. Every question
the repo can answer is one the owner doesn't have to. Look at:

- README(s), `AGENTS.md`, existing docs, wikis, design notes.
- Dependency/environment files (`pyproject.toml`, `environment.yml`,
  `requirements.txt`), Makefiles, CI configs, `justfile`s.
- Experiment configs and entry points: training/eval scripts, config files,
  notebooks, sweep definitions.
- Data: where it lives (paths, not contents), how it's produced or fetched,
  preprocessing steps.
- Git history (recent months) for what's active, what's recent work, branch
  conventions.
- Papers, references, or links cited in docs — they usually reveal the
  approach's lineage.

Build a private mental map: problem → pipeline → artifacts → people. Note
contradictions (README says X, code does Y) — these are prime interview
material.

## Step 2 — Reconstruct the approach

Write (for yourself, not yet the doc) a short reconstruction:

- **The problem.** What is actually being solved, in the owner's terms.
- **The approach.** What method/pipeline is used, and *why* it's plausible
  for this problem — the modeling intuition, data assumptions, constraints
  (compute, latency, data availability) that make it a sensible choice.
- **Alternatives.** What a reasonable person might have tried instead and
  what in the repo hints the owner considered or rejected it.

Separate three tiers of confidence honestly:

1. **Verified** — directly readable from code/config/docs.
2. **Inferred** — your reconstruction; plausible but unconfirmed.
3. **Unknown** — invisible to the repo.

Collect everything in tiers 2–3 into a question list for Step 3. In ML work
the most valuable knowledge — failed approaches, why a baseline was chosen,
which trick actually made it work, what "works" means numerically — is almost
never in the code, so err on the side of asking.

## Step 3 — Interview the owner

Ask the questions in one batched round (use the question tool if available,
otherwise a numbered list in chat). Cap it at ~10 questions, ordered by
importance, and mark which ones you can live without. Focus on:

1. Approach rationale: why this method; what was tried and abandoned, and why.
2. Status: what works today, what's in flight, what's known-broken or
   deprecated. What the current headline result is, and on which benchmark/
   split — the numbers a newcomer should know as ground truth.
3. Gotchas: non-obvious setup steps, footguns, things that look like bugs but
   aren't (and vice versa).
4. People: who owns which part, who to ask about data vs. modeling vs. infra.
5. First tasks: 2–3 concrete tasks suited to a newcomer.

If the reconstruction from Step 2 is wrong in an important way, say so plainly
("I read this as X — correct me") rather than presenting it as fact. After the
answers, it's fine to ask a short follow-up round if a central claim is still
unclear — but keep it to one round.

## Step 4 — Write the doc

**Location.** Default to `docs/onboarding.md` (create `docs/` if missing); if
an onboarding doc already exists, treat it as user work: read it, update and
extend it rather than overwriting, and tell the owner what you changed.

**Never put real credentials, tokens, API keys, IPs or usernames in the doc.**
It's a tracked file. Point to where secrets live (e.g. `~/.config/bash/.env_usr`
in this repo's convention) instead of their values.

Use this structure, trimming sections that genuinely don't apply:

```markdown
# Onboarding: <project name>
_Generated <date> from repo state <short sha> + owner interview.
Verify anything marked (owner) against current reality — this doc goes stale._

## TL;DR
One paragraph: what this project is, what the approach is, where it stands.

## The problem
What we're solving and for whom. The constraints that shape everything
(data size, latency, compute budget, scientific requirements).

## The approach — and why
The method/pipeline, and the reasoning that makes it a sensible fit.
- Alternatives considered or tried, and why they were set aside. (owner)
- What "works" means here: metrics, benchmarks, target numbers.

## Current status
Working / in flight / known-broken or deprecated. Headline current results.

## Codebase tour
Walk the directory tree in reading order (entry point → pipeline → eval),
with one-line purpose per module. Link key files by path.

## Getting set up
Environment, dependencies, data acquisition, any manual steps — as exact
commands. Say where secrets come from, never what they are. Note expected
runtimes and hardware so the newcomer can sanity-check their setup.

## Running things
Train / evaluate / analyze / plot: the commands actually used today,
including the cheap smoke-test version for verifying a setup works.

## Conventions & gotchas
Naming, config handling, experiment-tracking habits, and the traps:
things that look wrong but aren't, silent failure modes, order-sensitive
steps, results that reproduce only under X.

## Glossary
Project jargon, internal acronyms, dataset/metric nicknames.

## Who to ask
People map: data ↔ name, modeling ↔ name, infra ↔ name, …

## Suggested first tasks
2–3 concrete starter tasks with pointers to the relevant files.
```

**Style rules.**

- Audience is ML-literate: explain *this project's* choices and jargon, not
  standard ML concepts.
- Every claim a reader might act on should carry a path, command, or "owner"
  attribution so they can verify it. Mark owner-stated facts that aren't
  visible in the repo with "(owner)".
- Prefer exact commands over prose descriptions of commands.
- Keep it honest: if something is unresolved or contested, say so — an
  onboarding doc that hides open questions sets the newcomer up to trip on
  them later.

## Step 5 — Wrap up

1. Tell the owner where the doc is and summarize what came from the repo vs.
   from them, so they can spot misattributions.
2. Suggest they skim it before sharing — the owner interview is conversational,
   and the doc should get a final human pass.
3. Offer to walk the onboardee through the doc interactively later if a live
   walkthrough is wanted.
4. Remind the owner this doc will rot: when the approach or status changes
   materially, ask for it to be refreshed ("update the onboarding doc").
