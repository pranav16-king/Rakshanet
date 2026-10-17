# Git Workflow & Commit Guidelines

These rules govern version control, branching strategies, commit messages, and collaboration standards.

---

## 1. Conventional Commits

All commit messages must adhere to the Conventional Commits specification:

```text
<type>(<optional scope>): <description>

[optional body]

[optional footer(s)]
```

### Commit Types:
- `feat`: A new user-facing feature or capability.
- `fix`: A bug fix.
- `docs`: Documentation updates only.
- `style`: Changes that do not affect the meaning of the code (formatting, missing semi-colons, white-space).
- `refactor`: Code change that neither fixes a bug nor adds a feature.
- `perf`: Code change that improves performance.
- `test`: Adding missing tests or correcting existing tests.
- `chore`: Build process, dependencies, tooling, or repository maintenance.

### Formatting Rules:
- Use imperative, present tense ("add feature" not "added feature" or "adds feature").
- Do not capitalize the first letter of the description.
- Do not end the description with a period.
- Keep the subject line under 72 characters.

---

## 2. Branching Strategy

- `main` / `master`: Production-ready code. Always stable and deployable.
- `feature/<feature-name>`: Dedicated branches for new features.
- `fix/<issue-name>`: Dedicated branches for bug fixes.
- `refactor/<target>`: Dedicated branches for architectural improvements.

---

## 3. Pull Requests & Code Reviews

- Keep pull requests small and focused on a single concern.
- Include a concise summary of changes, motivation, and verification steps (screenshots/recordings for UI changes).
- Ensure all automated CI checks, linters, and unit tests pass before requesting review.
