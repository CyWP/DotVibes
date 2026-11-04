---
name: python-fmt
description: Norms and instructions for documentation, comments, typing in Python
---
# Python Documentation Skill — Brief, Typed, Shape-Aware

## Purpose

Produce concise, structural documentation with:

* explicit module entry points
* strict type + shape annotations
* inline shape comments
* minimal prose

Optimized for **fast reading and debugging**, not teaching.

---

## Core

* Be **brief**
* Be **explicit about types and shapes**
* Always **use type annotations**
* Show **data flow locally**
* Avoid all unnecessary explanation

---

## Module Entry Points

Every module must document its public API via `__init__.py`.

### Example

```python
# __init__.py
from .model import Model
from .train import train_step
```
Then:
```
One-liner description

Exposes:
- Model
- train_step

Internal:
- utils.py
```

**Exception**: A project's utils module should simply have an empty __init__.py, as you should always import a specific submodule from utils, which expose whatever they individually deem fit.

---

## Arrays and Tensors

- ALWAYS use the **jaxtyping** library for type annotations of JAX/PyTorch/NumPy/MLX/TensorFlow arrays and tensors.

## Class Documentation

For class-level documentation:
- Include **Brief** description
- Instead of a longer description, include Notes and Warnings when needed.
- Include functions enablibng the construction of an instance, other than __init__.
- Include attributes.
- Parameters should be specified in __init__, not class definition.

Format: 
```python
class ClassName:
    """<What this object *is*, not what it does.>

    Attributes:
        <public_attr> (Type): <Meaning, shape, or role.>
        ...

    Construction:
        from_<source>(...) -> ClassName:
            <When to use this constructor.>

    Notes:
        - <Invariant or assumption>
        - <Mutation / performance behavior>

    Warnings:
        - <Common misuse>
    """

    def __init__(self, ...):
        """
        Args:
            arg: Type, description of argument.
        """
        ...

    @classmethod
    def from_<source>(cls, ...):
        """<1-line purpose of constructor>,
        Args:
            arg: Type, description of argument.
        """
        ...
```

---

## Function Documentation

- Always use "out" as return argument
Format:
```python
def function_name(arg1: Type, arg2: Type, ...) -> ReturnType:
    """
    One-line description of what the function does.

    Args:
    - arg1: Type, description of argument.
    - arg2: Type, description of argument.
    - ...: ...

    Returns:
    - out: ReturnType, description of returned value.

    Notes:
    - Optional. Include assumptions, invariants, or important behavior.
    - Use only when necessary.
    """
```
---

## Inline Shape Comments (Mandatory)

All non-trivial ops must show shape changes.

Examples:

```python
x = linear(x) # (B, D) -> (B, D_out)
x = x.view(B, -1) # (B, D_out*H*W)
```

Broadcast:

```python
w = w[:, None] # (N,) -> (N, 1)
```

Reduction:

```python
loss = x.mean() # ()
```

Matrix:

```python
out = A @ x # (N, N) @ (N, D) -> (N, D)
```

Transformation:

```python
x = x.permute(0, 2, 1) # (B, C, N) -> (B, N, C)
x = x[:, :10] # (B, N, C) -> (B, 10, C)
```