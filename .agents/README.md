# Agent Workspace Configuration

This directory (`.agent`) is the central customization hub for Antigravity and AI coding agents. It provides a standardized architecture for **Rules** (guidelines always in effect) and **Skills** (modular, specialized workflows loaded on demand).

---

## Folder Structure

```text
.agent/
├── GEMINI.md                    # Primary workspace rules & guidelines
├── AGENTS.md                    # Standard cross-agent specification
├── README.md                    # Documentation & setup guide
│
├── rules/                       # Modular rules and engineering standards
│   ├── project_agent_instructions.md # Production-only data flow & zero-mock rules
│   ├── code-quality.md          # Clean architecture, strict typing, error handling
│   ├── ui-ux-standards.md       # Universal UI/UX standards, states & accessibility
│   ├── git-workflow.md          # Conventional commit messages & branching rules
│   └── security-safety.md       # Secrets handling, input sanitization, OWASP guidelines
│
└── skills/                      # On-demand workflows with progressive disclosure
    ├── web-ui/                  # Web UI design, layout, tokens & accessibility
    │   ├── SKILL.md             # Main entry point with skill frontmatter
    │   └── references/          # Deep documentation loaded as needed
    │       ├── design-tokens.md
    │       ├── component-patterns.md
    │       └── accessibility-checklist.md
    │
    ├── mobile-ui/               # Mobile UI design, touch ergonomics & HIG/Material
    │   ├── SKILL.md             # Main entry point with skill frontmatter
    │   └── references/          # Deep documentation loaded as needed
    │       ├── platform-guidelines.md
    │       ├── mobile-gestures-and-haptics.md
    │       └── touch-and-ergonomics.md
    │
    ├── professional-webapp-ui/  # Business software, enterprise look, zero purple, full HCI
    │   └── SKILL.md             # Main entry point with skill frontmatter
    │
    └── professional-mobile-app/ # Production mobile apps, thumb ergonomics, native HCI & offline
        └── SKILL.md             # Main entry point with skill frontmatter
```

---

## Customization Concepts

### 1. Rules (`rules/`)
- Rules define **constraints, coding standards, and principles** that the agent follows during development.
- The agent discovers root rules from `GEMINI.md` / `AGENTS.md` and referenced files in `rules/`.

### 2. Skills (`skills/`)
- Skills are **procedural playbooks and knowledge packages** that teach the agent how to execute specialized workflows.
- Each skill lives in its own subdirectory (`skills/<skill_name>/`) containing a `SKILL.md` with YAML frontmatter (`name` and `description`).
- **Progressive Disclosure**: The agent sees only the skill name and description until a task requires it, keeping the context window light and efficient. Supporting documents are placed in `references/`.

---

## Adding New Customizations

### To Add a New Rule:
1. Create a markdown file in `rules/<rule-name>.md`.
2. Reference it in [GEMINI.md](./GEMINI.md) and [AGENTS.md](./AGENTS.md).

### To Add a New Skill:
1. Create a folder `skills/<skill-name>/`.
2. Create `skills/<skill-name>/SKILL.md` with valid YAML frontmatter:
   ```markdown
   ---
   name: <skill-name>
   description: Explains what the skill does and when the agent should activate it.
   ---
   ```
3. Add supporting scripts or references in `scripts/` or `references/` if necessary.
