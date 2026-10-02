---
name: signalrescue-design
description: Use when creating or editing any UI for SignalRescue AI (React Native mobile app or React Command Center dashboard). Enforces the hi-vis beacon design system, tokens, accessibility, and emergency-specific UX rules.
---

# SignalRescue Design System & UI Guidelines

Guidelines for building and styling UI across the SignalRescue AI React Native mobile app and React Command Center dashboard.
For complete tokens, specs, typography, and component references, see [design.md](../../design.md).

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
