# Universal UI & UX Engineering Standards

These rules enforce high visual quality, accessibility, responsiveness, and consistent user experience across both Web and Mobile platforms.

---

## 1. Visual Hierarchy & Design System Consistency

- **Tokens Over Hardcoded Values**:
  - Never scatter magic numbers or arbitrary color hex codes across components.
  - Always utilize design tokens for:
    - Colors (`primary`, `secondary`, `neutral`, `surface`, `accent`, `destructive`)
    - Spacing scale (`2xs: 4px`, `xs: 8px`, `sm: 12px`, `md: 16px`, `lg: 24px`, `xl: 32px`, `2xl: 48px`)
    - Typography scale (`font-size`, `line-height`, `font-weight`)
    - Border radius (`sm: 4px`, `md: 8px`, `lg: 12px`, `full: 9999px`)
    - Elevation & Shadows (`elevation-1`, `elevation-2`, etc.)
- **Intentional Contrast**:
  - Ensure all text-to-background contrast ratios strictly meet WCAG 2.1 AA standards:
    - Normal text: at least **4.5:1**
    - Large text (18pt+ or 14pt+ bold): at least **3.0:1**
    - UI components and graphical objects: at least **3.0:1**

---

## 2. Accessibility (a11y) First

- **Semantic Structure**:
  - Web: Use semantic HTML5 elements (`<header>`, `<nav>`, `<main>`, `<article>`, `<aside>`, `<footer>`, `<button>`, `<input>`). Never use a `<div>` or `<span>` with an `onClick` where a native `<button>` or `<a>` is appropriate.
  - Mobile: Set proper accessibility roles, accessibility labels, and hints (`accessibilityRole="button"`, `accessibilityLabel="Close dialog"`).
- **Keyboard & Screen Reader Navigability**:
  - Ensure all interactive elements are focusable in a logical tab order.
  - Provide visible, high-contrast focus rings (`:focus-visible`). Never remove focus outlines without a customized replacement.
- **Motion & Reduced Motion**:
  - Respect user motion preferences (`prefers-reduced-motion` on Web, `AccessibilityInfo.isReduceMotionEnabled` on Mobile).
  - Disable or tone down looping/large animations when reduced motion is enabled.

---

## 3. Comprehensive State Coverage

Every UI component that fetches data or accepts input must explicitly account for all 5 fundamental states:
1. **Initial / Idle State**: Clean baseline presentation.
2. **Loading State**: Content-shaped skeleton loaders or subtle spinners. Never show blank layout shifts.
3. **Empty State**: Friendly illustration or icon, helpful title, explanatory copy, and a clear call-to-action (CTA).
4. **Error State**: Non-technical, human-friendly message, retry action button, and clear guidance on resolution.
5. **Success / Active State**: Smooth transition to loaded data, confirmation toasts or micro-feedback.

---

## 4. Responsiveness & Adaptive Design

- Design and implement **mobile-first**, progressively enhancing for tablet, desktop, and ultra-wide displays.
- Avoid horizontal scrollbars on viewports down to 320px width.
- Support Dark Mode and Light Mode natively using CSS variables or theme providers.
- Maintain adequate touch targets:
  - Minimum **44x44 pt** on iOS
  - Minimum **48x48 dp** on Android
  - Minimum **44x44 px** on Web for touch interfaces
