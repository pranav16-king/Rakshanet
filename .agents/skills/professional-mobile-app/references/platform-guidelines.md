# Mobile Platform Guidelines: iOS (HIG) vs. Android (Material 3)

When building cross-platform applications, respect the distinct conventions and design languages of each ecosystem.

---

## 1. Core Platform Comparison

| Attribute | Apple iOS (Human Interface Guidelines) | Android (Material Design 3) |
| :--- | :--- | :--- |
| **Design Language** | Depth, translucency (blur/vibrancy), subtle gradients | Dynamic color (Material You), elevation, tonal surfaces |
| **Primary Navigation** | Bottom Tab Bar (labeled icons) | Navigation Bar (3-5 pill-shaped items) |
| **Back Navigation** | Interactive edge swipe left-to-right, `< Back` button top-left | System predictive back gesture, top-left back arrow |
| **Top Bar** | Navigation Bar with centered or large collapsible title | Top App Bar (left-aligned title with right action icons) |
| **Modal Presentation** | Card-style sheet presentation sliding up from bottom | Full-screen modal or Material bottom sheet |
| **Touch Target Size** | Minimum 44 × 44 pt | Minimum 48 × 48 dp |
| **Typography Scaling** | Dynamic Type (iOS system font SF Pro) | SP font scaling (Roboto / Google Sans) |
| **Action Sheet / Menu** | Native iOS ActionSheet dialog with cancel at bottom | Bottom Sheet / Floating popup menu |
| **Primary Action (CTA)**| Sticky full-width button pinned above home indicator | Floating Action Button (FAB) or bottom pinned button |

---

## 2. Safe Area Insets Handling

### iOS Safe Areas:
- **Top Inset**: Accounts for the sensor notch or Dynamic Island (`44pt` to `59pt`).
- **Bottom Inset**: Accounts for the home indicator bar (`34pt`). Interactive elements must never be obscured by this bar.

### Android System Bars:
- **Status Bar**: Transparent with proper contrast icons (`StatusBar.setBarStyle('dark-content' | 'light-content')`).
- **Gesture Navigation Bar**: Edge-to-edge transparent navigation bar (`0pt` to `48dp`). Handle window insets so content scrolls under the bar smoothly while buttons remain elevated above it.

---

## 3. Native Font Sizing Scales

### iOS Dynamic Type Scale:
- Large Title: `34pt` (Regular / Bold)
- Title 1: `28pt`
- Title 2: `22pt`
- Title 3: `20pt`
- Headline: `17pt` (Semibold)
- Body: `17pt` (Regular)
- Callout: `16pt`
- Subheadline: `15pt`
- Footnote: `13pt`
- Caption 1: `12pt`
- Caption 2: `11pt`

### Android Material 3 Scale:
- Display Large/Medium/Small: `57sp` / `45sp` / `36sp`
- Headline Large/Medium/Small: `32sp` / `28sp` / `24sp`
- Title Large/Medium/Small: `22sp` / `16sp` / `14sp`
- Body Large/Medium/Small: `16sp` / `14sp` / `12sp`
- Label Large/Medium/Small: `14sp` / `12sp` / `11sp`
