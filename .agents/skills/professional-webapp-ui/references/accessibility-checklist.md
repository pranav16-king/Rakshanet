# Web Accessibility (WCAG 2.1 & 2.2 AA) Audit Checklist

Use this checklist during development and code review to guarantee compliance with modern accessibility standards.

---

## 1. Semantic Markup & Document Structure
- [ ] Only one `<h1>` per page representing the primary topic/title.
- [ ] Headings descend hierarchically without skipping levels (`h1` -> `h2` -> `h3`).
- [ ] Landmark regions used: `<header>`, `<nav>`, `<main>`, `<aside>`, `<footer>`.
- [ ] Interactive elements are native `<button>` or `<a>` tags with valid `href`.
- [ ] Tables use `<th>` with `scope="col"` or `scope="row"` and `<caption>`.

---

## 2. Keyboard Navigation & Focus
- [ ] All interactive elements reachable via `Tab` key.
- [ ] Logical tab order following visual reading flow (left-to-right, top-to-bottom).
- [ ] Visible focus ring on every interactive element (`:focus-visible`).
- [ ] Modal dialogs trap focus and release focus back to the opening trigger on close.
- [ ] Dropdowns, accordions, and menus operable with `Enter`, `Space`, and Arrow keys.
- [ ] "Skip to main content" link provided as the first focusable element on complex layouts.

---

## 3. Contrast & Color Independence
- [ ] Text contrast ratio is at least **4.5:1** against background for normal body text.
- [ ] Text contrast ratio is at least **3.0:1** for large text (18pt / 24px or 14pt / 18.5px bold).
- [ ] Form input borders, active icons, and UI components have at least **3.0:1** contrast.
- [ ] Information is never conveyed by color alone (always combine color with text, icons, or badges).

---

## 4. Forms & Input Validation
- [ ] Every input has an explicitly associated `<label>` using `for`/`id` or nesting.
- [ ] Required fields indicated both visually and via `aria-required="true"`.
- [ ] Error messages connected via `aria-describedby` pointing to error element ID.
- [ ] Inputs in error state marked with `aria-invalid="true"`.
- [ ] Autocomplete attributes added to standard fields (`autocomplete="email"`, `autocomplete="tel"`, `autocomplete="name"`).

---

## 5. Media & Dynamic Content
- [ ] All informational images have descriptive `alt` text.
- [ ] Decorative images have empty `alt=""` and `aria-hidden="true"`.
- [ ] Dynamic updates announced via `aria-live="polite"` or `role="status"` for non-urgent notices.
- [ ] Urgent errors announced via `aria-live="assertive"` or `role="alert"`.
- [ ] Media respects `prefers-reduced-motion` settings.
