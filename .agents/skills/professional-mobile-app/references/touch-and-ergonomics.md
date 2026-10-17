# Mobile Touch Targets & Thumb-Zone Ergonomics

Mobile devices are held in one hand over 75% of the time. Interface layouts must be optimized for natural thumb sweep arcs and one-handed reachability.

---

## 1. The Thumb Zone Architecture

```text
+-----------------------+
|   HARD TO REACH ZONE  |  <-- Infrequent / Destructive actions
| (Top 25% of viewport) |      (e.g., Settings icon, Back button, Close icon)
+-----------------------+
|      STRETCH ZONE     |  <-- Informational content & secondary items
| (Mid 35% of viewport) |      (e.g., Content cards, reading body, media)
+-----------------------+
|   NATURAL THUMB ZONE  |  <-- Frequent & Primary interactive controls
| (Bottom 40% viewport) |      (e.g., Bottom tab bar, Primary CTAs, Sheet handles)
+-----------------------+
```

### Design Rules:
1. **Never place critical primary CTAs exclusively in the top navigation bar.** Pin sticky bottom action buttons above the safe area instead.
2. **Bottom Sheet instead of Top Menus**: Use bottom sheets for filters, options, and sorting rather than dropdown menus pinned to the top right.
3. **Floating Controls**: Position floating buttons within the bottom-right or bottom-center thumb reach area.

---

## 2. Touch Hit Targets & Spacing

### Minimum Hit Target Standards:
- **iOS Human Interface Guidelines**: **44 × 44 pt** minimum.
- **Android Material Design**: **48 × 48 dp** minimum.
- **Touch Separation**: Minimum **8 pt / 8 dp** spacing between adjacent clickable targets to prevent accidental taps.

### Expanding Hit Areas with Hit Slop:
When visual design dictates a small icon (e.g., 20 × 20 pt), expand the touch target using hit slop without altering the visual layout:

```tsx
// React Native Hit Slop
<TouchableOpacity
  hitSlop={{ top: 12, bottom: 12, left: 12, right: 12 }}
  onPress={handleDismiss}
  accessibilityRole="button"
  accessibilityLabel="Dismiss dialog"
>
  <CloseIcon width={20} height={20} />
</TouchableOpacity>
```

---

## 3. One-Handed Reachability Checklist

- [ ] Primary navigation reachable without shifting grip (Bottom Navigation Bar).
- [ ] Confirmation and Submit buttons placed in the lower third of the screen.
- [ ] Destructive actions (e.g., "Delete Account", "Clear All") placed out of accidental thumb reach or protected by secondary confirmation sheets.
- [ ] Horizontal carousels support smooth edge-to-edge flicking.
- [ ] Safe area insets respected so controls do not overlap home indicator or sensor housing.
