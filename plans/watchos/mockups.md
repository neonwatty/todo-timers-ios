# watchOS App - UI Mockups

## Overview

These ASCII mockups illustrate the complete Apple Watch app user interface. The design follows watchOS Human Interface Guidelines, optimized for small screen, glanceable information, and Digital Crown navigation.

---

## Screen Sizes Reference

Apple Watch comes in various sizes:
- **41mm**: 176 x 215 pixels
- **45mm**: 198 x 242 pixels
- **49mm**: 205 x 251 pixels (Ultra)

Mockups represent approximate layout, not pixel-perfect dimensions.

---

## 1. Timer List View (Main Screen)

### Default State (With Timers)

```
        ╔═══════════════╗
        ║   My Timers   ║  Title (Scrolls off screen)
        ╠═══════════════╣
        ║               ║
        ║ 🏃 Workout    ║  Timer Card
        ║    25:00      ║  (Tappable)
        ║               ║
        ╟───────────────╢
        ║               ║
        ║ 📚 Study      ║  Timer Card
        ║    45:00      ║
        ║               ║
        ╟───────────────╢
        ║               ║
        ║ ☕ Break      ║  Timer Card
        ║    10:00      ║
        ║               ║
        ╟───────────────╢
        ║               ║
        ║ 🍳 Cooking    ║  Timer Card
        ║    15:00      ║  (Scrollable list)
        ║               ║
        ╚═══════════════╝
           Digital Crown
           to scroll ↕
```

**Interactions**:
- Tap timer → Navigate to Timer Detail
- Digital Crown → Scroll through list
- Force Touch → Menu (Sync Now option)

---

### Empty State (No Timers)

```
        ╔═══════════════╗
        ║   My Timers   ║
        ╠═══════════════╣
        ║               ║
        ║               ║
        ║      ⏱️       ║  Icon
        ║               ║
        ║  No Timers    ║  Message
        ║               ║
        ║  Create one   ║  Instruction
        ║  on iPhone    ║
        ║               ║
        ╚═══════════════╝
```

---

## 2. Timer Detail View (Not Running)

### Main Display

```
        ╔═══════════════╗
        ║  < Workout    ║  Back button + Title
        ╠═══════════════╣
        ║               ║
        ║               ║
        ║               ║
        ║    25:00      ║  Large Time Display
        ║               ║  (Center, prominent)
        ║               ║
        ║               ║
        ║   [ START ]   ║  Big Action Button
        ║               ║
        ╚═══════════════╝
           Digital Crown
           to scroll down
```

**Interactions**:
- Tap "< Workout" → Back to list
- Tap START button → Start timer
- Digital Crown down → Scroll to to-dos
- Force Touch → Menu (Reset, Edit on iPhone)

---

### Timer Display + Metadata

```
        ╔═══════════════╗
        ║  < Workout    ║
        ╠═══════════════╣
        ║               ║
        ║    25:00      ║  Time Display
        ║               ║
        ╟───────────────╢
        ║               ║
        ║  🏃 Workout   ║  Timer Info
        ║               ║
        ║  3 to-dos     ║  Metadata
        ║  Notes: Yes   ║
        ║               ║
        ║               ║
        ║   [ START ]   ║  Action Button
        ║               ║
        ╚═══════════════╝
```

---

## 3. Timer Running View

### Active Timer

```
        ╔═══════════════╗
        ║  < Workout    ║
        ╠═══════════════╣
        ║               ║
        ║      ╱╲       ║  Progress Ring
        ║     ╱  ╲      ║  (Animated)
        ║    │18:34│    ║  Countdown
        ║     ╲  ╱      ║
        ║      ╲╱       ║
        ║               ║
        ║   [ PAUSE ]   ║  Pause Button
        ║               ║
        ╚═══════════════╝
```

**Visual Notes**:
- Progress ring animates (depletes clockwise)
- Ring color matches timer's custom color
- Time updates every second
- PAUSE button replaces START

**Interactions**:
- Tap PAUSE → Pause timer
- Digital Crown → Still can scroll to to-dos while running
- Swipe right → Back to list (timer keeps running in background)

---

### Minimal Running Display

```
        ╔═══════════════╗
        ║               ║
        ║               ║
        ║               ║
        ║               ║
        ║    18:34      ║  Large Time Only
        ║               ║  (Full screen focus)
        ║               ║
        ║               ║
        ║               ║
        ╚═══════════════╝
        Tap anywhere
        to show controls
```

**Alternative view when timer is running** - tap screen to toggle controls visibility.

---

## 4. Timer Paused View

```
        ╔═══════════════╗
        ║  < Workout    ║
        ╠═══════════════╣
        ║               ║
        ║      ╱╲       ║  Progress Ring
        ║     ╱  ╲      ║  (Static/Dimmed)
        ║    │18:34│    ║
        ║     ╲  ╱      ║
        ║      ╲╱       ║
        ║   ⏸ PAUSED   ║  Status Label
        ║               ║
        ║  [ RESUME ]   ║  Resume Button
        ║               ║
        ╚═══════════════╝
```

**Changes from Running**:
- "PAUSED" label appears
- PAUSE button becomes RESUME
- Progress ring slightly dimmed
- Haptic feedback on pause

---

## 5. To-Do List View (Scroll Down from Timer)

### To-Do Section

```
        ╔═══════════════╗
        ║  < Workout    ║
        ╠═══════════════╣
        ║               ║
        ║  To-Dos (3)   ║  Section Header
        ║               ║
        ╟───────────────╢
        ║ ☐ Warm up     ║  To-Do Item
        ║   5 minutes   ║  (Tappable)
        ╟───────────────╢
        ║ ☐ 20 push-ups ║  To-Do Item
        ╟───────────────╢
        ║ ☑ Stretch     ║  Completed Item
        ║   legs        ║  (Checkmark)
        ╟───────────────╢
        ║ ☐ Core        ║  To-Do Item
        ║   exercises   ║  (Scrollable)
        ╚═══════════════╝
           Digital Crown
           to scroll
```

**Interactions**:
- Tap to-do → Toggle completion
- Haptic feedback on toggle
- Completed items show checkmark
- Digital Crown → Scroll through list

---

### Individual To-Do Detail (Tap on To-Do)

```
        ╔═══════════════╗
        ║  < To-Dos     ║
        ╠═══════════════╣
        ║               ║
        ║  Warm up      ║  To-Do Text
        ║  5 minutes    ║  (Read-only)
        ║               ║
        ║               ║
        ║ ┌───────────┐ ║
        ║ │  ☐ Mark   │ ║  Toggle Button
        ║ │ Complete  │ ║
        ║ └───────────┘ ║
        ║               ║
        ║               ║
        ╚═══════════════╝
```

**Simplified interaction** - tap entire card to toggle, or dedicated button.

---

### Empty To-Dos

```
        ╔═══════════════╗
        ║  < Workout    ║
        ╠═══════════════╣
        ║               ║
        ║  To-Dos (0)   ║
        ║               ║
        ║               ║
        ║  No to-dos    ║  Empty State
        ║  yet          ║
        ║               ║
        ║  Add them on  ║  Instruction
        ║  iPhone       ║
        ║               ║
        ╚═══════════════╝
```

---

## 6. Notes View (Scroll Further Down)

### Notes Section

```
        ╔═══════════════╗
        ║  < Workout    ║
        ╠═══════════════╣
        ║               ║
        ║  Notes        ║  Section Header
        ║               ║
        ╟───────────────╢
        ║               ║
        ║ Remember to   ║  Note Text
        ║ hydrate!      ║  (Scrollable)
        ║               ║
        ║ Increase      ║
        ║ intensity     ║
        ║ next time     ║
        ║               ║
        ╚═══════════════╝
           Digital Crown
           to scroll text
```

**Read-only view** - notes can only be edited on iPhone.

---

### Empty Notes

```
        ╔═══════════════╗
        ║  < Workout    ║
        ╠═══════════════╣
        ║               ║
        ║  Notes        ║
        ║               ║
        ║               ║
        ║  No notes     ║  Empty State
        ║  yet          ║
        ║               ║
        ║  Add them on  ║
        ║  iPhone       ║
        ║               ║
        ╚═══════════════╝
```

---

## 7. Timer Complete Notification

### Notification Banner

```
        ╔═══════════════╗
        ║               ║
        ║  🏃 Timer     ║  Notification
        ║  Complete!    ║  (Banner style)
        ║               ║
        ║  Workout      ║  Timer Name
        ║  Timer        ║
        ║               ║
        ║  Your 25:00   ║  Message
        ║  timer has    ║
        ║  finished!    ║
        ║               ║
        ╚═══════════════╝
        Tap to open app
```

**Notification Behavior**:
- Banner appears on watch face
- Haptic feedback (strong)
- Sound plays (if enabled)
- Tap to open timer detail

---

### In-App Completion

```
        ╔═══════════════╗
        ║  < Workout    ║
        ╠═══════════════╣
        ║               ║
        ║      ✓        ║  Checkmark Icon
        ║               ║  (Large, centered)
        ║   Complete!   ║
        ║               ║
        ║    00:00      ║  Timer at Zero
        ║               ║
        ║               ║
        ║  [ RESTART ]  ║  Action Button
        ║               ║
        ╚═══════════════╝
```

**Completion Behavior**:
- Large checkmark animation
- Haptic success feedback
- RESTART button to start again

---

## 8. Force Touch Menu (Context Menu)

### Timer List Menu

```
        ╔═══════════════╗
        ║   My Timers   ║
        ╠═══════════════╣
        ║ ┌───────────┐ ║
        ║ │ Sync Now  │ ║  Menu Option
        ║ └───────────┘ ║
        ║               ║
        ║ ┌───────────┐ ║
        ║ │  Refresh  │ ║  Menu Option
        ║ └───────────┘ ║
        ║               ║
        ║ ┌───────────┐ ║
        ║ │  Cancel   │ ║  Cancel
        ║ └───────────┘ ║
        ╚═══════════════╝
```

---

### Timer Detail Menu

```
        ╔═══════════════╗
        ║  < Workout    ║
        ╠═══════════════╣
        ║ ┌───────────┐ ║
        ║ │   Reset   │ ║  Menu Option
        ║ └───────────┘ ║
        ║               ║
        ║ ┌───────────┐ ║
        ║ │Edit on    │ ║  Menu Option
        ║ │iPhone     │ ║
        ║ └───────────┘ ║
        ║               ║
        ║ ┌───────────┐ ║
        ║ │  Cancel   │ ║  Cancel
        ║ └───────────┘ ║
        ╚═══════════════╝
```

---

## 9. Scrolling Navigation Overview

### Full Screen Scroll Flow

```
┌─────────────────────────────────────┐
│                                     │
│    Screen 1: Timer Display          │
│    ┌─────────────────────────┐     │
│    │       25:00             │     │
│    │     [ START ]           │     │
│    └─────────────────────────┘     │
│                                     │
│              ↓ Scroll Down          │
│         (Digital Crown)             │
│                                     │
│    Screen 2: To-Dos                 │
│    ┌─────────────────────────┐     │
│    │ To-Dos (3)              │     │
│    │ ☐ Warm up 5 minutes     │     │
│    │ ☐ 20 push-ups           │     │
│    └─────────────────────────┘     │
│                                     │
│              ↓ Scroll Down          │
│         (Digital Crown)             │
│                                     │
│    Screen 3: Notes                  │
│    ┌─────────────────────────┐     │
│    │ Notes                   │     │
│    │ Remember to hydrate!    │     │
│    │ Increase intensity...   │     │
│    └─────────────────────────┘     │
│                                     │
└─────────────────────────────────────┘
```

All screens accessible via continuous vertical scroll using Digital Crown.

---

## 10. Complications (Watch Face Widgets)

### Circular Complication

```
    ┌─────────┐
    │  ⏱️     │  Icon Only
    │   25    │  Duration (minutes)
    └─────────┘
```

### Modular Complication

```
┌─────────────────────┐
│ 🏃 Workout  →       │  Timer Name + Chevron
│    25:00            │  Duration
└─────────────────────┘
```

### Graphic Circular

```
        ┌────┐
       ╱      ╲
      │  25:00 │  Duration in circle
       ╲      ╱   Progress ring when running
        └────┘
```

**Complication Features**:
- Tap to open app
- Shows next timer or running timer
- Updates in real-time when timer active
- Can customize which timer to show

---

## Design Specifications

### Typography (watchOS)
- **Large Title**: 28pt (timer display)
- **Title**: 20pt (screen titles)
- **Headline**: 17pt (section headers)
- **Body**: 15pt (regular text)
- **Caption**: 12pt (metadata)

### Spacing
- **Screen padding**: 8pt horizontal (limited space)
- **Element spacing**: 8-12pt
- **Section spacing**: 16pt

### Colors
- **Primary**: System color (user's accent)
- **Timer Color**: Custom per timer
- **Background**: Black (OLED optimization)
- **Text**: White/system colors

### Tap Targets
- **Minimum**: 44x44pt (even on small screen)
- **Buttons**: Full width when possible
- **List Items**: Full height row

---

## Interaction Patterns

### Digital Crown
- **Scroll lists**: Timer list, to-do list
- **Scroll content**: Notes, long text
- **Zoom**: Not used in this app

### Tap Gestures
- **Single tap**: Primary action (start timer, toggle to-do)
- **Tap and hold**: Not used (use Force Touch instead)

### Force Touch
- **Context menu**: Additional actions
- **Available on**: Timer list, timer detail

### Swipe Gestures
- **Swipe right**: Back navigation (system gesture)
- **Swipe left**: Not used

---

## watchOS-Specific Features

### Always-On Display (AOD)
When timer is running and screen dims:
```
        ╔═══════════════╗
        ║               ║
        ║               ║
        ║               ║
        ║    18:34      ║  Dimmed Display
        ║               ║  (Low power mode)
        ║               ║
        ║               ║
        ║               ║
        ╚═══════════════╝
```
- Only essential info shown
- Reduced brightness
- Updates every second

---

### Handoff to iPhone

When user raises iPhone near Watch running timer:
```
iPhone Lock Screen:
┌─────────────────────────────────────┐
│                                     │
│  🏃 Continue Workout Timer          │
│     on iPhone                       │  Handoff Banner
│                                     │
└─────────────────────────────────────┘
```

User can tap to immediately open timer on iPhone.

---

## Accessibility

### VoiceOver
- Timer display: "18 minutes 34 seconds remaining"
- To-dos: "Warm up 5 minutes, not completed, button"
- Timer state: "Timer running" / "Timer paused"

### Larger Text
- All text scales with Dynamic Type
- Layouts reflow for larger text

### Reduced Motion
- Progress ring animations simplified
- No parallax effects

### Color Blind Support
- Icons paired with text
- Checkmarks for completion (not just color)

---

## Performance Considerations

### Battery Optimization
- Timer runs in background efficiently
- Screen dims when not in use (AOD)
- Haptics used sparingly
- Minimal animations when battery low

### Data Sync
- Sync on app open
- Background sync when Watch Connectivity available
- Graceful offline mode

---

## Navigation Summary

```
Timer List
    │
    ├─> Timer Detail (Tap)
    │      │
    │      ├─> Scroll Down: To-Dos Section
    │      │
    │      └─> Scroll Down: Notes Section
    │
    └─> Force Touch Menu
           ├─> Sync Now
           └─> Refresh
```

**Back Navigation**: Swipe right (system gesture) or tap back button

---

## Next Steps

See `views-structure.md` for detailed SwiftUI implementation for watchOS.
