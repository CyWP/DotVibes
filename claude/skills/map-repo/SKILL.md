---
name: map-repo
description: Rapidly explore an unfamiliar repository and write a short SUMMARY section in INFO.md at the repo root covering components, how they interact, data/tensor shapes, and how to run it. Optionally writes agent notes to AGENTS.md. Use when asked to map, explore, orient in, or summarize how a repo works.
---

# map-repo

Goal: quickly understand how a repo works and how to use it, then write the `## SUMMARY` section of `INFO.md` in the repo root (create the file if missing; if it exists, replace only the SUMMARY section and keep the rest, i.e. any `## THEME:` blocks). SUMMARY goes directly under the `# INFO:` header, before any theme blocks.

**Scope rules**
- Orientation only. Stay at module/entrypoint level; do not go into crazy specifics.
- This is NOT a README replacement. Don't copy README prose; link to it. Aim for ~1-2 pages.
- Read selectively: file tree, manifests/config, entrypoints, then trace one main path end to end.
- Label anything not verified in code as *(inferred)*. List open unknowns rather than guessing.

## Process
1. **Survey:** list the tree (skip vendored/build dirs); read the README skim, manifests (`pyproject.toml`, `package.json`, `Makefile`, `Dockerfile`, etc.), and CI config.
2. **Find entrypoints:** CLIs, `main`, scripts, servers, notebooks, exported APIs, config-driven launchers.
3. **Trace one main path** (e.g. train, infer, serve, build) to see how components connect.
4. **Check data:** for tensors/arrays, find where they are created and consumed.
5. **Check tests/run modes** and note the commit hash + date.
6. **Write the SUMMARY section of `INFO.md`**, adapting the template below (drop sections that don't apply, add ones that do).
7. **Ask the user** whether to create/append `AGENTS.md`, unless the prompt already said yes or no.

## SUMMARY section template
```markdown
# INFO: <repo>

## SUMMARY
_Mapped at commit <hash>, <date>. Orientation only; see README for details._

### Purpose
One or two sentences.

### Layout
Short annotated tree of top-level dirs only.

### Components
| Component | Purpose | Entrypoint / interface |
|---|---|---|

### How components interact
Brief flow (list or ASCII diagram): who calls/imports/feeds whom, and config or data handoffs.

### Data
Nature of inputs/outputs (files, formats, schemas). For each tensor:
name | shape with named dims (e.g. `[B, C, H, W]`) | dtype | range/normalization | device | produced by -> consumed by
Mark non-verified shapes *(inferred)*.

### Setup
Language/version, install steps, env vars, config files, hardware (GPU etc.).

### Ways to run
Commands for each mode (train / infer / serve / test / dev), with one-line explanations.

### Testing
Where tests live, how to run them, CI.

### Extension points
Where to add a new model / dataset / command / etc.

### Gotchas & unknowns
Non-obvious conventions, hard-coded paths, dead/deprecated code, unverified items.
```

## AGENTS.md (only if the user agrees)
- Ask first: "Want me to create/append to AGENTS.md?" Skip asking only if the prompt specified.
- If the file exists, **append**; never overwrite or reorder existing content. Organize by topic: use `## <topic>` sections (e.g. `## Setup`, `## Run & test`, `## Entrypoints`, `## Data contracts`, `## Do not touch`), reusing an existing matching section instead of creating a duplicate.
- Include only agent-useful facts: exact commands (setup, run, test, lint), key entrypoints, conventions, data shape/dtype contracts, extension points, and do-not-touch areas. Brief README facts may be repeated if they help the agent act faster.
- Keep it terse: bullets and commands, no narrative.
