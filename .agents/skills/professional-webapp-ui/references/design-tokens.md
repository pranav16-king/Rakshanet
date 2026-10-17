# Web UI Design Tokens Specification

Design tokens are the foundational visual variables of the UI. Use this specification as a blueprint when configuring CSS custom properties, Tailwind themes, or CSS-in-JS configurations.

---

## 1. Color Palette Tokens

```css
:root {
  /* Neutral scale */
  --color-neutral-50:  #f8fafc;
  --color-neutral-100: #f1f5f9;
  --color-neutral-200: #e2e8f0;
  --color-neutral-300: #cbd5e1;
  --color-neutral-400: #94a3b8;
  --color-neutral-500: #64748b;
  --color-neutral-600: #475569;
  --color-neutral-700: #334155;
  --color-neutral-800: #1e293b;
  --color-neutral-900: #0f172a;
  --color-neutral-950: #020617;

  /* Brand / Primary */
  --color-primary-50:  #eff6ff;
  --color-primary-500: #3b82f6;
  --color-primary-600: #2563eb;
  --color-primary-700: #1d4ed8;

  /* Semantic feedback */
  --color-success: #16a34a;
  --color-warning: #d97706;
  --color-error:   #dc2626;
  --color-info:    #0284c7;

  /* Surface / Background / Foreground */
  --color-bg-canvas:  var(--color-neutral-50);
  --color-bg-surface: #ffffff;
  --color-text-main:  var(--color-neutral-900);
  --color-text-muted: var(--color-neutral-500);
  --color-border:     var(--color-neutral-200);
}

[data-theme="dark"] {
  --color-bg-canvas:  var(--color-neutral-950);
  --color-bg-surface: var(--color-neutral-900);
  --color-text-main:  var(--color-neutral-50);
  --color-text-muted: var(--color-neutral-400);
  --color-border:     var(--color-neutral-800);
}
```

---

## 2. Typography Tokens

```css
:root {
  --font-family-sans: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
  --font-family-mono: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;

  /* Fluid typography scale (min, preferred, max) */
  --text-xs:   clamp(0.75rem, 0.7rem + 0.25vw, 0.8125rem);
  --text-sm:   clamp(0.875rem, 0.8rem + 0.35vw, 0.9375rem);
  --text-base: clamp(1rem, 0.95rem + 0.25vw, 1.125rem);
  --text-lg:   clamp(1.125rem, 1.05rem + 0.4vw, 1.25rem);
  --text-xl:   clamp(1.25rem, 1.15rem + 0.5vw, 1.5rem);
  --text-2xl:  clamp(1.5rem, 1.35rem + 0.75vw, 1.875rem);
  --text-3xl:  clamp(1.875rem, 1.6rem + 1.2vw, 2.25rem);
  --text-4xl:  clamp(2.25rem, 1.9rem + 1.8vw, 3rem);

  /* Line heights */
  --leading-tight:  1.2;
  --leading-normal: 1.5;
  --leading-loose:  1.75;
}
```

---

## 3. Spacing, Radius, and Shadow Tokens

```css
:root {
  /* Spacing Scale (8pt / 4pt grid) */
  --space-1: 0.25rem;  /* 4px */
  --space-2: 0.5rem;   /* 8px */
  --space-3: 0.75rem;  /* 12px */
  --space-4: 1rem;     /* 16px */
  --space-6: 1.5rem;   /* 24px */
  --space-8: 2rem;     /* 32px */
  --space-12: 3rem;    /* 48px */
  --space-16: 4rem;    /* 64px */

  /* Border Radii */
  --radius-sm: 0.25rem; /* 4px */
  --radius-md: 0.5rem;  /* 8px */
  --radius-lg: 0.75rem; /* 12px */
  --radius-xl: 1rem;    /* 16px */
  --radius-full: 9999px;

  /* Shadows */
  --shadow-sm: 0 1px 2px 0 rgb(0 0 0 / 0.05);
  --shadow-md: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);
  --shadow-lg: 0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1);
}
```
