---
name: pithy-docs
description: Write or revise pithy Google-style Python docstrings and comments that complement type annotations (jaxtyping shapes/dtypes, runtime checkers like beartype/typeguard) instead of repeating them, while explaining the reasoning behind non-obvious algorithms and heuristics. Use when asked to document, add docstrings, or clean up/shorten docs in Python code, especially array/tensor code.
---

# pithy-docs

Goal: docstrings that say only what the annotations cannot, and fully explain *why* wherever an algorithm or heuristic is non-obvious.

**Principle:** annotations are checked, prose rots. Anything the type system states (types, shapes, dtypes, optionality, defaults) is stated there only. Prose carries what types can't: meaning, units, frames, invariants, and rationale.

## Rules

1. **Google style.** Summary line (imperative, one line, ends with a period), then optional detail, then `Args:`, `Returns:`, `Raises:`, `Yields:`, `Notes:` as needed. Skip any section that adds nothing; a trivial function gets a one-line docstring.
2. **No types in prose.** Write `x: Meaning.`, never `x (Tensor): ...` or `x: (N, 3) float array`. The annotation is the source of truth and is runtime-checked; a duplicated copy can only drift.
3. **No shapes or dtypes in prose** when a jaxtyping annotation exists. Instead:
   - Name the *meaning* of each dimension symbol once, at its first use in the function, if it isn't obvious from the name: `N: number of query points.` Put these in a short line in the body or under `Args:` of the relevant parameter. Don't re-explain symbols already defined in the module docstring or an adjacent function.
   - Mention shape only for what annotations can't express: that two symbols are related (`K <= N`), a dimension is data-dependent, or a ragged/padded convention (what the padding value is, how to mask).
   - If the signature has no jaxtyping annotation but is array-like, suggest adding one rather than documenting the shape in prose.
4. **Document what types can't say:** units, coordinate frames/axis order and handedness, value ranges and normalization (`in [0, 1]`, unit-norm rows, sorted ascending), invariants, mutation/aliasing, determinism/seeding, and side effects.
5. **`Returns:`** describes meaning, not type. For tuples, one line per element in order: `Returns:\n    Per-point distances to the nearest centroid.\n    Index of that centroid.` Omit when the summary line already says it.
6. **`Raises:`** only for exceptions the function itself raises deliberately. Don't list shape/type errors the runtime checker raises.
7. **Don't narrate code.** No comment that restates the next line. No "This function...". No parameter-by-parameter paraphrase of names (`n: the n`). Cut `Args:` entries that add nothing beyond the name plus annotation, but keep the section if any entry does.
8. **Private and obvious helpers:** one-liner or none. Public API and anything surprising gets full treatment.
9. **Match the repo.** If existing docstrings use a different convention (e.g. imperative vs. descriptive, a particular dimension-naming scheme), follow it. Don't mass-reformat untouched code.

## Explaining algorithms and heuristics (do not skimp here)

Terseness applies to *describing the interface*. For *implementation reasoning*, be as long as needed. Add a `Notes:` section in the docstring (public/high-level logic) or a comment block above the relevant lines (local tricks). For each non-obvious algorithm, heuristic, magic constant, or numerical trick, cover:

- **What and why:** the approach, and why it was chosen over the obvious alternative.
- **Source:** paper/URL/name of the technique if it exists (`Welford's online variance`, `Umeyama alignment`).
- **Complexity / cost** if it drove the choice (`O(N log N) via KD-tree instead of O(N^2) pairwise`).
- **Assumptions and failure modes:** when it breaks (degenerate input, ill-conditioning, ties, outliers) and what the code does then.
- **Constants:** where a threshold/epsilon/iteration cap came from (derived, tuned on what, or arbitrary) and what happens if it's changed.
- **Numerical choices:** why `logsumexp`, why subtract the max, why `eps` is added where it is, why float64 for an accumulation.
- **Shape tricks:** broadcasting/einsum/reshape that isn't obvious. Explain the *intent* (`pairwise diff via broadcasting: (N,1,D) - (1,M,D)`); here a shape in a comment is acceptable because it explains the trick, not the interface. Prefer `einsum` strings with named axes over comments.

Example (note: no types or shapes duplicated in the signature docs; reasoning is kept):

```python
def farthest_point_sample(
    points: Float[Tensor, "N 3"], k: int, seed: int = 0
) -> Int[Tensor, " k"]:
    """Select k well-spread points by greedy farthest-point sampling.

    Args:
        points: Point cloud in metres, any frame.
        k: Number of samples; must satisfy ``k <= N``.
        seed: Seeds the random first point, so results are reproducible.

    Returns:
        Indices into ``points`` in selection order. Any prefix is itself a
        good coarser sample.

    Notes:
        Greedy FPS is a 2-approximation of the optimal k-center cover, and
        unlike random or grid sampling it keeps sparse regions represented.
        We keep a running min-distance to the chosen set and update it
        in O(N) per pick (O(N k) total) rather than recomputing all
        pairwise distances (O(N^2) memory). Starting from a random point
        rather than the farthest-from-centroid one avoids systematically
        picking outliers first. Duplicate points have distance 0 and are
        never selected before distinct ones, so heavy duplication is safe.
    """
```

## What not to do

- Don't write `Args: points (Float[Tensor, "N 3"]): ...`. It duplicates the annotation, and the jaxtyping string in prose isn't checked.
- Don't remove or alter annotations, dimension names, or `@jaxtyped`/checker decorators while documenting. Docs-only changes.
- Don't add `from __future__ import annotations` to files that use jaxtyping with a runtime checker unless it's already there: it can break checking of string dimension specs.
- Don't invent rationale. If you can't determine *why* from the code, history, or comments, say so to the user and ask, or mark `# NOTE: rationale unknown` rather than fabricating a plausible story.
- Don't pad. If the explanation needs three paragraphs, write three; if the function is `return x + 1`, write one line.

## Process

1. Read the function and its annotations. Identify what the annotations already tell a reader.
2. Draft the summary line; add only the sections that carry information beyond the annotations.
3. Identify every non-obvious algorithm/heuristic/constant/numerical trick and write its reasoning (above). Verify claims against the code; check git log/blame or ask if the reason isn't evident.
4. Re-read as a stranger: delete anything the signature already says, and confirm nothing the code *needs* a reader to know is missing.
5. If a docstring checker/linter is configured (e.g. `ruff` `D`, `pydocstyle`, `darglint`), run it. A linter requiring types in `Args:` conflicts with rule 2; tell the user and prefer configuring the linter (e.g. Google convention) over duplicating types.
