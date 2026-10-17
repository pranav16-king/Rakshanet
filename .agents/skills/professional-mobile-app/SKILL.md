---
name: professional-mobile-app
description: Design and build professional, production-grade mobile applications and mobile UI (mobile-ui, professional-mobile-app) across iOS, Android, React Native, Flutter, Expo, Kotlin, Swift, and PWA with a clean business look, complete light and dark themes, correct touch sizing, native-feeling navigation and gestures, full human-computer interaction, offline support, permission handling, error handling, error prevention, accessibility and performance. Use this skill whenever the user asks for a mobile app, mobile-ui, mobile UI design, app screens, app UI, React Native or Flutter code, an Android or iOS app, a mobile-first PWA, or an app prototype. Also use it when the user complains about purple or flashy colors, poor mobile usability, tiny buttons, missing dark mode, or missing validation and error handling.
---

# Professional Mobile Application & Mobile UI Skill

Goal: apps that look like serious, trustworthy products (banking, health, logistics, productivity quality) and feel native, fast, safe and accessible on real phones used one-handed, outdoors, on slow networks.

## Quick References
- [Platform Guidelines: iOS (HIG) vs. Android (Material 3)](./references/platform-guidelines.md)
- [Mobile Gestures & Haptic Feedback Reference](./references/mobile-gestures-and-haptics.md)
- [Touch Targets & Thumb-Zone Ergonomics Reference](./references/touch-and-ergonomics.md)

Follow sections in order. Run the final checklist before delivering.

---

## 0. Hard Rules (never break)

1. **No purple, violet, indigo, magenta, pink or neon colors.** Use blue, slate, teal, green, amber, red only.
2. **No decorative gradients, glow, glassmorphism overload, or emoji as icons.** Flat surfaces, subtle borders, light elevation.
3. **Light and dark themes are mandatory**, token-based, following the system setting by default with a manual override (Light / Dark / System) that persists.
4. **Never hard-code colors, sizes, spacing or strings in screens.** Use theme tokens and localization files.
5. **Touch targets at least 48x48dp (Android) / 44x44pt (iOS).** Spacing between targets at least 8dp.
6. **Every screen has loading, empty, error, offline and success states.**
7. **Every action gives immediate feedback** (pressed state within 100ms, haptic where appropriate).
8. **No dead ends**: every screen can go back, and every error has a recovery action.
9. **Destructive actions need undo or specific confirmation.**
10. **Never show raw technical errors, codes only, or stack traces.**
11. **Never rely on color alone** to convey meaning. Add icon and text.
12. **Request permissions in context**, never all at launch.

---

## 1. Platform Approach

- Follow **Material Design 3** conventions on Android and **Apple Human Interface Guidelines** on iOS. Where one codebase is used (React Native / Flutter), adapt: back gesture, navigation transitions, date/time pickers, action sheets vs bottom sheets, switch style, safe areas, status bar.
- Choose the stack by need unless the user specifies:
  - **React Native + Expo + TypeScript** (default for most business apps): React Navigation / Expo Router, TanStack Query, React Hook Form + Zod, Zustand/Redux Toolkit, MMKV/SQLite, Reanimated.
  - **Flutter** when pixel-consistent custom UI or heavy animation is required: Riverpod/Bloc, go_router, Dio, Drift/Hive.
  - **Native (Swift/SwiftUI, Kotlin/Compose)** for platform-deep features (background processing, widgets, advanced hardware).
  - **PWA** only when installation, push and hardware needs are light.
- Architecture: feature-based folders, separate UI / state / data layers, repository pattern for API + cache, dependency injection, single source of truth for data.

---

## 2. Color System (Theme Tokens)

Same professional palette as the web skill, exposed as a theme object. Never purple.

```ts
export const lightTheme = {
  bg:'#F8FAFC', surface:'#FFFFFF', surface2:'#F1F5F9', surface3:'#E2E8F0',
  border:'#E2E8F0', inputBorder:'#94A3B8',
  text:'#0F172A', text2:'#334155', textMuted:'#475569', textDisabled:'#94A3B8', onPrimary:'#FFFFFF',
  primary:'#1D4ED8', primaryPressed:'#1E3A8A', primarySubtle:'#EFF6FF', focus:'#2563EB',
  success:'#15803D', successSubtle:'#F0FDF4',
  warning:'#B45309', warningSubtle:'#FFFBEB',
  danger:'#B91C1C',  dangerSubtle:'#FEF2F2',
  info:'#0369A1',    infoSubtle:'#F0F9FF',
  overlay:'rgba(15,23,42,0.5)',
};

export const darkTheme = {
  bg:'#0B1220', surface:'#111827', surface2:'#1A2332', surface3:'#243044',
  border:'#263244', inputBorder:'#64748B',
  text:'#F1F5F9', text2:'#CBD5E1', textMuted:'#94A3B8', textDisabled:'#64748B', onPrimary:'#FFFFFF',
  primary:'#3B82F6', primaryPressed:'#60A5FA', primarySubtle:'#172554', focus:'#60A5FA',
  success:'#4ADE80', successSubtle:'#052E16',
  warning:'#FBBF24', warningSubtle:'#2D1B04',
  danger:'#F87171',  dangerSubtle:'#2A0A0A',
  info:'#38BDF8',    infoSubtle:'#07263A',
  overlay:'rgba(0,0,0,0.65)',
};
```

Rules:
- Contrast: text 4.5:1, large text and icons/borders 3:1, in both themes.
- Dark mode uses dark blue-gray, never pure black, except optional OLED "true black" setting. Elevation in dark mode is shown by lighter surfaces, not shadows.
- Primary color for the single main action per screen; secondary actions are outlined or text.
- Status bar style matches theme (light content on dark, dark content on light). Navigation bar and splash screen themed too.
- Provide theme through context/provider; read `useColorScheme()` / `Appearance` (RN), `MediaQuery.platformBrightness` (Flutter), `isSystemInDarkTheme()` (Compose), `@Environment(\.colorScheme)` (SwiftUI). Apply theme before first frame to avoid flash.
- Charts: `#2563EB #0F766E #D97706 #475569 #DC2626 #0891B2`, with labels or patterns.
- Support dynamic color (Material You) only if it never yields purple-heavy results on the brand surfaces; default to the fixed palette above.

---

## 3. Typography, Spacing and Sizing

**Fonts**: system font (SF Pro on iOS, Roboto on Android) or Inter. Support Dynamic Type (iOS) and font scale (Android) up to 200% without clipping: use flexible layouts, `allowFontScaling`, `maxFontSizeMultiplier` (about 1.5-2.0 for dense UI), never fixed-height text containers.

| Role | Size (sp/pt) | Weight | Use |
|---|---|---|---|
| Caption | 12 | 400/500 | helper, badges, timestamps |
| Body small | 14 | 400 | secondary text, list subtitles |
| Body | 16 | 400 | default text, inputs (16 prevents iOS zoom) |
| Title small | 18 | 600 | card titles, list headers |
| Title | 20-22 | 600 | screen section titles |
| Headline | 24-28 | 600/700 | screen titles, large nav titles |
| Display | 32+ | 700 | KPI numbers, onboarding |

Line height 1.4-1.5 for body, 1.2-1.3 for headings. Numbers in tables/amounts: tabular figures.

**Spacing scale (4dp base)**: `4, 8, 12, 16, 20, 24, 32, 40, 48`. Screen horizontal padding **16dp** (20-24 on tablets). Section gap 24dp. Item gap 8-12dp.

**Radii**: 8 (inputs, buttons), 12 (cards), 16-24 (bottom sheets top corners), full (chips, avatars, FAB).

**Component sizes**

| Component | Size |
|---|---|
| Button (default) | height 48-52, padding X 16-24, radius 8-12 |
| Button (compact) | height 40 (hit area extended to 48) |
| Text input | height 48-56, font 16, radius 8 |
| List item (one line) | min height 56; two-line 72; three-line 88 |
| App bar / top bar | 56dp Android, 44pt + safe area iOS (large title 96) |
| Bottom tab bar | 56-64dp (+ safe area), 3-5 items, icon 24 + label 12 |
| FAB | 56 (mini 40), 16 from edges, above tab bar |
| Icon | 20-24, touch target 48 |
| Avatar | 32 / 40 / 56 |
| Chip | height 32, hit area 48 |
| Switch / checkbox / radio | visual 20-24, hit 48 |
| Bottom sheet handle | 32x4 |
| Snackbar | min height 48, 16 margin |
| Dialog | width 280-560, padding 24 |

**Safe areas**: respect notch, status bar, home indicator, camera cutout, and rounded corners (`SafeAreaView`/`react-native-safe-area-context`, `SafeArea` in Flutter, `WindowInsets` in Compose). Never place controls under system bars.

**Responsive**: support small phones (320-360dp wide), large phones, foldables, tablets, landscape. Use flexible layouts (flex, constraints, weights), not fixed pixel widths. On tablets: two-pane layout (list + detail), max content width about 600-840dp for forms and reading. Handle keyboard avoidance and resizing.

---

## 4. Mobile HCI Principles

**Ergonomics (thumb zone)**
- Place primary actions in the lower half, within thumb reach. Use bottom navigation, bottom sheets, sticky bottom action bars.
- Avoid essential controls at the top corners; use top for titles, search, secondary actions.
- Design for one-handed use and for both left and right hands. Don't rely on tiny edge targets.

**Core heuristics** (Nielsen, adapted)
1. Visibility of status: loading, syncing, saved, offline, progress.
2. Match real world: plain language and familiar icons.
3. User control: back, cancel, undo, swipe-back, dismissable sheets.
4. Consistency: same action = same icon, label and place everywhere; follow platform patterns.
5. Error prevention: section 8.
6. Recognition over recall: visible options, recent items, autofill, suggestions.
7. Efficiency: defaults, shortcuts, biometrics, swipe actions, widgets, deep links.
8. Minimalism: one primary goal per screen, progressive disclosure.
9. Error recovery: section 9.
10. Help: onboarding hints, empty-state guidance, in-context help.

Supporting laws: Fitts (big close targets), Hick (few choices), Miller (chunk to 5-9), Jakob (match other apps), Doherty (respond under 400ms).

**Feedback timing**

| Duration | Feedback |
|---|---|
| < 100ms | pressed state/ripple, optional light haptic |
| 100ms-1s | inline indicator, button spinner |
| 1-10s | skeleton or spinner, disable the trigger |
| > 10s | determinate progress with cancel; allow background; notify on completion |

Prefer **skeleton screens** for lists and detail screens. Use **optimistic updates** for low-risk actions with rollback and an error snackbar.

**Touch states (all required)**: default, pressed (ripple on Android, opacity/highlight on iOS), focused (for keyboard/switch access), disabled (reduced opacity + explanation), loading (spinner, stable width), selected, error. Pressed feedback must be visible within 100ms.

**Haptics**: light impact on toggle/selection, success notification on completed key action, warning/error on failures. Subtle, never constant, respect system settings.

**Gestures**
- Gestures are shortcuts, never the only way. Always provide a visible alternative.
- Standard: tap, long-press (context menu, with visible hint), swipe-back, pull-to-refresh, swipe-to-reveal actions on list rows (max 2-3 actions, destructive in red with Undo), pinch/zoom on media and maps.
- Don't conflict with system gestures (edge swipes, home indicator). Don't hijack back navigation.
- Avoid double-tap, multi-finger, and shake as required interactions.

**Motion**
- 100-150ms for micro feedback, 200-300ms for transitions, never over 400ms.
- Use platform-standard transitions (shared element for list to detail, slide for push, bottom-up for modal).
- Animate `opacity` and `transform` on the UI thread (Reanimated worklets, Flutter implicit animations, Compose animate*).
- Respect "Reduce Motion": replace motion with fades/instant changes.
- No decorative looping animations or parallax.

**Content-first layout**: lists with clear hierarchy (title, one supporting line, trailing meta/action), cards only when grouping needs a boundary, generous whitespace, consistent alignment on a 4dp grid.

---

## 5. Navigation and Information Architecture

- **Bottom tabs** for 3-5 top-level destinations of equal importance (icon + label, always labeled, active = color + weight; badge for counts). Tabs persist state per tab. Tapping the active tab scrolls to top or pops to root.
- **Stack navigation** for drill-down with a back button (top-left) and swipe-back on iOS / system back on Android. Titles describe the screen.
- **Drawer** only for many secondary destinations; avoid hiding primary navigation.
- **Modal / full-screen modal** for self-contained tasks (compose, edit, checkout) with explicit Close/Cancel and Save/Done.
- **Bottom sheets** for contextual choices, filters, quick forms; draggable handle, scrim dismiss, snap points, never required for critical flows without a close option.
- **Top app bar**: title, back, max 2-3 actions, overflow menu for the rest. Search as an icon expanding to a field or a pinned search bar.
- Keep depth shallow (max 3-4 levels), keep key destinations within 2-3 taps.
- **Deep links and universal/app links** for every shareable screen; restore the correct stack. Handle links when logged out (return after login).
- **State restoration**: restore the screen, scroll position, filters and drafts after process death, backgrounding or reopening.
- **Back behavior** predictable: Android back = one level up, never closes unexpectedly with unsaved data (confirm), predictive back animation supported.
- **Onboarding**: at most 3 short screens or none; allow skip; value first, sign-up later when possible; teach with contextual coachmarks, not long tutorials.
- **Authentication**: social/passwordless/biometric options, "Remember me", secure keyboard types, autofill (password managers, OTP auto-read), logout in a findable place.

---

## 6. Components and Patterns

**Buttons**: primary (filled blue), secondary (outlined), tertiary (text), destructive (filled red only in destructive context), icon buttons. Full-width primary on forms and sticky bottom bars. Label = verb + object ("Save address"). One primary per screen.

**Text inputs**: visible floating or top label (never placeholder-only), helper text, error text with icon, clear button, character counter when limited, correct keyboard (`email-address`, `numeric`, `phone-pad`), `autoComplete`/`textContentType`, return key type (next/done/search/go), moves focus to next field, scrolls into view above keyboard, secure entry with show/hide toggle.

**Selection**: switches apply immediately; checkboxes need confirmation by Save; radios for single choice up to 5, pickers/sheets for more; searchable list for long options; native date/time pickers.

**Lists**: virtualized (FlatList/FlashList, `ListView.builder`, `LazyColumn`), stable keys, pagination or infinite scroll with a footer loader and an error row with Retry, pull-to-refresh, section headers, swipe actions, empty states, skeleton rows, preserve scroll position.

**Cards**: padding 16, radius 12, border or soft elevation, whole card tappable when it navigates, no nested tappables conflicting.

**Dialogs (alerts)**: only for critical decisions; title + clear message + 2 actions (cancel left, confirm right on Android; follow iOS conventions), action text repeats the verb ("Delete").

**Snackbar / toast**: confirmation of quick results, 4-6s, above bottom tabs and keyboard, optional Undo action, error snackbars with Retry; never the sole channel for critical errors.

**Banners**: persistent states (offline, sync pending, update required, subscription issue).

**Progress**: linear for known duration, circular for short unknown waits, step indicators for multi-step flows ("Step 2 of 4").

**Search**: debounce 300ms, recent searches, suggestions, clear button, empty-result guidance, filters in a bottom sheet with applied-count badge and Reset.

**Media and uploads**: placeholders while loading (blurhash/skeleton), cached images, correct resizing, compression before upload, upload progress with cancel/retry, resumable uploads for large files.

**Maps/location**: show permission rationale first, handle denied/approximate location, battery-aware updates.

**Notifications**: opt-in at a meaningful moment, channels/categories with user control, actionable and relevant, deep link to the exact screen, badge counts accurate, quiet hours respected.

**Empty states**: neutral illustration/icon, one-line explanation, primary action; different copy for "nothing yet", "no results", and "no access".

---

## 7. Content and Microcopy

- Short, plain, active voice; sentence case; consistent terms (don't alternate Remove/Delete/Discard).
- Screen titles are nouns; buttons are verbs; specific outcomes ("Address saved").
- Localize all strings; support RTL via start/end (not left/right); format dates, numbers, currency and units with locale APIs; avoid text in images; allow 30-40% text expansion.
- Polite, respectful tone; never blame ("Enter a valid phone number").
- Show relative time with absolute available ("2h ago"), always handle time zones for schedules.

---

## 8. Error Prevention

**Constrain input**
- Use the right control (pickers, steppers, segmented controls, sliders) instead of free text where possible.
- Correct keyboard type, input masks (phone, card, date) that still accept paste, `maxLength` with counter, numeric limits.
- Disable invalid actions and explain why ("Add at least one item to continue"). Prefer enabled-with-explanation for the primary submit button if disabled-state confusion is likely.
- Prefill from known data, remember last used, support autofill and suggestions.

**Validate gently and early**
- Validate on blur, then live after the first error appears; never flash errors while typing first time.
- On submit: validate all, scroll to and focus the first invalid field, show error summary for long forms, keep all input.
- Always revalidate on the server and map field errors back.
- Normalize: trim, case-fold emails, strip formatting characters.
- Check uniqueness asynchronously (debounced).

**Protect against destructive actions and data loss**
- Prefer **Undo** (soft delete + snackbar Undo, trash with restore) over confirmation. Use dialogs for irreversible or costly actions, naming the object and consequence ("Delete 'Trip to Pune'? This can't be undone.").
- High-risk (delete account, payments, bulk delete): require re-authentication (biometric/password) or typed confirmation.
- Show counts in bulk actions ("Delete 12 items").
- Auto-save drafts; show "Saved" status; restore after crash/kill; confirm before discarding edits.
- Guard against accidental taps: spacing between destructive and safe controls; confirm swipe-to-delete or provide Undo.
- Payments: summary screen before pay, clear total with taxes/fees, idempotency keys, prevent double charge.

**Prevent duplicates and conflicts**
- Disable submit after tap and show busy state; idempotency keys; debounce rapid taps (e.g., 500ms on submit/navigation to avoid pushing the same screen twice).
- Optimistic concurrency (version/ETag) with a conflict resolution UI.
- Queue offline writes with a visible "Pending sync" marker.

**Prevent permission and environment errors**
- Ask permissions **just in time**, with a short pre-prompt explaining the benefit; handle "Don't allow", "Ask every time", and permanently denied (explain and deep link to Settings); offer a non-permission fallback (manual address entry instead of location, file picker instead of camera).
- Check connectivity, storage space, battery saver, background restrictions and OS version before heavy tasks.
- Version gating: soft/forced update prompts with clear message when the API is no longer supported.
- Feature-detect hardware (biometrics, NFC, camera) and degrade gracefully.
- Handle interruptions: calls, backgrounding, rotation, low memory, app kill, locale/theme change during use.

**Security as prevention**
- Store tokens in Keychain/Keystore (`expo-secure-store`, `flutter_secure_storage`), never AsyncStorage/SharedPreferences plain text.
- TLS only, certificate pinning for high-risk apps, no secrets in the bundle, obfuscation for release builds.
- Biometric unlock with fallback PIN; auto-lock after inactivity for sensitive apps; hide content in the app switcher and block screenshots on sensitive screens (`FLAG_SECURE`).
- Jailbreak/root detection only where required by risk.
- Clear sensitive data on logout; mask sensitive fields; avoid logging PII.
- Sanitize deep link and push payload inputs; validate everything from outside.

---

## 9. Error Handling

### Error types and responses

| Type | Examples | UX response |
|---|---|---|
| Validation | empty/invalid field | Inline under field, focus first, keep input |
| Auth | 401, expired token | Refresh silently; if failing, save draft, show "Session expired" sign-in, return to the same screen |
| Permission (OS) | camera/location denied | Explain why needed, retry, open Settings, fallback |
| Authorization | 403 | "You don't have access. Contact your admin." |
| Not found | 404/deleted item | Screen explaining item moved/deleted + go back/home |
| Conflict | 409 | Show what changed, offer reload / overwrite / merge |
| Rate limit | 429 | "Too many attempts. Try again in 30s" with countdown |
| Network | offline, timeout, DNS | Offline banner, cached data, Retry, auto-retry on reconnect |
| Server | 5xx | Apologetic message, Retry, reference ID, support link |
| Payment | declined, 3DS failed | Specific reason, alternate method, no double charge |
| Storage/Device | disk full, camera busy | Clear instruction to free space/retry |
| Crash/Unexpected | uncaught exception | Error boundary fallback screen, restart option, crash report |
| Partial failure | 3 of 10 uploads failed | Show success count, list failures, "Retry failed" |

### Message formula
**What happened + why (if known) + what to do next**, plain, polite, specific.
- Bad: "Error 500", "Something went wrong", "Operation failed".
- Good: "We couldn't upload your photo because your connection dropped. It's saved on your phone. Reconnect and tap Retry."
- Server errors include a copyable **reference ID**.
- Keep the message next to the cause; use danger color + icon + text; persistent until fixed for blocking errors.
- Never discard user input; never blame the user.

### Implementation requirements
1. **Central API client**: timeout (15-30s), retries with exponential backoff + jitter for idempotent calls, token refresh with request queue, error normalization to `{ code, userMessage, fieldErrors, requestId, retryable }`, cancellation on unmount/navigation.
2. **Data layer states**: every query exposes `idle | loading | success | empty | error` (+ `refreshing`, `stale`). UI renders every state.
3. **Offline-first where valuable**: local cache (SQLite/MMKV/Realm/Room), show cached data immediately then refresh (stale-while-revalidate), write queue with sync, conflict strategy, "Last updated" label, connectivity listener (NetInfo/connectivity_plus).
4. **Error boundaries** (React Error Boundary, Flutter `FlutterError.onError` + `runZonedGuarded`, Android/iOS global handlers) with a friendly fallback screen and restart action.
5. **Crash and error reporting** (Sentry, Firebase Crashlytics) with breadcrumbs, app version, and no PII; analytics for failed flows.
6. **Never swallow errors**: every catch handles, shows, or rethrows.
7. **Retry UX**: Retry button for every recoverable failure; pull-to-refresh retries; automatic retry for background syncs with a stop after N attempts.
8. **Dedicated screens**: offline, maintenance, force-update, not-found, no-permission, generic error. Each has title, short explanation, primary action, support link.
9. **Accessibility of errors**: announce via accessibility live region/`AccessibilityInfo.announceForAccessibility`, move focus to the first error, and don't use color alone.
10. **Form submit failure**: re-enable form, keep values, show summary + inline errors, scroll to first problem, haptic error feedback.

Example API client skeleton (React Native / TypeScript):

```ts
export async function api<T>(path: string, opts: Req = {}): Promise<T> {
  const { method = 'GET', body, retries = 2, timeout = 20000 } = opts;
  const ctrl = new AbortController();
  const timer = setTimeout(() => ctrl.abort(), timeout);
  try {
    const res = await fetch(BASE + path, {
      method, signal: ctrl.signal,
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${await getToken()}` },
      body: body ? JSON.stringify(body) : undefined,
    });
    if (res.status === 401 && await refreshToken()) return api<T>(path, { ...opts, retries });
    if (!res.ok) throw await normalizeError(res);  // {code,userMessage,fieldErrors,requestId,retryable}
    return res.status === 204 ? (null as T) : await res.json();
  } catch (e) {
    const err = toAppError(e); // AbortError -> timeout, TypeError -> network
    if (err.retryable && method === 'GET' && retries > 0) {
      await sleep(400 * 2 ** (2 - retries) + Math.random() * 200);
      return api<T>(path, { ...opts, retries: retries - 1 });
    }
    report(err);
    throw err;
  } finally { clearTimeout(timer); }
}
```

---

## 10. Accessibility (WCAG 2.2 AA + platform guidelines)

- Every interactive element has an accessible label, role and state (`accessibilityLabel/Role/State`, `Semantics`, `contentDescription`). Icon-only buttons always labeled.
- Logical focus/reading order; group related content; headings marked.
- Test with **VoiceOver** and **TalkBack**, switch control, and keyboard where available.
- Dynamic Type/font scale to 200%; bold text; layouts reflow, no truncation of essential info.
- Contrast 4.5:1 text, 3:1 non-text, in both themes; support high contrast.
- Touch targets 48dp/44pt; no timing-only interactions; gestures have alternatives.
- Honor Reduce Motion, Reduce Transparency, color inversion, and screen-reader announcements for dynamic changes (toasts, errors, loaded content).
- Captions/transcripts for audio/video; don't autoplay with sound.
- Never convey status by color alone.

---

## 11. Performance and Battery

- Targets: cold start under 2s (to interactive), 60fps scrolling (120 on capable devices), first meaningful screen under 1s from cache, small bundle/APK (use app bundles, split by ABI).
- Virtualize lists, memoize rows, avoid re-renders (React.memo, selectors, keys), keep animations on the UI thread, lazy-load screens and heavy libraries, use Hermes (RN) and release builds when measuring.
- Images: correct size, WebP/AVIF, caching library (expo-image, FastImage, cached_network_image), placeholders, progressive loading.
- Network: batch requests, cache with ETag, paginate, compress payloads, avoid polling (use push/WebSocket), respect data saver and metered networks.
- Background work: use OS schedulers (WorkManager, BGTaskScheduler), minimal location/sensor use, stop work when backgrounded.
- Memory: release listeners/subscriptions, avoid leaks, handle low-memory warnings.
- Test on low-end devices and slow 3G profiles, not only flagship phones.

---

## 12. Privacy, Compliance and Store Readiness

- Privacy policy and in-app data controls (export, delete account), consent for analytics/tracking (ATT on iOS), data minimization.
- Declare permissions accurately with usage descriptions (`NSCameraUsageDescription` etc.), Data Safety (Google Play) and Privacy Nutrition Labels (App Store).
- Follow store guidelines: no hidden features, in-app purchase rules, account deletion in-app, age rating, content policies.
- App icon (no purple), splash screen themed for light/dark, adaptive icon (Android), proper screenshots and descriptions.
- Versioning: semantic version + build number; forced-update mechanism; staged rollouts; feature flags and remote config; crash-free target above 99.5%.

---

## 13. Implementation Workflow (follow in order)

1. **Clarify**: users, top 3 tasks, platforms, offline needs, data, roles. If unclear assume a business user on Android + iOS phones, intermittent network.
2. **Define tokens** (colors light+dark, type, spacing, radii, sizes) in a theme file; build both themes together.
3. **Design navigation map**: tabs, stacks, modals, deep links; list every screen and its states.
4. **Build the app shell**: providers (theme, auth, query client, i18n, error boundary), navigation, safe areas, connectivity banner, snackbar host.
5. **Build shared components** with all states and accessibility props.
6. **Build screens** with loading / empty / error / offline / success states.
7. **Add validation, prevention, confirmation/undo, permission flows** (sections 8-9).
8. **Add offline cache, sync queue, retry, crash reporting**.
9. **Accessibility pass**: screen reader, font scale 200%, contrast both themes, touch targets.
10. **Device pass**: small phone (320dp), large phone, tablet, landscape, notch, keyboard open, dark/light switch live, slow network, airplane mode, app kill and restore.
11. **Run the checklist**; fix failures before delivering.

When delivering code, provide: folder structure, theme file, reusable components, example screens, API client, and run instructions. For single-screen prototypes in a chat/preview, build a phone-width (390x844) responsive mock with the same tokens and state handling.

---

## 14. Final Delivery Checklist

**Visual**
- [ ] No purple/violet/indigo/pink anywhere; no decorative gradients or glow
- [ ] Light and dark themes complete; follows system; manual override persists; status bar/nav bar/splash themed
- [ ] All colors/sizes from tokens; contrast 4.5:1 text, 3:1 UI in both themes
- [ ] 4dp spacing scale; 16dp screen padding; consistent radii and icon family
- [ ] Safe areas respected on notch/home-indicator devices

**Interaction**
- [ ] Touch targets at least 48dp/44pt with 8dp spacing
- [ ] Pressed/disabled/loading/selected/error states on all controls
- [ ] Primary actions in thumb zone; one primary action per screen
- [ ] Gestures have visible alternatives; no conflict with system gestures
- [ ] Platform-correct navigation and back behavior; deep links work; state restores
- [ ] Feedback within 100ms; skeletons for loading; haptics subtle and consistent
- [ ] Keyboard handling: correct types, next/done, field scrolls above keyboard, dismiss on scroll/tap

**Forms and prevention**
- [ ] Visible labels, helper text, correct keyboard/autofill, validation on blur/submit
- [ ] First invalid field focused; input never lost
- [ ] Double-tap/double-submit prevented; idempotency on payments and creates
- [ ] Undo or specific confirmation for destructive actions; re-auth for high risk
- [ ] Drafts auto-saved; unsaved-change warnings; restore after kill
- [ ] Permissions requested in context with rationale, denied-state handling, Settings link, fallback

**Errors and resilience**
- [ ] Every screen has loading, empty, error, offline, success states
- [ ] Messages follow what + why + next step; no raw technical text; reference ID for server errors
- [ ] Central API client with timeout, backoff retry, token refresh, normalized errors
- [ ] Offline banner, cached data, queued writes, sync status, "Last updated"
- [ ] Error boundary/global handlers, crash reporting, offline/maintenance/force-update screens
- [ ] Partial failures reported with retry for failed items

**Accessibility and responsive**
- [ ] Labels/roles/states on all elements; VoiceOver and TalkBack tested
- [ ] Font scale to 200% without clipping; Reduce Motion honored
- [ ] Works on 320dp to tablet, portrait and landscape; foldable/tablet two-pane where relevant

**Performance, security, release**
- [ ] Cold start and scroll performance targets met on a low-end device
- [ ] Tokens in Keychain/Keystore; TLS; no secrets in bundle; PII not logged
- [ ] Permissions and privacy declarations accurate; account deletion available
- [ ] No console/logcat errors, lorem ipsum, or placeholder content
- [ ] README with setup, theme tokens, architecture, and release steps

If an item doesn't apply, state why instead of silently skipping it.
