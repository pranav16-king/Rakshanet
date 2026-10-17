# Mobile Gestures & Haptic Feedback Reference

Fluid gestures and tactile haptic feedback elevate mobile applications from static displays into responsive, tangible physical tools.

---

## 1. Core Gesture Design Patterns

### 1.1 Swipe-to-Dismiss / Swipe-to-Action
- **Usage**: Deleting list items, archiving emails, dismissing modals or notifications.
- **Threshold**: Require at least 40% swipe distance or velocity > 500 pt/s to trigger the action automatically.
- **Visual Feedback**: Reveal underlying actions (red delete icon, green archive icon) progressively as the user drags.
- **Undoing**: Accompany destructive swipe actions with an immediate undo toast/snackbar (5-second display).

### 1.2 Pull-to-Refresh
- **Usage**: Feeds, notifications, dashboards, and live status pages.
- **Indicator**: Native spinner or subtle custom branding indicator appearing above the list header.
- **Threshold**: Drag distance of ~60–80pt before triggering the reload event.
- **Haptic**: Fire an impact haptic when the drag threshold is crossed so the user feels the release point.

### 1.3 Bottom Sheet Dragging & Snapping
- **Snap Points**: Standard snap positions: `['25%', '50%', '90%']`.
- **Velocity Tracking**: Calculate release velocity. If flicked upward, jump to the highest snap point; if flicked downward, dismiss or collapse.

---

## 2. Haptic Feedback Guidelines

Use device vibration motors (Taptic Engine on iOS, Linear Resonant Actuators on Android) purposefully. Overuse causes fatigue and annoyance.

| Interaction Type | Haptic Pattern | Example Use Case |
| :--- | :--- | :--- |
| **Light Impact** (`impactLight`) | Subtle tick | Toggling a switch, selecting a date picker wheel |
| **Medium Impact** (`impactMedium`) | Noticeable bump | Pull-to-refresh snap trigger, snapping sheet to breakpoint |
| **Heavy Impact** (`impactHeavy`) | Firm thump | Long-press context menu reveal, drag-and-drop pickup |
| **Success Notification** (`notificationSuccess`) | Double pulse (fast) | Payment approved, order placed successfully |
| **Warning Notification** (`notificationWarning`) | Short pulse + pause | Approaching maximum limit or non-blocking validation |
| **Error Notification** (`notificationError`) | Triple pulse (staccato) | Form submission failure, invalid passcode entry |

### Implementation Note (React Native / Expo):
```typescript
import * as Haptics from 'expo-haptics';

// On switch toggle:
Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);

// On payment confirmed:
Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
```
