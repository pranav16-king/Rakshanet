# Code Quality & Architecture Rules

These rules apply to all code generated, refactored, and maintained across this workspace.

---

## 1. Core Principles

- **Readability Over Cleverness**: Code should be self-documenting, clean, and intuitive. Avoid overly dense one-liners when clear multi-line code communicates intent better.
- **Single Responsibility Principle (SRP)**: Each function, component, or class must have a single, well-defined responsibility.
- **Fail Fast & Explicit Error Handling**: Validate inputs at boundary layers. Throw informative errors rather than silently swallowing exceptions or returning ambiguous nulls.
- **Strict Typing**:
  - In TypeScript/JavaScript: Always use strict typing. Avoid `any` — use `unknown` with type guards or generics instead.
  - In Python: Use PEP 484 type hints across all function signatures and data models (Pydantic / dataclasses).
  - Explicitly define interfaces and schemas for all external inputs and API responses.

---

## 2. Code Organization & Modularity

- **File & Folder Structure**:
  - Group files by feature/domain or layer (components, hooks, services, utils, types).
  - Keep file sizes manageable (typically under 300 lines). Break large files into modular sub-units.
  - Co-locate tests, styles, and types close to their implementation when appropriate.
- **Immutability & Pure Functions**:
  - Favor immutable data structures and pure functions where state changes are predictable.
  - Avoid mutating function parameters or shared global state.
- **DRY with Discretion**:
  - Eliminate repetitive business logic, but do not prematurely abstract code that just coincidentally looks similar. Slight duplication is preferable to the wrong abstraction.

---

## 3. Formatting & Style Consistency

- Use standard formatting conventions (Prettier / ESLint for JS/TS; Black / Ruff for Python).
- Meaningful Naming Conventions:
  - Variables and functions: `camelCase` (descriptive verbs for functions: `fetchUserProfile`, `calculateTax`).
  - Types, Interfaces, Classes: `PascalCase`.
  - Constants & Configuration keys: `UPPER_SNAKE_CASE`.
  - Boolean variables: Prefix with `is`, `has`, `should`, or `can` (e.g., `isLoading`, `hasPermission`).
- Preserve existing comments and docstrings. Add comments only to explain *why* non-obvious logic exists, not *what* self-explanatory code is doing.

---

## 4. Testing & Verification

- Write automated unit and integration tests for critical business logic and edge cases.
- Follow the Arrange-Act-Assert (AAA) pattern in tests.
- Test both happy paths and failure conditions (empty lists, null inputs, network timeouts, invalid schemas).
