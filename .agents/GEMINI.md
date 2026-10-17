# Workspace Agent Configuration & Rules

Welcome to the agent configuration root. This workspace enforces structured development rules, high engineering quality, and specialized design skills for Web and Mobile user interfaces.

---

## 1. Directory Structure

```text
.agent/
├── GEMINI.md                    # Primary workspace agent rules (this file)
├── AGENTS.md                    # Agent compatibility specification
├── README.md                    # Overview and onboarding documentation
├── rules/                       # Modular guidelines applied across projects
│   ├── project_agent_instructions.md # Production-only data flow & zero-mock rules
│   ├── code-quality.md          # Clean architecture, typing, error handling
│   ├── ui-ux-standards.md       # Universal UI/UX, accessibility, state handling
│   ├── git-workflow.md          # Conventional commits & PR standards
│   └── security-safety.md       # Secrets management & input defense
└── skills/                      # Specialized on-demand workflows
    ├── professional-webapp-ui/  # Merged Web UI: business apps, tokens, component patterns, HCI & a11y
    │   ├── SKILL.md
    │   └── references/
    │       ├── design-tokens.md
    │       ├── component-patterns.md
    │       └── accessibility-checklist.md
    └── professional-mobile-app/ # Merged Mobile UI: native apps, gestures, touch ergonomics & offline
        ├── SKILL.md
        └── references/
            ├── platform-guidelines.md
            ├── mobile-gestures-and-haptics.md
            └── touch-and-ergonomics.md
```

---

## 2. Rule Enforcement

All active rules in `./rules/` must be adhered to at all times:
- **Production Data Flow**: Follow [project_agent_instructions.md](./rules/project_agent_instructions.md). Zero dummy/fake data; real data flows through backend and DB.
- **Code Quality**: Follow [code-quality.md](./rules/code-quality.md). Favor clarity, modularity, strict typing, and comprehensive error handling.
- **UI/UX Standards**: Follow [ui-ux-standards.md](./rules/ui-ux-standards.md). Never hardcode magic styling numbers; adhere to the 5 core UI states and WCAG AA contrast.
- **Git Standards**: Follow [git-workflow.md](./rules/git-workflow.md). Use Conventional Commits (`feat:`, `fix:`, `refactor:`).
- **Security Protocols**: Follow [security-safety.md](./rules/security-safety.md). Zero committed secrets, rigorous input sanitization, and parameterized queries.

---

## 3. Specialized Skills

When working on UI or client development tasks, reference and activate the unified skills:
- **Professional Web App & Web UI (`skills/professional-webapp-ui/`)**: For enterprise web applications, SaaS tools, portals, dashboards, data tables, responsive layouts, CSS Grid/Flexbox, design tokens, light/dark themes, full HCI design, component patterns, and WCAG accessibility.
- **Professional Mobile App & Mobile UI (`skills/professional-mobile-app/`)**: For production-grade mobile applications (iOS, Android, React Native, Flutter), 48/44 touch targets, thumb-zone ergonomics, native navigation, offline-first sync, haptics, safe areas, virtual keyboard handling, and complete light/dark themes.
