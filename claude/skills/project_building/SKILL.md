---
name: project_building
description: General programming practices and preferences for building projects and their structure.
---
# Programming practices
Use the following development practices as default behaviour, always followed unless specified otherwise.
These are general pointers. Use your other skills for more specific development informaton.

## Repository Structure

### `/src/`

* Contains all source code
* Main project code lives in a dedicated module (`my_project/`)
* Avoid placing logic directly at `/src/` root

---

### `/src/utils/`

* For reusable, non-core functionality

Rules:

* No project-specific logic
* No heavy dependencies on core modules

---

### `/test/`

* Mirrors core functionality being tested
* Flat structure is acceptable

---

### Root

Contains:

* project configuration
* documentation (`README.md`)
* CI/CD configs
* environment files

No source code should live here.

---

## Guiding Principle

> Keep core logic isolated in `/src/`,
> keep utilities generic,
> keep tests separate and explicit.

# Programming practices

## Application state

- **ALWAYS** Prefer implementing a globally accessible state class, devoid of imports from other modules from the project. This is done to limit argument passing and explicit dependencies between modules.
- A global state should usually be a singleton, accessible without explicit construction calls when imported into other modules.