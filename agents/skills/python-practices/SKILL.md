---
name: python-practices
description: Privileged coding practices for software development in Python
---

## Dev environment
- Always use miniconda3 for the dev environment.
- In environment.yaml file, prefer using pip modules rather than conda modules.

## Naming
- Prefer single word names for variables and functions. Only use multiple words if necessary.
- Only use single letter variable/property names when it is a canonical property with an equivalently canonical mathematical notation (e.g. V for vertices or F for faces in a mesh object.)
- Multi-word var names must be in snake_case (e.g. word1_word2).
- Class names should be CamelCase and remain short and clear: avoid prepositions like "To"

## Logging
- Only implement a logging class if specified. Otehrwise use the default logger from logging so it can be inherited from a bigger project if inherited inside it.
- Logging should be implemented in a utils/logger.py file.
- Logging handlers are implemented in the same file, below the logger class.
- The entire project should use the same logger.

## Exception handling

- When possible, avoid using a try/catch or try/except block.
- Raise exceptions using the logger
- If recoverable, raise the exception as a warning.

## Control flow

- Avoid else statements when possible. Prefer early returns in functions.

## Testing

- Avoid mocks as much as possible.
- Test actual implementation, do not duplicat elogic into tests.

## Data Representation Classes

For classes that primarily represent structured data (e.g., graphic primitives, geometry types), enforce the following module structure and conventions.

### Module Structure

* Each representation type lives in its own module (e.g., `primitives/`).
* The module contains:

  * `__init__.py`
  * `generic.py` (optional base class)
  * One file per subclass

```
primitives/
    __init__.py
    generic.py
    sphere.py
    cube.py
    ...
```

---

### `__init__.py` Requirements

`__init__.py` must expose:

* A list of all classes:

  ```python
  CLASSES = [Sphere, Cube, ...]
  ```

* A name-to-class mapping:

  ```python
  CLASS_DICT = {cls.__name__: cls for cls in CLASSES}
  ```

* A factory function:

  ```python
  def get_<name>(type: str, **kwargs):
      return CLASS_DICT[type](**kwargs)
  ```

This enables dynamic construction and centralized access.

---

### Base Class (`generic.py`)

* Define a base class **only if shared behavior or a common interface exists**.
* Use the `abc` module to enforce required methods.
* Keep it minimal and focused on:

  * shared methods
  * abstract interface definition

```python
from abc import ABC, abstractmethod


class Primitive(ABC):
    """Abstract base class for all primitives."""

    @abstractmethod
    def to_dict(self) -> Dict[str, Any]:
        """Serializes the primitive to a dictionary."""
        pass

    @classmethod
    @abstractmethod
    def from_dict(cls, data: Dict[str, Any]):
        """Constructs a primitive from a dictionary."""
        pass
```

---

### Subclasses
* Each subclass lives in its own file
* Data representation types may have a lot of properties that require computation, but only depend on other properties or attributes. These should be implemented as `@property` instead of normal instance methods. Properties should however **NEVER** imply internal changes for the instance.
**IMPORTANT**: Subclass instance methods should **not** directly implement complex logic. Complex functions functions should be implemented as a `@staticmethod`, explicitly specifying necessary arguments. The instance method can then call the static method.
Example:
```python
  #mesh.py
  class Mesh(Primitive):
  ...
  @property
  def area(self) -> Float[Tensor, ""]:
    return Mesh.compute_area(self.V, self.F)

  @staticmethod
  def compute_area(V: Float[Tensor, "num_V"], F: Float[Tensor, "num_F"]) -> Float[Tensor, ""]:
    ... #Do computations
    return out
```

---

### Design Principles

* One class per file
* No hidden registration logic — all classes are listed explicitly
* Construction is centralized via factory functions
* `from_dict` enables serialization / deserialization symmetry
* Keep classes lightweight: data containers + minimal behavior

---

## Mathematical Function Classes

For classes representing parameterized mathematical functions (e.g., spherical harmonics), directly inherit from `torch.nn.Module`.

### Base Rule

* Always inherit directly from `nn.Module`
* Do not introduce intermediate base classes unless strictly necessary
* Follow PyTorch’s standard module interface

```python
import torch.nn as nn


class FunctionName(nn.Module):
    def __init__(self, ...):
        super().__init__()
        ...

    def forward(self, x, ...):
        """Evaluates the function."""
        ...
```

---

### Design Guidelines

* Treat the class as a **stateful function**
* Use:

  * `nn.Parameter` for learnable parameters
  * `register_buffer` for fixed state
* Keep `forward`:

  * pure
  * side-effect free
  * focused on computation

---
* Rely on `state_dict` / `load_state_dict` for serialization and deserialization

---

### Notes

* Avoid unnecessary abstraction or inheritance hierarchies
* Prefer clarity and direct use of `nn.Module`
* Separate configuration (init arguments) from learned state (`state_dict`)

---

