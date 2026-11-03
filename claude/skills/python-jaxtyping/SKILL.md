---
name: python-jaxtyping
description: Norms and instructions for using jaxtyping in python for type annotation of tensors and arrays (torch, numpy, ...).
---
# Array annotations

The shape and dtypes of arrays can be annotated in the form `dtype[array, shape]`, such as  
`jaxtyping.Float[Tensor, "B C"]`.

## Dtype

The dtype should be any one of (all imported from `jaxtyping`):

- Any dtype at all: `Shaped`
    - Boolean: `Bool`
    - Any integer, unsigned integer, floating, or complex: `Num`
        - Any floating or complex: `Inexact`
            - Any floating point: `Float`
                - Of particular precision: `BFloat16`, `Float16`, `Float32`, `Float64`
            - Any complex: `Complex`
                - Of particular precision: `Complex64`, `Complex128`
        - Any integer or unsigned integer: `Integer`
            - Any unsigned integer: `UInt`
                - Of particular precision: `UInt2`, `UInt4`, `UInt8`, `UInt16`, `UInt32`, `UInt64`
            - Any signed integer: `Int`
                - Of particular precision: `Int2`, `Int4`, `Int8`, `Int16`, `Int32`, `Int64`
        - Any floating, integer, or unsigned integer: `Real`.

## Shape

**Symbols**

The shape should be a string of space-separated symbols, such as `"a b c d"`. Each symbol can be either an:

- `int`: fixed-size axis, e.g. `"28 28"`.
- `str`: variable-size axis, e.g. `"C"`.
- A symbolic expression in terms of other variable-size axes, e.g.  
    `def remove_last(x: Float[Tensor, "dim"]) -> Float[Tensor, "dim-1"]`.  
    Symbolic expressions must not use any spaces, otherwise each piece is treated as as a separate axis.

**Modifiers**

In addition some modifiers can be applied:

- Prepend `*` to an axis to indicate that it can match multiple axes, e.g. `"*B"` will match zero or more B axes.
- Prepend `#` to an axis to indicate that it can be that size *or* equal to one – i.e. broadcasting is acceptable, e.g.  
    `def add(x: Float[Tensor, "#foo"], y: Float[Tensor, "#foo"]) -> Float[Tensor, "#foo"]`.
- Prepend `_` to an axis to disable any runtime checking of that axis (so that it can be used just as documentation). This can also be used as just `_` on its own: e.g. `"b c _ _"`.
- Documentation-only names (i.e. they're ignored by jaxtyping) can be handled by prepending a name followed by `=` e.g. `Float[Tensor, "rows=4 cols=3"]`.
- Prepend `?` to an axis to indicate that its size can vary within a PyTree structure. (See [PyTree annotations](./pytree.md).)

When using multiple modifiers, their order does not matter.

As a special case:

- `...`: anonymous zero or more axes (equivalent to `*_`) e.g. `"... c h w"`

**Notes**

- To denote a scalar shape use `""`, e.g. `Float[Tensor, ""]`.
- To denote an arbitrary shape (and only check dtype) use `"..."`, e.g. `Float[Tensor, "..."]`.
- You cannot have more than one use of multiple-axes, i.e. you can only use `...` or `*name` at most once in each array.
- A symbolic expression cannot be evaluated unless all of the axes sizes it refers to have already been processed. In practice this usually means that they should only be used in annotations for the return type, and only use axes declared in the arguments.
- Symbolic expressions are evaluated in two stages: they are first evaluated as f-strings using the arguments of the function, and second are evaluated using the processed axis sizes. The f-string evaluation means that they can use local variables by enclosing them with curly braces, e.g. `{variable}`, e.g.
    ```python
    def full(size: int, fill: float) -> Float[jax.Array, "{size}"]:
        return jax.numpy.full((size,), fill)

    class SomeClass:
        some_value = 5

        def full(self, fill: float) -> Float[jax.Array, "{self.some_value}+3"]:
            return jax.numpy.full((self.some_value + 3,), fill)
    ```

# Norms and styling

- Always try to use short, single letter uppercase names for dimensions when reasonable. **GOOD**:"B C H W". **BAD**: "batch channels height width"
- Always use Tensor (form torch import Tensor) instead of torch.Tensor in type annotations.