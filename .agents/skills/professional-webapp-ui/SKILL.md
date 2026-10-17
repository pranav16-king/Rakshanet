---
name: professional-webapp-ui
description: Build professional, production-grade web applications and modern web UI (web-ui, professional-webapp-ui) with a clean business look, complete light and dark themes, consistent sizing, full human-computer interaction (HCI) design, error handling, error prevention, accessibility and responsive layout. Use this skill whenever the user asks for a web app, web-ui, web UI design, dashboard, admin panel, SaaS UI, internal tool, CRM, form-heavy app, data table, portal, or any web interface. Also use it when the user complains about ugly colors, purple/violet gradients, poor usability, missing validation, or missing dark mode.
---

# Professional Web Application & Web UI Skill

Goal: every app built with this skill looks like serious business software (think Stripe, Linear, GitHub, Microsoft Fluent, IBM Carbon) and behaves predictably, safely and accessibly.

## Quick References
- [Design Tokens Specification](./references/design-tokens.md)
- [Component Patterns & Architecture](./references/component-patterns.md)
- [WCAG 2.1 & 2.2 AA Accessibility Checklist](./references/accessibility-checklist.md)

Follow the sections in order. Do not skip the final checklist.

---

## 0. Hard Rules (never break)

1. **No purple, violet, indigo, magenta, pink or neon colors** anywhere (UI, charts, gradients, shadows, focus rings). Blue, slate, teal, green, amber and red only.
2. **No decorative gradients**, glow effects, glassmorphism, emoji as icons, or rainbow charts. Flat, calm surfaces with subtle borders and light shadows.
3. **Both light and dark themes are mandatory**, driven by design tokens (CSS variables). Respect `prefers-color-scheme`, and offer a manual toggle (Light / Dark / System) that is remembered.
4. **Never hard-code colors, sizes or spacing in components.** Use tokens only.
5. **Every interactive element has all states**: default, hover, focus-visible, active, disabled, loading, and error where relevant.
6. **Every async action has loading, success, empty and error states.**
7. **Never rely on color alone** to convey meaning (add icon + text).
8. **Never show raw technical errors** (stack traces, "undefined", HTTP codes alone) to users.
9. **Destructive actions are never one click without protection** (confirm or undo).
10. **Text contrast minimum 4.5:1** (3:1 for large text and UI borders/icons) in both themes.

---

## 1. Color System (Design Tokens)

Use a neutral slate base, one blue primary, and semantic colors. Define on `:root`, override for dark.

```css
:root {
  color-scheme: light dark;

  /* Surfaces */
  --bg:            #F8FAFC;  /* app background */
  --surface:       #FFFFFF;  /* cards, panels, inputs */
  --surface-2:     #F1F5F9;  /* table header, hover rows, subtle fills */
  --surface-3:     #E2E8F0;  /* pressed, skeleton base */
  --border:        #E2E8F0;
  --border-strong: #CBD5E1;  /* input borders (3:1 on white needs #94A3B8 for strict WCAG, use for inputs) */
  --input-border:  #94A3B8;

  /* Text */
  --text:          #0F172A;  /* primary, 17:1 */
  --text-2:        #334155;  /* secondary, 10:1 */
  --text-muted:    #475569;  /* hints, 7.5:1 */
  --text-disabled: #94A3B8;
  --text-on-primary: #FFFFFF;

  /* Brand / primary (blue) */
  --primary:        #1D4ED8;
  --primary-hover:  #1E40AF;
  --primary-active: #1E3A8A;
  --primary-subtle: #EFF6FF;  /* selected row, info tint */
  --focus-ring:     #2563EB;

  /* Semantic */
  --success:        #15803D;  --success-subtle: #F0FDF4;  --success-border: #BBF7D0;
  --warning:        #B45309;  --warning-subtle: #FFFBEB;  --warning-border: #FDE68A;
  --danger:         #B91C1C;  --danger-subtle:  #FEF2F2;  --danger-border:  #FECACA;
  --info:           #0369A1;  --info-subtle:    #F0F9FF;  --info-border:    #BAE6FD;

  /* Elevation */
  --shadow-sm: 0 1px 2px rgb(15 23 42 / 0.06);
  --shadow-md: 0 4px 12px rgb(15 23 42 / 0.08);
  --shadow-lg: 0 12px 32px rgb(15 23 42 / 0.12);
  --overlay:   rgb(15 23 42 / 0.5);
}

:root[data-theme="dark"] {
  --bg:            #0B1220;
  --surface:       #111827;
  --surface-2:     #1A2332;
  --surface-3:     #243044;
  --border:        #263244;
  --border-strong: #334155;
  --input-border:  #64748B;

  --text:          #F1F5F9;
  --text-2:        #CBD5E1;
  --text-muted:    #94A3B8;
  --text-disabled: #64748B;
  --text-on-primary: #FFFFFF;

  --primary:        #3B82F6;  /* buttons: white text on #2563EB if contrast is tight */
  --primary-hover:  #60A5FA;
  --primary-active: #93C5FD;
  --primary-subtle: #172554;
  --focus-ring:     #60A5FA;

  --success:        #4ADE80;  --success-subtle: #052E16;  --success-border: #166534;
  --warning:        #FBBF24;  --warning-subtle: #2D1B04;  --warning-border: #92400E;
  --danger:         #F87171;  --danger-subtle:  #2A0A0A;  --danger-border:  #991B1B;
  --info:           #38BDF8;  --info-subtle:    #07263A;  --info-border:    #075985;

  --shadow-sm: 0 1px 2px rgb(0 0 0 / 0.4);
  --shadow-md: 0 4px 12px rgb(0 0 0 / 0.45);
  --shadow-lg: 0 12px 32px rgb(0 0 0 / 0.55);
  --overlay:   rgb(0 0 0 / 0.65);
}

@media (prefers-color-scheme: dark) {
  :root:not([data-theme="light"]) { /* duplicate the dark token block here */ }
}
```

Color rules:
- Dark mode is **not** inverted light mode. Use dark gray-blue (never pure `#000`), reduce surface contrast, lighten semantic colors.
- Primary action color is used sparingly: one primary button per view region.
- Semantic color usage: success = completed/valid, warning = needs attention, danger = error/destructive, info = neutral notice.
- Chart palette (colorblind-safe, no purple): `#2563EB`, `#0F766E`, `#D97706`, `#475569`, `#DC2626`, `#0891B2`. Lighten each ~15% in dark mode. Add patterns/labels, not color only.
- Links: primary color, underlined on hover (always underlined inside body text).

Theme toggle behavior:
- Three options: Light, Dark, System (default System).
- Persist choice (`localStorage`, wrapped in try/catch). Apply theme **before first paint** (inline script in `<head>`) to prevent flash.
- Transition colors with `transition: background-color .15s, color .15s, border-color .15s`, and disable transitions when `prefers-reduced-motion`.

---

## 2. Typography

- Font stack: `Inter, "Segoe UI", system-ui, -apple-system, Roboto, "Helvetica Neue", Arial, sans-serif`. Mono for code/IDs: `"JetBrains Mono", ui-monospace, "SF Mono", Consolas, monospace`.
- Use `font-variant-numeric: tabular-nums` for tables, prices, metrics.
- Base size **16px** (body 14px allowed only in dense data tables/admin tools). Never below 12px.
- Line height: body 1.5, headings 1.2-1.3, dense UI 1.4.
- Max line length for reading text: 60-75 characters (`max-width: 70ch`).
- Use rem, not px, for font sizes (respects user settings). Never disable zoom.

| Token | Size | Weight | Use |
|---|---|---|---|
| `--fs-xs` | 0.75rem (12px) | 500 | captions, badges |
| `--fs-sm` | 0.875rem (14px) | 400/500 | secondary text, table cells, labels |
| `--fs-md` | 1rem (16px) | 400 | body, inputs |
| `--fs-lg` | 1.125rem (18px) | 600 | card titles |
| `--fs-xl` | 1.25rem (20px) | 600 | section headings |
| `--fs-2xl` | 1.5rem (24px) | 600 | page titles |
| `--fs-3xl` | 1.875rem (30px) | 700 | dashboard KPI, hero numbers |

Weights: 400 body, 500 labels/buttons, 600 headings. Avoid 800-900 and avoid all-caps long text. Heading hierarchy must be semantic (`h1` once per page, no skipped levels).

---

## 3. Sizing, Spacing and Layout

Spacing scale (4px base): `4, 8, 12, 16, 20, 24, 32, 40, 48, 64`.

```css
--space-1: .25rem; --space-2: .5rem; --space-3: .75rem; --space-4: 1rem;
--space-5: 1.25rem; --space-6: 1.5rem; --space-8: 2rem; --space-10: 2.5rem; --space-12: 3rem;

--radius-sm: 4px;   /* badges, checkboxes */
--radius-md: 8px;   /* buttons, inputs */
--radius-lg: 12px;  /* cards, modals */
--radius-full: 999px;
```

Control sizes (consistent across buttons, inputs, selects):

| Size | Height | Padding X | Font | Use |
|---|---|---|---|---|
| sm | 32px | 12px | 14px | dense tables, toolbars |
| md (default) | 40px | 16px | 14-16px | most controls |
| lg | 48px | 20px | 16px | mobile primary actions, auth forms |

- **Touch target minimum 44x44px** on touch devices (24x24 absolute minimum on desktop for tiny icon buttons, with spacing). Add padding or pseudo-element hit area if the icon is smaller.
- Gap between adjacent interactive targets: at least 8px.
- Icons: 16px (inline), 20px (buttons, nav), 24px (headers). Stroke 1.5-2px, one icon family (Lucide, Heroicons, Material Symbols). Always pair icon-only buttons with `aria-label` and a tooltip.
- Cards: padding 16-24px, 1px border, `--radius-lg`, `--shadow-sm`.
- Page container: `max-width: 1280px` (content apps), `1440px` (data dense), centered, side padding 16px mobile / 24px tablet / 32px desktop.
- Sidebar: 240-280px expanded, 64-72px collapsed. Top bar: 56-64px. Modal widths: 400 (confirm), 560 (form), 720+ (complex). Never taller than `90vh`; body scrolls inside.
- Table row height: 40px dense, 48px default, 56px comfortable. Sticky header.

Responsive breakpoints (mobile-first):
`sm 640px`, `md 768px`, `lg 1024px`, `xl 1280px`, `2xl 1536px`.
- Under `md`: sidebar becomes a drawer or bottom navigation, tables become cards or scroll horizontally inside their own container, modals become full-screen sheets, buttons in forms become full width.
- Use CSS Grid/Flex, `min()`, `clamp()`, and `dvh` (not `100vh`). Never allow horizontal page scroll.
- Test at 320px, 375px, 768px, 1024px, 1440px. Support 200% zoom without loss of content.
- Respect safe areas on mobile: `env(safe-area-inset-*)`.

Layout principles:
- Align to a grid, use whitespace to group (Gestalt proximity), keep one clear focal point per screen.
- Group related fields; separate groups with 24-32px, items inside with 8-16px.
- Left-align text and labels (center only short headings, empty states, auth cards).
- Visual hierarchy: size, weight and color contrast, not decoration.

---

## 4. Human-Computer Interaction (HCI) Principles

Apply Nielsen's 10 heuristics to every screen:

1. **Visibility of system status**: always show where the user is (active nav item, breadcrumbs, page title), what is happening (spinners, progress), and the result (toast, inline message).
2. **Match the real world**: use the user's language and domain terms, not developer terms. Logical order, familiar icons.
3. **User control and freedom**: Cancel, Back, Undo, Close (X + Esc + overlay click where safe). Never trap the user.
4. **Consistency and standards**: same action = same label, icon, position everywhere. Follow platform conventions (primary action on the right in dialogs, logo links home, search icon = magnifier).
5. **Error prevention**: see section 7.
6. **Recognition over recall**: show options, recent items, placeholders as examples, autocomplete, visible labels. Never use placeholder as the only label.
7. **Flexibility and efficiency**: keyboard shortcuts, bulk actions, saved filters, defaults, command palette (`Ctrl/Cmd+K`) for larger apps.
8. **Aesthetic and minimalist design**: remove anything not supporting a task. Progressive disclosure for advanced options.
9. **Help users recognize, diagnose and recover from errors**: see section 8.
10. **Help and documentation**: contextual hints, tooltips, empty-state guidance, link to docs.

Supporting laws:
- **Fitts's law**: important targets large and close; destructive buttons small, away from primary.
- **Hick's law**: fewer choices per screen; group, filter, or paginate long lists.
- **Miller's law / chunking**: break long forms into steps of about 5-9 fields.
- **Jakob's law**: users expect your app to work like others they know.
- **Doherty threshold**: respond within 400ms; if longer, show feedback.
- **Aesthetic-usability + Peak-end**: polish every state, especially success and error endings.

### Response time feedback

| Duration | Feedback |
|---|---|
| < 100ms | none needed, feels instant |
| 100ms-1s | button pressed state, subtle inline indicator |
| 1-10s | spinner or skeleton, disable the triggering control |
| > 10s | determinate progress bar, estimate, and allow cancel / background |

Prefer **skeleton screens** over spinners for page and list loading. Use **optimistic updates** for low-risk actions (toggle, like, reorder) with rollback on failure.

### Interaction states (all required)

```css
.btn:hover:not(:disabled)        { background: var(--primary-hover); }
.btn:active:not(:disabled)       { background: var(--primary-active); transform: translateY(1px); }
.btn:focus-visible               { outline: 2px solid var(--focus-ring); outline-offset: 2px; }
.btn:disabled, .btn[aria-disabled="true"] { opacity: .5; cursor: not-allowed; }
.btn[aria-busy="true"]           { cursor: progress; /* show spinner, keep width stable */ }
```

- Never remove focus outlines without a visible replacement. Use `:focus-visible`.
- Cursor: `pointer` for clickable, `not-allowed` for disabled, `text` for inputs, `progress` while busy.
- Hover must never be the only way to reveal functionality (touch has no hover).
- Disabled controls need an explanation (tooltip or helper text: "Complete required fields to continue").
- Keep button width stable when loading (swap label for spinner without layout shift).

### Motion

- Duration: 100-150ms (hover), 200-250ms (panels, dropdowns), 300ms max (modals, page).
- Easing: `ease-out` entering, `ease-in` leaving. Animate `opacity` and `transform` only.
- Wrap animations: `@media (prefers-reduced-motion: reduce) { * { animation-duration: .01ms !important; transition-duration: .01ms !important; } }`.
- No bouncing, parallax, auto-playing carousels, or looping decorative animation.

### Feedback patterns: which one when

| Situation | Use |
|---|---|
| Result of a quick action (saved, copied, deleted) | **Toast** (4-6s, bottom-right or top-center, with Undo when possible, `role="status"`) |
| Field validation | **Inline** message under the field |
| Page-level or form-level problem | **Alert banner** at top of the section, `role="alert"` for errors |
| Needs a decision or irreversible action | **Modal confirm dialog** |
| Persistent state (offline, maintenance, trial ending) | **Sticky banner** |
| Long running job | **Progress bar** + notification when done |
| No data yet | **Empty state** with explanation and primary action |

Toasts must not be the only place critical errors appear (they disappear). Errors that need action stay on screen until resolved.

### Navigation

- Primary nav: left sidebar (apps with 5+ sections) or top bar (fewer). Highlight active item with color + weight + `aria-current="page"`.
- Show breadcrumbs for hierarchies deeper than 2 levels.
- Keep URLs meaningful and shareable (filters, tabs, pagination in query string). Back button must work.
- Preserve scroll position, filters and form drafts when navigating back.
- Warn before leaving with unsaved changes (`beforeunload` + in-app route guard).
- Limit nesting to 3 levels.

### Data tables and lists

- Sticky header, sortable columns (with `aria-sort`), right-align numbers, left-align text, truncate with ellipsis plus tooltip/title.
- Search + filter + sort + pagination (25/50/100 per page) or virtualized list for large data. Show total count and current range.
- Row selection with checkbox, select-all, and a bulk action bar showing the selected count.
- Row actions in a kebab menu (3+ actions) or visible icon buttons (1-2).
- States: loading (skeleton rows), empty (no data), empty-filtered ("No results for 'x'. Clear filters"), error (retry).
- Persist user preferences for column visibility and page size.
- Allow export (CSV) for business data when relevant.

### Forms (completeness)

- One column layout by default; labels **above** fields; required marked with `*` and "Required" in legend; mark optional ones as "(optional)" if most are required.
- Field anatomy: label, control, helper text (optional), error text. Link with `aria-describedby`; error with `aria-invalid="true"`.
- Use the correct `type`, `inputmode`, and `autocomplete` (`email`, `tel`, `one-time-code`, `current-password`, `new-password`, `postal-code`...). Mobile gets the right keyboard.
- Input widths reflect expected content (zip short, address long).
- Primary submit button at the bottom-left of the form (or right in dialogs), secondary Cancel beside it, label with a verb ("Save changes", "Create invoice", not "Submit" or "OK").
- Prevent double submit: disable and show busy state after the first click, plus an idempotency key for server calls.
- Multi-step forms: show progress ("Step 2 of 4"), allow going back without data loss, summary/review before final submit, auto-save drafts.
- Password fields: show/hide toggle, strength guidance, paste allowed.
- Dates: use native/accessible date picker, show the expected format, accept typed input.
- Search inputs: debounce 250-300ms, clear button, `Esc` clears, show result count.

### Keyboard and accessibility (WCAG 2.2 AA)

- Everything operable by keyboard in a logical tab order (DOM order = visual order). Never use positive `tabindex`.
- Skip link ("Skip to main content") as the first focusable element.
- Use semantic HTML first (`button`, `a`, `nav`, `main`, `table`, `label`); ARIA only to fill gaps. A `div` with onClick is a bug.
- Modals: trap focus, move focus in on open, return focus to the trigger on close, `Esc` closes, `aria-modal="true"`, `role="dialog"` with `aria-labelledby`.
- Menus/tabs/comboboxes follow WAI-ARIA Authoring Practices (arrow keys, Home/End, type-ahead).
- Announce dynamic changes with `aria-live="polite"` (status) or `role="alert"` (errors).
- Images: meaningful `alt`; decorative `alt=""`. Icons-only: `aria-label`.
- Don't use placeholder-only labels, color-only status, or time-limited actions without extension.
- Support `prefers-reduced-motion`, `prefers-contrast`, 200% text resize, and forced-colors mode.
- Language attribute on `<html lang>`; support RTL via logical CSS properties (`margin-inline-start`) if i18n is needed.

---

## 5. Component Standards

**Buttons**: variants = primary (solid blue), secondary (outlined/neutral), tertiary/ghost (text), danger (solid red, only in destructive context), link. One primary per section. Label = verb + object. Min width 80px. Icon + text gap 8px.

**Inputs**: height 40px, 1px `--input-border`, radius 8px, background `--surface`. Hover: border darker. Focus: 2px focus ring + primary border. Error: danger border + icon + message. Disabled: `--surface-2` + muted text. Read-only distinct from disabled (selectable text).

**Select / Combobox**: searchable if more than 7 options; show selected value; clear option; keyboard operable; loading and empty states inside list.

**Checkbox / Radio / Switch**: minimum 20px visual, 44px hit area, label clickable. Switch = immediate effect; checkbox = needs Save. Group with `fieldset`/`legend`.

**Badges / Status chips**: icon + text + semantic subtle background + border. Never color only.

**Tabs**: for switching views of the same context; not for steps or navigation between pages. Max 6-7.

**Modal / Dialog**: title, concise body, actions at the bottom right (secondary left of primary). Focus first logical control (the safest one in destructive dialogs). Don't stack modals. Prefer inline panels or drawers for long forms.

**Drawer / Side panel**: for details and editing while keeping context (480-640px).

**Tooltip**: supplemental only (never essential info), shows on hover and focus, delay 300-500ms, dismiss with Esc, short text.

**Dropdown menu**: max about 8 items, group with dividers, destructive item last in danger color, shortcuts shown on right.

**Toast**: max 3 visible, stack, pause on hover/focus, close button, never auto-dismiss errors needing action.

**Pagination / infinite scroll**: use pagination for tasks requiring location and comparison; infinite scroll only for feeds; always provide "Back to top" and keep position on return.

**Empty state**: icon/illustration (neutral colors), one-line explanation, primary action ("Create your first project"), optional doc link.

**Skeleton**: matches final layout; neutral shimmer `--surface-2` to `--surface-3` (disabled under reduced motion).

**Avatars, cards, breadcrumbs, steppers, progress, accordion, date picker, file upload (drag and drop + click + progress + type/size validation + remove)** all follow the same token, size and state rules.

---

## 6. Content and Microcopy

- Plain language, active voice, sentence case ("Save changes", not "SAVE CHANGES" or "Save Changes").
- Be specific: "Invoice #1042 deleted" not "Success".
- Labels are nouns, buttons are verbs, errors say what happened + why + how to fix.
- Consistent terminology (do not alternate Delete/Remove/Discard for the same action).
- Numbers, dates and currency formatted for the user's locale (`Intl.NumberFormat`, `Intl.DateTimeFormat`); show relative time with absolute time on hover; always include timezone for scheduling.
- Tone: calm, respectful, never blaming ("Enter a valid email" not "You entered a wrong email").

---

## 7. Error Prevention (do this before errors can happen)

**Constrain input**
- Use the right control: date pickers, selects, steppers, sliders, toggles, radio groups instead of free text where options are known.
- `maxlength` with a live character counter, `min`/`max`, `step`, `pattern`, input masks for phone/card/ID (formatting, not blocking paste).
- Disable or hide actions that are invalid in the current state, **and tell the user why**.
- Prefill defaults, remember last-used values, offer autocomplete and suggestions.

**Validate early and gently**
- Validate on blur (first time) and then on change after an error is shown; never show errors while the user is still typing the first time.
- On submit: validate everything, focus the first invalid field, show a summary at top for long forms (`role="alert"`, links to each field).
- Server-side validation always repeated (client validation is for UX only). Map server field errors back to fields.
- Normalize input: trim whitespace, case-fold emails, accept `+91 98765 43210` formats, strip thousand separators.
- Check availability asynchronously (username/email taken) with debounce.

**Protect against destructive and irreversible actions**
- Prefer **Undo** (soft delete, toast with Undo for 5-10s, trash with restore for 30 days) over confirmation dialogs; use confirmation only when undo is impossible.
- Confirmation dialog must name the object and consequence: "Delete project 'Alpha'? 14 tasks will be permanently removed." Button label repeats the action ("Delete project"), not "OK". Default focus on Cancel.
- For very high-risk actions (delete account, bulk delete, production deploy): require typing the resource name or a password.
- Separate destructive buttons spatially and visually from safe ones; never make danger the primary visual default.
- Show affected count in bulk actions ("Delete 23 selected items").

**Protect against data loss**
- Auto-save drafts (debounced) and show "Saved 10:42" / "Saving..." status.
- Warn on unsaved changes when navigating or closing.
- Preserve form state on error, refresh, or session expiry (restore drafts).
- Optimistic concurrency: detect edit conflicts (ETag/version) and offer merge/overwrite choice.

**Prevent duplicate and conflicting operations**
- Disable submit on click, idempotency keys, server-side uniqueness constraints.
- Rate-limit and debounce rapid actions (search, save, refresh).
- Lock or flag records being edited by others.

**Prevent security and permission errors**
- Hide or disable what the user can't do (with explanation); enforce permissions on the server too.
- Session timeout warning 2 minutes before expiry with "Stay signed in".
- Sanitize and escape all user content (XSS), CSRF protection, validate uploads by type, size and content.
- Mask sensitive data by default (show on demand), never put secrets in URLs or logs.

**Prevent environmental errors**
- Detect offline (`navigator.onLine` + failed requests) and show a banner; queue writes and sync when back online if feasible.
- Handle slow networks with timeouts (10-30s), retries with exponential backoff and jitter for idempotent requests.
- Feature-detect instead of browser-sniffing; graceful fallback when JS APIs are unavailable.
- Validate environment configuration at startup; fail fast with a clear message.

---

## 8. Error Handling (when errors still happen)

### Error taxonomy and handling

| Type | Examples | UX response |
|---|---|---|
| Validation | empty required, bad format | Inline under field, focus first, keep input |
| Authentication | 401, expired session | Save draft, redirect to sign in with return URL, explain "Your session expired" |
| Authorization | 403 | "You don't have permission to do this. Contact your admin." + request-access path |
| Not found | 404 | Friendly page, search, link home; for resource: "This item was deleted or moved" |
| Conflict | 409, stale version | Show what changed, offer reload / overwrite / merge |
| Rate limit | 429 | "Too many requests. Try again in 30 seconds" with countdown |
| Client network | offline, timeout | Banner + Retry button, keep data, auto-retry when online |
| Server | 500, 502, 503 | Apologetic, non-technical, Retry, reference ID, status page link |
| Unexpected client bug | uncaught exception | Error boundary fallback, Reload, report option |
| Partial failure | 3 of 10 items failed | Show success count, list failures with reasons, offer Retry failed |

### Error message formula
**What happened + why (if known) + what to do next**, in plain language, polite, specific.

- Bad: `Error 500`, `Invalid input`, `Something went wrong`, `Operation failed`.
- Good: `We couldn't save your changes because the connection was lost. Your edits are kept. Check your connection and try again.` [Try again]
- Field: `Enter an email like name@example.com` (not "Invalid email").
- Include a short **reference/trace ID** for server errors ("Reference: 7F3A-91C2") and make it copyable.
- Place the message next to the cause, use danger color + icon + text, and keep it visible until fixed.
- Never clear what the user typed. Never blame the user. Don't use humor for serious errors.

### Implementation requirements

1. **Central API layer**: one wrapper that adds timeout, retry (idempotent only), auth refresh, error normalization to `{ code, message, userMessage, fieldErrors, requestId, retryable }`.
2. **Never swallow errors**: every `catch` either handles, shows, or rethrows; log with context to a monitoring service (Sentry or equivalent) with PII stripped.
3. **Error boundaries** at app level and around independent widgets, so one failing widget doesn't break the page (fallback card with Retry).
4. **Global handlers**: `window.onerror` and `unhandledrejection` log and show a generic recoverable message.
5. **Loading + error + empty + success** for every data view (use a state machine: `idle | loading | success | empty | error`).
6. **Retry UX**: Retry button on every recoverable failure; automatic backoff retry for background fetches; stop and surface after max attempts.
7. **Graceful degradation**: cached/stale data shown with "Last updated" notice when refresh fails.
8. **Dedicated pages**: 404, 403, 500, offline, maintenance. Each has: clear title, short explanation, primary action (Go to dashboard / Retry), support link.
9. **Accessible announcements**: `role="alert"` for errors, move focus to error summary on submit failure.
10. **Form submit failure**: re-enable form, keep values, show top summary + inline field errors, focus first problem.

Example form field pattern:

```html
<div class="field">
  <label for="email">Email <span aria-hidden="true">*</span></label>
  <input id="email" type="email" autocomplete="email" required
         aria-invalid="true" aria-describedby="email-hint email-error" />
  <p id="email-hint" class="hint">We'll send the receipt here.</p>
  <p id="email-error" class="error" role="alert">
    <svg aria-hidden="true">...</svg> Enter an email like name@example.com
  </p>
</div>
```

Example API wrapper skeleton:

```js
async function api(path, { method = 'GET', body, retries = 2, timeout = 15000 } = {}) {
  const ctrl = new AbortController();
  const t = setTimeout(() => ctrl.abort(), timeout);
  try {
    const res = await fetch(path, {
      method, signal: ctrl.signal,
      headers: { 'Content-Type': 'application/json' },
      body: body ? JSON.stringify(body) : undefined,
    });
    if (!res.ok) throw await normalizeError(res);       // -> {code, userMessage, fieldErrors, requestId}
    return res.status === 204 ? null : await res.json();
  } catch (err) {
    const e = err.name === 'AbortError' ? timeoutError() : (err.userMessage ? err : networkError(err));
    if (e.retryable && method === 'GET' && retries > 0) {
      await sleep(2 ** (3 - retries) * 400 + Math.random() * 200);
      return api(path, { method, body, retries: retries - 1, timeout });
    }
    report(e);                                           // log to monitoring, no PII
    throw e;                                             // UI decides how to show it
  } finally { clearTimeout(t); }
}
```

---

## 9. Security, Privacy and Reliability Basics

- HTTPS only, secure and `HttpOnly` cookies, CSP headers, escape output, parameterized queries.
- Authenticate and authorize on the server for every request.
- Store minimal personal data, mask by default, honor consent and deletion requests.
- Don't expose whether an account exists on login/reset ("If that email exists, we sent a link").
- Lock sensitive actions behind re-authentication.
- Audit log for critical business actions where applicable.

## 10. Performance

- Targets: LCP < 2.5s, INP < 200ms, CLS < 0.1.
- Reserve space for images and async content (width/height, skeletons) to avoid layout shift.
- Code-split by route, lazy-load heavy components, compress and properly size images (WebP/AVIF), `loading="lazy"` below the fold.
- Virtualize lists over about 200 rows, debounce expensive handlers, memoize carefully.
- Cache GET data (stale-while-revalidate), paginate on the server.

---

## 11. Implementation Workflow (follow in order)

1. **Clarify**: users, main tasks, data, roles, devices. If unclear, assume a business user on desktop plus mobile.
2. **Define tokens** (section 1-3) in one CSS block; build light + dark together from the start.
3. **Build the app shell**: top bar, sidebar/nav, theme toggle, main content, skip link, toasts container, error boundary.
4. **Build shared components** with all states (section 5).
5. **Build screens** with loading / empty / error / success handled for each data region.
6. **Add validation, prevention and confirmation flows** (sections 7-8).
7. **Add accessibility pass**: keyboard-only walkthrough, screen reader labels, contrast check in both themes.
8. **Responsive pass** at 320 / 768 / 1024 / 1440 widths.
9. **Run the checklist below** and fix any failures before delivering.

Technology defaults (unless the user specifies otherwise): semantic HTML + CSS variables; React with TypeScript and Tailwind or CSS Modules for larger apps; accessible primitives (Radix UI, React Aria, Headless UI) for dialogs, menus, comboboxes; React Hook Form + Zod for forms; TanStack Query for data fetching, caching and retry; Lucide icons. For single-file deliverables, use plain HTML/CSS/JS with the same tokens.

---

## 12. Final Delivery Checklist

**Visual**
- [ ] No purple/violet/indigo/pink anywhere, no decorative gradients or glow
- [ ] Light and dark themes both complete; toggle works, persists, no flash on load
- [ ] All colors come from tokens; contrast 4.5:1 text, 3:1 UI in both themes
- [ ] Spacing on 4px scale; control heights 32/40/48; radius consistent
- [ ] Typography scale applied; one icon family; consistent alignment

**Interaction**
- [ ] Hover, focus-visible, active, disabled, loading states on every control
- [ ] Touch targets at least 44px on mobile; no hover-only features
- [ ] Clear primary action per view; verb-based labels; consistent terminology
- [ ] Feedback for every action (toast/inline/progress); skeletons for loading
- [ ] Keyboard-only operation works; focus trapped and restored in dialogs; skip link present
- [ ] Back button, deep links, filters in URL, scroll restoration work

**Forms and prevention**
- [ ] Visible labels, correct input types/autocomplete, helper text, required markers
- [ ] Validation on blur/submit, first error focused, input never lost
- [ ] Double-submit prevented; unsaved-changes warning; drafts/auto-save where relevant
- [ ] Destructive actions have undo or specific confirmation; high-risk require typed confirmation
- [ ] Invalid actions disabled with an explanation; permissions enforced client + server

**Errors**
- [ ] Every data view has loading, empty, empty-filtered, error and success states
- [ ] Error messages follow what + why + next step; no raw technical text; reference ID for server errors
- [ ] Central API layer with timeout, retry/backoff, normalized errors, logging
- [ ] Error boundaries, 404/403/500/offline pages, offline banner, session-expiry handling
- [ ] Partial failures reported clearly with retry for failed items

**Accessibility and responsive**
- [ ] Semantic HTML, labels, `aria-live`/`role="alert"`, correct heading order
- [ ] Reduced-motion, 200% zoom, and screen-reader checks pass
- [ ] Layout works at 320px to 1440px+; no horizontal page scroll; tables adapt

**Quality**
- [ ] Core Web Vitals targets met; images sized; code split
- [ ] No console errors; no leftover placeholder or lorem ipsum text
- [ ] README or short note listing tokens, components, and keyboard shortcuts

If any item is not applicable, state why instead of silently skipping it.
