# SignalRescue AI — design.md

Design system for the **mobile app (React Native, Android-first)** and the **Command Center (React web dashboard)**.
Includes a **Design Skill** (Section 16) that any AI coding agent or teammate can follow to keep new screens consistent.

---

## 1. Design Direction

**Subject:** a disaster communication app used by stressed people with a dying battery, wet hands, and sunlight or darkness. A separate dashboard is used by rescue coordinators making fast decisions.

**Concept: "Hi-vis beacon."** The identity borrows from rescue gear: safety-vest yellow, signal red, and deep night navy. Yellow means *"this app is alive and ready."* Red is reserved for *SOS and critical danger only*. Teal/blue means *connection*.

**Principles**

1. **One action dominates.** On the phone the SOS button is the loudest object on screen. Everything else stays quiet.
2. **Status is always visible.** Mesh, Internet, GPS, and battery are shown on every main screen. The user should never wonder whether a message left the phone.
3. **Never rely on colour alone.** Every status has an icon and a text label as well as a colour.
4. **Big, forgiving targets.** Minimum 48 dp, 56 dp for primary actions, spacing that works with gloves and shaking hands.
5. **Show the why.** AI outputs (priority, search zone) always display their factors and confidence. No black-box scores.
6. **Dark mode saves battery** on OLED phones. Offer it as a one-tap "Low power" theme as well as a system setting.

---

## 2. Colour System

### 2.1 Brand core (same in both themes)

| Token | Hex | Meaning |
|---|---|---|
| `brand.signalYellow` | `#FFC400` | Hi-vis brand colour, "ready", primary actions |
| `brand.sosRed` | `#D92D20` | SOS and critical only |
| `brand.beaconTeal` | `#0E8A94` | Mesh connected, relay, links |
| `brand.nightNavy` | `#0B1220` | Dark base, text on yellow surfaces |

### 2.2 Light theme (warm, yellow-tinted)

| Role | Token | Hex | Notes |
|---|---|---|---|
| Background | `bg` | `#FFFCEB` | Pale hi-vis tint |
| Background raised | `bgAlt` | `#FFF5C2` | Banners, highlighted rows |
| Surface (cards) | `surface` | `#FFFFFF` | |
| Surface sunken | `surfaceSunken` | `#F6F0D4` | Inputs, chat bubbles (received) |
| Border | `border` | `#E6DCA8` | |
| Border strong | `borderStrong` | `#C9BB6E` | Focus-adjacent, dividers on yellow |
| Text primary | `text` | `#16202D` | 15.9:1 on `bg` |
| Text secondary | `textMuted` | `#566070` | 6.3:1 on `bg` |
| Text disabled | `textDisabled` | `#9AA1AB` | |
| Text on yellow | `onPrimary` | `#1A1400` | 12:1 on `#FFC400` |
| Primary | `primary` | `#FFC400` | Buttons, active tab indicator |
| Primary pressed | `primaryPressed` | `#E0AA00` | |
| Primary tint | `primarySoft` | `#FFEFA6` | Chips, selected rows |
| Yellow text / icon on light | `primaryInk` | `#8A5A00` | Yellow-family text that passes 4.5:1 |
| SOS | `sos` | `#D92D20` | White text 5.2:1 |
| SOS pressed | `sosPressed` | `#B42318` | |
| SOS tint | `sosSoft` | `#FDE2DF` | |
| Mesh / info | `info` | `#0E8A94` | |
| Info tint | `infoSoft` | `#D6F1F3` | |
| Success (delivered) | `success` | `#1E8E4E` | |
| Success tint | `successSoft` | `#D9F2E3` | |
| Warning | `warning` | `#E07B00` | |
| Warning tint | `warningSoft` | `#FFE6C7` | |
| Overlay scrim | `scrim` | `rgba(22,32,45,0.48)` | |

### 2.3 Dark theme (night navy, yellow stays the hero)

| Role | Token | Hex | Notes |
|---|---|---|---|
| Background | `bg` | `#0B1220` | Near-OLED, slight blue |
| Background raised | `bgAlt` | `#111A2C` | |
| Surface (cards) | `surface` | `#162036` | |
| Surface sunken | `surfaceSunken` | `#0E1627` | Inputs |
| Border | `border` | `#26344F` | |
| Border strong | `borderStrong` | `#3A4C70` | |
| Text primary | `text` | `#EEF2F8` | 15.4:1 on `bg` |
| Text secondary | `textMuted` | `#9FADC2` | 7.9:1 |
| Text disabled | `textDisabled` | `#5F6E86` | |
| Text on yellow | `onPrimary` | `#1A1400` | |
| Primary | `primary` | `#FFD21F` | Slightly brighter for dark |
| Primary pressed | `primaryPressed` | `#E6B800` | |
| Primary tint | `primarySoft` | `#3A3010` | Selected rows |
| Yellow text / icon on dark | `primaryInk` | `#FFD21F` | |
| SOS | `sos` | `#FF5A4E` | Brighter for dark. Use `#1A0503` text if filled, or white on `#D92D20` for the main SOS button |
| SOS pressed | `sosPressed` | `#E0463B` | |
| SOS tint | `sosSoft` | `#3A1512` | |
| Mesh / info | `info` | `#3CC6D0` | |
| Info tint | `infoSoft` | `#0F3037` | |
| Success | `success` | `#4CD08A` | |
| Success tint | `successSoft` | `#0F3322` | |
| Warning | `warning` | `#FFA033` | |
| Warning tint | `warningSoft` | `#3A2508` | |
| Overlay scrim | `scrim` | `rgba(0,0,0,0.64)` | |

> The main SOS button uses `#D92D20` with white text in **both** themes so it is instantly recognisable.

### 2.4 Severity scale (incidents, map pins, dashboard)

| Level | Light | Dark | Icon | Label |
|---|---|---|---|---|
| CRITICAL | `#D92D20` | `#FF5A4E` | `alert-octagon` | Critical |
| HIGH | `#E07B00` | `#FFA033` | `alert-triangle` | High |
| MEDIUM | `#C99A00` | `#FFD21F` | `alert-circle` | Medium |
| LOW | `#1E8E4E` | `#4CD08A` | `check-circle` | Low |
| UNKNOWN | `#566070` | `#9FADC2` | `help-circle` | Unknown |

Each level also has a 12% tint of its colour for row backgrounds.

### 2.5 Connectivity and message status

| State | Colour token | Icon | Text |
|---|---|---|---|
| Mesh connected | `info` | `radio` | Mesh connected |
| Mesh searching | `warning` | `radio` (pulsing) | Searching for devices |
| Mesh off | `textMuted` | `radio-off` | Mesh off |
| Internet online | `success` | `wifi` | Online |
| Internet offline | `textMuted` | `wifi-off` | Offline |
| GPS fix | `success` | `map-pin` | GPS good |
| GPS last known | `warning` | `map-pin-off` | Last known location |
| Message queued | `textMuted` | `clock` | Saved on this phone |
| Message relayed | `info` | `share-2` | Relayed by N devices |
| Message delivered to server | `success` | `check-check` | Reached rescue team |
| Message failed | `sos` | `x-circle` | Not sent. Retrying |

### 2.6 Map layer colours

| Layer | Colour (light / dark) | Shape |
|---|---|---|
| SOS pin | `#D92D20` / `#FF5A4E` | Filled circle with pulse ring |
| Device cluster | `#0E8A94` / `#3CC6D0` | Circle, size by count |
| Search zone | `#FFC400` @ 28% fill, 2 px dashed edge | Circle or polygon |
| Communication gap | `#7A4DD8` / `#A98BFF` @ 25% fill | Hatched polygon |
| Flood extent | `#2F6FDE` / `#6C9DFF` @ 30% fill | Polygon |
| Rescue team | `#1E8E4E` / `#4CD08A` | Rounded square |
| Shelter | `#0E8A94` | House icon |
| Hospital | `#D92D20` | Cross icon |
| Hazard | `#E07B00` | Triangle |
| Blocked road | `#D92D20` dashed line | |

---

## 3. Typography

| Role | Family | Fallback |
|---|---|---|
| Display / headings / big numbers | **Barlow Semi Condensed** (600, 700) | `sans-serif-condensed`, system |
| Body / UI | **Atkinson Hyperlegible** (400, 700) | `sans-serif`, system |
| IDs, coordinates, timestamps | **JetBrains Mono** (500) | `monospace` |

Atkinson Hyperlegible was designed for low-vision readers, which suits stress and poor light. Bundle all fonts locally so they work offline.

### 3.1 Mobile type scale (sp, scales with system font size)

| Style | Size / line height | Weight | Use |
|---|---|---|---|
| `display` | 40 / 44 | Barlow 700 | Counts, "SOS SENT" |
| `h1` | 28 / 34 | Barlow 700 | Screen titles |
| `h2` | 22 / 28 | Barlow 600 | Section titles |
| `h3` | 18 / 24 | Atkinson 700 | Card titles |
| `body` | 16 / 24 | Atkinson 400 | Default text |
| `bodyStrong` | 16 / 24 | Atkinson 700 | |
| `caption` | 14 / 20 | Atkinson 400 | Secondary info |
| `micro` | 12 / 16 | Atkinson 700 | Badges only. Never for essential info |
| `button` | 17 / 22 | Atkinson 700 | |
| `mono` | 14 / 20 | JetBrains Mono 500 | Device ID `SR-8F31-A72C` |

Rules: body never below 16 sp. Sentence case everywhere, with no all-caps labels. Line length under 70 characters. Support up to 200% font scaling without clipping (use `minHeight`, never fixed heights on text containers).

### 3.2 Dashboard type scale (px, desktop)

| Style | Size / line height | Weight |
|---|---|---|
| `stat` | 48 / 52 | 700 |
| `h1` | 32 / 40 | 700 |
| `h2` | 24 / 32 | 600 |
| `h3` | 18 / 26 | 700 |
| `body` | 15 / 22 | 400 |
| `table` | 14 / 20 | 400 |
| `caption` | 13 / 18 | 400 |

---

## 4. Spacing, Sizing and Shape

### 4.1 Spacing scale (4-point grid)

| Token | dp / px |
|---|---|
| `space.1` | 4 |
| `space.2` | 8 |
| `space.3` | 12 |
| `space.4` | 16 |
| `space.5` | 20 |
| `space.6` | 24 |
| `space.8` | 32 |
| `space.10` | 40 |
| `space.12` | 48 |
| `space.16` | 64 |

Screen horizontal padding: **16** (phone), **24** (tablet). Gap between cards: **12**. Inside cards: **16**.

### 4.2 Radii (different per role, not one radius for everything)

| Token | Value | Use |
|---|---|---|
| `radius.xs` | 4 | Badges, tags |
| `radius.sm` | 8 | Inputs, chips |
| `radius.md` | 12 | Cards, list rows |
| `radius.lg` | 20 | Bottom sheets, modals |
| `radius.pill` | 999 | Status pills, segmented control |
| `radius.round` | 50% | SOS button, avatars, map pins |

### 4.3 Touch targets and component sizes (dp)

| Element | Size |
|---|---|
| Minimum touch target | **48 × 48** |
| Primary button | height **56**, min width 120, full width on phone |
| Secondary button | height 48 |
| Icon button | 48 × 48 (icon 24) |
| Text input | height 52 |
| List row | min height 64 (72 with avatar) |
| Bottom tab bar | height 64 + safe area |
| Top app bar | height 56 |
| Status strip (Mesh / Internet / GPS) | height 40 |
| Chat bubble | max width 80% of screen, padding 12 × 16 |
| **SOS button (Home)** | **176 × 176 circle** (min 144 on small screens) |
| **SOS button (SOS screen)** | **min(280, 70% screen width) circle** |
| Avatar | 40 (list), 56 (profile) |
| Bottom sheet handle | 40 × 4 |
| Map marker | 32 (pin), 44 (selected), 56+ (cluster, grows with count) |

### 4.4 Icon sizes

| Token | Size | Use |
|---|---|---|
| `icon.sm` | 16 | Inline with caption |
| `icon.md` | 24 | Default |
| `icon.lg` | 32 | Status cards |
| `icon.xl` | 48 | Empty states |
| `icon.hero` | 64 | Onboarding, SOS states |

Icon set: **Lucide** (line, 2 px stroke, round caps) via `lucide-react-native` and `lucide-react`. One icon family only. Emoji are for the wireframes only, not production.

### 4.5 Elevation

| Level | Light | Dark | Use |
|---|---|---|---|
| 0 | none | none | Flat rows |
| 1 | `0 1 2 rgba(22,32,45,.10)` | border only | Cards |
| 2 | `0 4 12 rgba(22,32,45,.14)` | surface step up | Sheets, FAB |
| 3 | `0 8 24 rgba(22,32,45,.20)` | surface step up | Modals |

In dark mode prefer a lighter surface and a border over shadows.

### 4.6 Breakpoints (dashboard)

| Name | Width | Layout |
|---|---|---|
| `sm` | < 768 | Single column, tabs |
| `md` | 768 to 1279 | Map plus collapsible side panel |
| `lg` | ≥ 1280 | Three zones: left nav 72, map flexible, right panel 400 |
| `xl` | ≥ 1920 | Wall-display mode: type scale +25% |

---

## 5. Motion

| Moment | Spec |
|---|---|
| Press feedback | Scale to 0.97, 100 ms, haptic light |
| SOS press-and-hold | Ring fills over **1.5 s** with haptic ticks, release before completion cancels. Prevents accidental sends |
| SOS sent | One confirmation animation (ring to check), 400 ms, strong haptic |
| Mesh searching | Slow pulse on the radio icon, 1.6 s loop |
| Status change | Cross-fade 200 ms |
| Sheet open / close | 250 ms, ease-out |
| Map pin new SOS (dashboard) | One pulse ring, 1.2 s, then static |

Respect `reduce motion`: replace pulses with static state and colour. No decorative entrance animations.

---

## 6. Layout and Navigation (Mobile)

Bottom tabs (5): **Home, Chat, Map, Network, More**.
SOS is reachable from Home (big button) and from a persistent red **SOS** chip in the top bar on every other screen.

```text
┌─────────────────────────────┐
│ ● Mesh 6   ○ Offline   ◉ GPS │  Status strip (40)
├─────────────────────────────┤
│  App bar (56)               │
│                             │
│  Content (16 padding)       │
│                             │
├─────────────────────────────┤
│ Home Chat Map Network More  │  Tab bar (64)
└─────────────────────────────┘
```

Alignment: left-aligned text and content. Centre only the SOS button, onboarding illustrations, and big status messages.

---

## 7. Screen Specs (10 screens)

### 7.1 Onboarding
- Yellow `bg` (light) or navy (dark), large `h1` "Be reachable when networks fail."
- One supporting sentence: "SignalRescue passes your SOS from phone to phone until it reaches rescuers."
- Primary button: **Turn on emergency mode**.
- Secondary link: "How it works" (3 simple steps).

### 7.2 Permissions
Four rows, each with icon, plain reason, and state toggle: **Location** ("so rescuers can find you"), **Nearby devices**, **Bluetooth**, **Notifications**. Row min height 72. Button: **Allow and continue**. Show what happens if denied.

### 7.3 Home
```text
┌─────────────────────────────┐
│ ● Network ready             │ Hero status card (info tint)
│ 6 devices nearby            │
│ Mesh connected · Offline    │
│                             │
│          ┌───────┐          │
│          │  SOS  │  176 dp  │
│          └───────┘          │
│    Hold for 1.5 s to send   │
│                             │
│ Last message: Delivered ✓   │
└─────────────────────────────┘
```

### 7.4 Offline chat
Conversation list (nearby people, relayed groups). Chat bubbles: sent = `primarySoft` with `text`; received = `surfaceSunken`. Under each sent message show a status icon (queued, relayed, delivered). Quick replies: "I'm safe", "Need water", "Need medical help", "Trapped".

### 7.5 SOS
1. **Select**: number of people stepper (large + / −), situation chips (Trapped, Injured, Flooding, Fire, Need evacuation), optional text.
2. **Hold to send** (red circle, ring fill).
3. **Sent**: "SOS saved and sending". Shows the live status timeline (7.8).

### 7.6 My location (offline map)
Full-bleed MapLibre map, blue dot or amber "last known" circle with accuracy radius, floating buttons (re-centre, layers), bottom sheet with coordinates in mono, accuracy, and "Share location".

### 7.7 Nearby network
List rows: device nickname or ID (mono), distance band ("about 15 m"), link icon (BLE / Wi-Fi), relay badge. Top summary: devices, relay capacity, last Internet-connected device seen.

### 7.8 Emergency status (timeline)
Vertical stepper, each step with icon, time, and state:
1. SOS saved on this phone
2. Received by nearby device
3. Relayed (N hops)
4. Reached rescue team

Done = success colour, current = primary with pulse, pending = muted.

### 7.9 Shelter
List plus map toggle. Row: name, type icon, distance, capacity bar (success / warning / sos), "Last updated 2 h ago" (data is cached and may be old, so always show its age).

### 7.10 Settings
Sections: Communication mode (Auto / Bluetooth only / Save battery), Privacy (what is shared), Emergency profile (name, blood group, medical notes, emergency contact), Appearance (Light, Dark, System, Low power), Language, Data and storage.

---

## 8. Command Center (Dashboard) Layout

```text
┌────┬──────────────────────────────────────────────┬────────────────────┐
│ nav│ Top bar: Zone filter · Time range · Alerts   │                    │
│ 72 ├──────────────────────────────────────────────┤  Right panel (400) │
│    │ KPI row (4 cards, 96 high)                   │  Incident details  │
│    │ Critical 42 · High 91 · Affected 1,248 ·     │  or Incident list  │
│    │ Comm gaps 3                                  │                    │
│    ├──────────────────────────────────────────────┤  Priority factors  │
│    │                                              │  Relay path        │
│    │                 LIVE MAP                     │  AI confidence     │
│    │                                              │  Assign team       │
│    │                                              │                    │
│    ├──────────────────────────────────────────────┴────────────────────┤
│    │ Bottom drawer: Incidents table / Rescue teams / Resources (tabs)   │
└────┴────────────────────────────────────────────────────────────────────┘
```

- Left nav: Overview, Map, Incidents, Rescue ops, Comm gaps, Settings (icons with tooltips).
- Incident table columns: Severity, Incident, People, Location, Last update, Assigned team, Status.
- Table row height 48. Severity cell uses icon plus label plus tint.
- **Explainability panel** (required): lists each factor and its weight, for example "Last contact 24 min ago · Flood boundary expanding · 12 devices in cluster", with a confidence percentage and an "Estimate, not exact" label on search zones.
- Dashboard defaults to dark for control-room use. Light theme available.

---

## 9. Core Components

| Component | Variants / states |
|---|---|
| `Button` | primary (yellow), danger (red), secondary (outline), ghost; default, pressed, disabled, loading |
| `SosButton` | idle, holding (ring progress), sending, sent, failed |
| `StatusStrip` | mesh, internet, GPS, battery items |
| `StatusPill` | info, success, warning, danger, neutral. Icon plus text |
| `Card` | default, highlighted (`bgAlt`), alert (left border 4 px in status colour) |
| `ListRow` | leading icon/avatar, title, subtitle, trailing meta |
| `ChatBubble` | sent, received, system, with delivery state |
| `Timeline` | done, current, pending, failed |
| `Stepper` | count selector with 56 dp buttons |
| `Chip` | selectable, 40 high, min 48 touch area |
| `BottomSheet` | peek 120, half 50%, full |
| `Banner` | info, warning, danger. Persistent, never auto-dismiss for critical |
| `Toast` | 4 s, bottom, above tab bar |
| `MapMarker` | sos, cluster, team, shelter, hospital, hazard |
| `ConfidenceMeter` | 0–100% with text value |
| `EmptyState` | icon 48, one sentence, one action |

Focus ring: 3 px `primary` outline plus 2 px offset (keyboard, switch access, dashboard).

---

## 10. Content and Voice

- Plain, short, calm. Active verbs. Sentence case.
- Buttons say what happens: **Send SOS**, **Share location**, **Assign team**.
- Same word across the flow: "Send SOS" gives "SOS sent".
- Errors say what happened and what to do: "No GPS signal. Sending your last known location from 10:42."
- Empty states are invitations: "No devices nearby yet. Stay in this area, the network will keep searching."
- Never promise rescue. Say "Your SOS has reached the rescue team" rather than "Help is coming".
- Support English, Hindi, Marathi at launch. Allow +30% text expansion.

---

## 11. Accessibility

- Contrast ≥ 4.5:1 for text, ≥ 3:1 for icons and UI boundaries (values above are checked for the pairings listed).
- Yellow is never used as text on light backgrounds. Use `primaryInk` `#8A5A00`.
- Screen reader labels on every control, for example "Send SOS. Hold for one and a half seconds."
- Hold-to-send has an alternative: double-tap then confirm dialog for TalkBack users.
- Haptics and optional sound for sent, delivered, failed.
- Colour-blind safe: severity differs by icon shape and label as well as colour.
- High-contrast mode: raise borders to `borderStrong`, remove tinted fills.

---

## 12. Battery and Low-Connectivity Design

- **Low power theme:** pure `#000000` background, no animations, map in simplified style, reduced scan rate.
- Show battery in the status strip. Warn at 20% and offer Low power mode.
- All assets and fonts bundled. No remote images in the app.
- Lists virtualised. Map tiles stored locally. Show tile age.
- Show "Saved on this phone" immediately on any action so the user knows it will not be lost.

---

## 13. Design Tokens (TypeScript)

```ts
// theme/tokens.ts
export const brand = {
  signalYellow: '#FFC400',
  sosRed: '#D92D20',
  beaconTeal: '#0E8A94',
  nightNavy: '#0B1220',
};

export const light = {
  bg: '#FFFCEB', bgAlt: '#FFF5C2', surface: '#FFFFFF', surfaceSunken: '#F6F0D4',
  border: '#E6DCA8', borderStrong: '#C9BB6E',
  text: '#16202D', textMuted: '#566070', textDisabled: '#9AA1AB',
  primary: '#FFC400', primaryPressed: '#E0AA00', primarySoft: '#FFEFA6',
  primaryInk: '#8A5A00', onPrimary: '#1A1400',
  sos: '#D92D20', sosPressed: '#B42318', sosSoft: '#FDE2DF',
  info: '#0E8A94', infoSoft: '#D6F1F3',
  success: '#1E8E4E', successSoft: '#D9F2E3',
  warning: '#E07B00', warningSoft: '#FFE6C7',
  scrim: 'rgba(22,32,45,0.48)',
};

export const dark: typeof light = {
  bg: '#0B1220', bgAlt: '#111A2C', surface: '#162036', surfaceSunken: '#0E1627',
  border: '#26344F', borderStrong: '#3A4C70',
  text: '#EEF2F8', textMuted: '#9FADC2', textDisabled: '#5F6E86',
  primary: '#FFD21F', primaryPressed: '#E6B800', primarySoft: '#3A3010',
  primaryInk: '#FFD21F', onPrimary: '#1A1400',
  sos: '#FF5A4E', sosPressed: '#E0463B', sosSoft: '#3A1512',
  info: '#3CC6D0', infoSoft: '#0F3037',
  success: '#4CD08A', successSoft: '#0F3322',
  warning: '#FFA033', warningSoft: '#3A2508',
  scrim: 'rgba(0,0,0,0.64)',
};

export const lowPower: typeof dark = { ...dark, bg: '#000000', bgAlt: '#000000', surfaceSunken: '#000000' };

export const severity = {
  light: { CRITICAL: '#D92D20', HIGH: '#E07B00', MEDIUM: '#C99A00', LOW: '#1E8E4E', UNKNOWN: '#566070' },
  dark:  { CRITICAL: '#FF5A4E', HIGH: '#FFA033', MEDIUM: '#FFD21F', LOW: '#4CD08A', UNKNOWN: '#9FADC2' },
};

export const space = { 1: 4, 2: 8, 3: 12, 4: 16, 5: 20, 6: 24, 8: 32, 10: 40, 12: 48, 16: 64 };
export const radius = { xs: 4, sm: 8, md: 12, lg: 20, pill: 999 };
export const size = {
  touchMin: 48, buttonPrimary: 56, input: 52, row: 64, tabBar: 64, appBar: 56,
  statusStrip: 40, sosHome: 176, sosScreenMax: 280, icon: { sm: 16, md: 24, lg: 32, xl: 48, hero: 64 },
};
export const type = {
  display: { fontSize: 40, lineHeight: 44, fontFamily: 'BarlowSemiCondensed-Bold' },
  h1:      { fontSize: 28, lineHeight: 34, fontFamily: 'BarlowSemiCondensed-Bold' },
  h2:      { fontSize: 22, lineHeight: 28, fontFamily: 'BarlowSemiCondensed-SemiBold' },
  h3:      { fontSize: 18, lineHeight: 24, fontFamily: 'AtkinsonHyperlegible-Bold' },
  body:    { fontSize: 16, lineHeight: 24, fontFamily: 'AtkinsonHyperlegible-Regular' },
  caption: { fontSize: 14, lineHeight: 20, fontFamily: 'AtkinsonHyperlegible-Regular' },
  micro:   { fontSize: 12, lineHeight: 16, fontFamily: 'AtkinsonHyperlegible-Bold' },
  mono:    { fontSize: 14, lineHeight: 20, fontFamily: 'JetBrainsMono-Medium' },
};
```

CSS variables for the dashboard follow the same names, for example `--color-bg`, `--color-primary`, redefined under `[data-theme="dark"]` and `@media (prefers-color-scheme: dark)`.

---

## 14. Representation Guidelines (data to visuals)

| Data | Representation |
|---|---|
| Relay path | Dotted line A → B → C → server with hop icons and times |
| Hop count | "Relayed by 2 devices" with small chain icon |
| Distance | Bands ("about 15 m"), never fake precision |
| Location uncertainty | Circle of accuracy radius. Dashed if estimated or last known |
| Search zone | Dashed yellow circle plus confidence badge and factor list |
| Incident cluster | One pin with count, expands to individual SOS on zoom |
| Communication gap | Hatched purple area plus before and after device count sparkline |
| Time since contact | Relative ("24 min ago") with exact time on tap, mono |
| Priority | Pill with icon, plus top 3 factors |
| Sync state | Check icons: one grey (saved), one blue (relayed), double green (delivered) |

---

## 15. Light vs Dark Quick Preview

```text
LIGHT                               DARK
bg        #FFFCEB  ▇▇▇             bg        #0B1220  ▇▇▇
surface   #FFFFFF  ▇▇▇             surface   #162036  ▇▇▇
primary   #FFC400  ▇▇▇             primary   #FFD21F  ▇▇▇
sos       #D92D20  ▇▇▇             sos       #FF5A4E  ▇▇▇
info      #0E8A94  ▇▇▇             info      #3CC6D0  ▇▇▇
text      #16202D  ▇▇▇             text      #EEF2F8  ▇▇▇
```

---

## 16. Design Skill (for AI agents and contributors)

```yaml
---
name: signalrescue-design
description: Use when creating or editing any UI for SignalRescue AI (React Native mobile app or React Command Center dashboard). Enforces the hi-vis beacon design system, tokens, accessibility, and emergency-specific UX rules.
---
```

### When to apply
Any new screen, component, state, empty state, error message, map layer, or dashboard widget in this project.

### Always
1. **Import tokens** from `theme/tokens.ts` (or CSS variables). Never hard-code hex values, sizes, or font sizes in components.
2. **Support light, dark, and low-power** from the first commit. Test all three.
3. **Reserve red** (`sos`) for SOS and critical severity. Do not use red for generic errors on non-critical items (use `warning`) or for decoration.
4. **Use yellow** (`primary`) for the main action and "ready" states. On light backgrounds use `primaryInk` for yellow-family text.
5. **Pair colour with icon and text** for every status.
6. **Touch targets ≥ 48 dp**, primary actions 56 dp. Keep 8 dp minimum between adjacent targets.
7. **Body text ≥ 16 sp**, sentence case, no all-caps labels, scalable up to 200%.
8. **Show system state**: mesh, internet, GPS, battery visible on main screens. Every user action immediately shows "Saved on this phone".
9. **Show the age** of any cached data (maps, shelters, locations).
10. **Show uncertainty**: estimated locations use dashed styles, accuracy radius, and wording like "about" or "estimated".
11. **Explain AI**: any AI-derived label (priority, cluster, search zone) must show factors and confidence.
12. **Prevent accidental SOS** with hold-to-send (1.5 s) and a TalkBack alternative. Never prevent a *deliberate* SOS with extra steps beyond that.
13. **Work offline**: bundle fonts, icons, and map styles. No remote assets.
14. **Respect reduce motion**. Use motion only for press feedback, SOS progress and confirmation, and new-SOS pulse on the dashboard.

### Never
- Do not add decorative gradients, glassmorphism, or illustration-heavy hero sections.
- Do not use one radius for everything. Follow the radius roles.
- Do not use more than one icon family (Lucide only).
- Do not show raw device IDs to other users. IDs appear only in mono in the Network and debug views.
- Do not show precise personal data (medical notes, exact location) in lists visible to nearby phones. Details open only on authorised views.
- Do not use marketing language in emergency flows.

### Screen checklist
- [ ] Uses tokens only
- [ ] Light, dark, low-power checked
- [ ] Contrast checked, no yellow text on light
- [ ] 48 dp targets, 200% font scale OK
- [ ] Status visible (mesh / internet / GPS)
- [ ] Offline, loading, empty, and error states designed
- [ ] Screen-reader labels added
- [ ] AI outputs show factors and confidence
- [ ] Copy is plain, active, consistent

### Component recipe (React Native example)

```tsx
import { Pressable, Text } from 'react-native';
import { useTheme } from '@/theme';

export function PrimaryButton({ label, onPress, disabled }: Props) {
  const { c, size, radius, type } = useTheme();
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={label}
      onPress={onPress}
      disabled={disabled}
      style={({ pressed }) => ({
        minHeight: size.buttonPrimary,
        borderRadius: radius.md,
        paddingHorizontal: 24,
        alignItems: 'center',
        justifyContent: 'center',
        backgroundColor: disabled ? c.border : pressed ? c.primaryPressed : c.primary,
        transform: [{ scale: pressed ? 0.97 : 1 }],
      })}
    >
      <Text style={[type.h3, { color: c.onPrimary }]}>{label}</Text>
    </Pressable>
  );
}
```

---

## 17. Suggested File Structure

```text
/theme
  tokens.ts
  ThemeProvider.tsx
  useTheme.ts
/components
  Button/ SosButton/ StatusStrip/ StatusPill/ Card/ ListRow/
  ChatBubble/ Timeline/ BottomSheet/ Banner/ MapMarker/ ConfidenceMeter/
/screens
  Onboarding/ Permissions/ Home/ Chat/ Sos/ Map/ Network/ Status/ Shelter/ Settings/
/assets
  fonts/ (Barlow Semi Condensed, Atkinson Hyperlegible, JetBrains Mono)
/dashboard
  styles/tokens.css
  components/ ...
```
