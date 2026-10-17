# Security & Operational Safety Rules

These rules mandate security best practices for application code, secret handling, dependencies, and environment execution.

---

## 1. Secrets & Credentials Management

- **Zero Hardcoded Secrets**:
  - Never commit API keys, passwords, database credentials, JWT secrets, or private certificates into code repositories.
  - Use environment variables (`.env`, secret vaults) loaded via process environments.
  - Ensure `.env*` files with sensitive data are explicitly ignored in `.gitignore`. Provide a sanitized `.env.example` instead.

---

## 2. Input Validation & Defense in Depth

- **Never Trust Client Input**:
  - Validate and sanitize all user input on both the client (UX feedback) and server (security boundary).
  - Use schema validation libraries (e.g., Zod, Yup, Pydantic) to validate request payloads.
- **Injection Prevention**:
  - Use parameterized queries or trusted ORMs to prevent SQL Injection.
  - Escape all untrusted user content before rendering in HTML/DOM to prevent Cross-Site Scripting (XSS). Avoid `dangerouslySetInnerHTML` unless content has been sanitized with DOMPurify.
- **Authentication & Authorization**:
  - Verify authorization permissions on every protected resource and endpoint.
  - Implement CSRF protection for cookie-based stateful authentication.
  - Enforce secure HTTP headers (Content-Security-Policy, X-Frame-Options, Strict-Transport-Security).

---

## 3. Dependency Safety

- Run audit commands (`npm audit`, `pip-audit`) when adding or updating third-party libraries.
- Avoid introducing unmaintained or unnecessary dependencies when simple native standard library code suffices.
