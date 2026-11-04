---
name: python
description: Norms and defaults for Python development in this user's projects — pithy docs (types live in annotations, not prose), jaxtyping array annotations, module structure and exposure rules. Use for any Python code work.
---

# Python

Defaults for all Python work, in four areas: documentation, array annotations,
structure and module exposure, and coding practices. The documentation style
(`pithy-docs`) is the reference — anything below that conflicts with it loses.

## Documentation — pithy, annotation-first

Goal: docstrings that say only what the annotations cannot, and fully explain
*why* wherever an algorithm or heuristic is non-obvious.

**Principle:** annotations are checked, prose rots. Anything the type system
states (types, shapes, dtypes, optionality, defaults) is stated there only.
Prose carries what types can't: meaning, units, frames invariants and
rationale.

1. **Google style.** Summary line (imperative, one line, ends with a period),
   then optional detail, then `Args:`/`Returns:`/`Raises:`/`Notes:` as needed.
   Skip any section that adds nothing; a trivial function gets a one-line
   docstring. Don't narrate code; no parameter-by-parameter paraphrase.
2. **No types in prose.** Write `x: Meaning.`, never `x (Tensor): ...` or
   `x: (N, 3) float array`. The annotation is the source of truth and is
   runtime-checked; a duplicated copy can only drift.
3. **No shapes or dtypes in prose** when a jaxtyping annotation exists
   (see the next section — use it). Only mention shapes for what annotations
   can't express: related symbols (`K <= N`), data-dependent dims, ragged /
   padding conventions.
4. **Document what types can't say:** units, coordinate frames / axis order
   and handedness, ranges and normalization (`in [0, 1]`, unit-norm rows,
   sorted ascending), invariants, mutation/aliasing, determinism/seeding,
   side effects.
5. **`Returns:`** describes meaning, not type. For tuples, one line per
   element in order. Omit when the summary line already says it.
6. **`Raises:`** only for exceptions the function itself raises deliberately;
   no shape/type errors the runtime checker raises.
7. **Private and obvious helpers:** one-liner or none. Public API and anything
   surprising gets full treatment.
8. **Match the repo.** Don't mass-reformat untouched code.

### Explaining algorithms and heuristics (do not skimp here)

Terseness applies to the *interface*. For *implementation reasoning*, be as
long as needed — `Notes:` in the docstring for high-level logic, a comment
block above the lines for local tricks. For each non-obvious algorithm,
heuristic, magic constant or numerical trick, cover:

- **What and why**, and why over the obvious alternative.
- **Source** if it exists (paper/name: Welford, Umeyama, ...).
- **Complexity/cost** if it drove the choice (`O(N log N) via KD-tree` vs
  `O(N^2) pairwise`).
- **Assumptions and failure modes** (degenerate input, ill-conditioning,
  ties, outliers) and what the code does then.
- **Constants:** where a threshold/epsilon/cap came from and what changing it
  does.
- **Numerical choices:** why `logsumexp`, why subtract the max, why that eps,
  why float64 for an accumulation.
- **Shape tricks:** explain the *intent* (`pairwise diff via broadcasting:
  (N,1,D) - (1,M,D)`); a literal shape here is fine because it explains the
  trick, not the interface. Prefer named-axis `einsum` strings over comments.

Don't invent rationale: verify from code/history or mark
`# NOTE: rationale unknown` — never fabricate a plausible story.

## Array annotations — jaxtyping

The shape and dtypes of arrays are annotated as `dtype[array, shape]`, e.g.
`jaxtyping.Float[Tensor, "B C"]`. Always use jaxtyping for torch/numpy/jax/MLX
arrays and tensors.

### Dtype (any one of, imported from jaxtyping)

- `Shaped` — any dtype at all
  - `Bool`
  - `Num` — any integer, unsigned int, floating or complex
    - `Inexact` — floating or complex
      - `Float` → `BFloat16`, `Float16`, `Float32`, `Float64`
      - `Complex` → `Complex64`, `Complex128`
    - `Integer` → `Int`/`UInt` with precision variants (`Int8`...`UInt64`)
  - `Real` — floating, integer or unsigned integer

### Shape symbols

A string of space-separated symbols; each is an:

- `int` — fixed-size axis: `"28 28"`.
- `str` — variable axis: `"C"`.
- symbolic expression of other variable axes, no spaces inside:
  `Float[Tensor, "dim-1"]`.

Modifiers (order doesn't matter):

- `*axis` — matches zero or more axes: `"*B"`.
- `#axis` — that size *or* broadcastable: `"#foo"`.
- `_axis` / `_` — that axis unchecked, used just as documentation:
  `"b c _ _"`.
- `name=...` — documentation-only name: `"rows=4 cols=3"`.
- `?axis` — size may vary within a PyTree structure.
- `...` — anonymous zero-or-more axes (e.g. `"... c h w"`); scalar shape is
  `""`.

Notes: at most one multi-axis use (`...` or `*name`) per array; symbolic
expressions only over axes already declared (usually return annotations);
f-string evaluation allows local variables: `Float[jax.Array, "{size}"]`.

### Norms

- Short, single-letter uppercase dim names when reasonable. GOOD: `"B C H W"`.
  BAD: `"batch channels height width"`.
- Always `Tensor` (from torch), never `torch.Tensor`, in annotations.

## Structure and exposure

- Source code lives in a dedicated module under `src/` (never at `src/`
  root, never in the repo root).
- `utils/` — reusable, non-core functionality only: no project-specific
  logic, no heavy deps on core modules; project code imports specific
  submodules of utils. Its `__init__.py` stays empty.
- **Every module must document its public API via `__init__.py`:**
  explicit imports of what the module exposes, plus a one-liner and
  `Exposes:` / `Internal:` lists in the docstring. Internal-only files are
  not re-exported.

## Class docs (pithy applied to classes)

```python
class Mesh:
    """<What this object *is*.>

    Attributes:
        V: Vertices.
        F: Face (triangle) indices into V.

    Construction:
        from_dict(...) -> Mesh: <when to use this constructor.

    Notes:
        - <invariants, assumptions, mutation/perf behavior>

    Warnings:
        - <common misuse>
    """
```

- The type is in the annotation, not the prose: parameter lines carry
  meaning only (`V: Vertices, metres, world frame.`). Parameter *descriptions*
  go on `__init__`'s docstring, not the class scope.
- `from_<source>(...)` classmethods get a one-line purpose; they enable
  construction other than `__init__`.

## Inline shape comments

All non-trivial tensor ops must show their shape change as a comment — this is
code comment, not docstring prose, so it's required even with jaxtyping:

```python
x  = linear(x)          # (B, D) -> (B, D_out)
w  = w[:, None]         # (N,)   -> (N, 1)
out = A @ x             # (N, N) @ (N, D) -> (N, D)
x  = x.permute(0, 2, 1) # (B, C, N) -> (B, N, C)
loss = x.mean()         # ()
```

## Coding practices

### Dev environment

- miniconda3. In `environment.yaml`, prefer pip modules over conda modules.

### Naming

- Prefer single-word names; multi-word only when needed, in `snake_case`.
- Single-letter names only for canonical math notation (V/F for mesh
  vertices/faces).
- Classes: short, clear `CamelCase`, avoid prepositions ("To").

### Logging

- Use the default `logging` unless asked; the whole project shares one logger.
- When a custom logger is needed: `utils/logger.py`, handlers below the
  class, everything imports it.

### Exceptions and control flow

- Avoid try/except when possible; raise through the logger; recoverable
  errors raise as a warning.
- Avoid `else` — prefer early returns.

### Testing

- Avoid mocks; test the real implementation, don't duplicate logic into tests.

