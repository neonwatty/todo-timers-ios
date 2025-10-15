# iOS App - UI Mockups

## Overview

These ASCII mockups illustrate the complete iOS app user interface for the Timer app. The design follows iOS Human Interface Guidelines and leverages native SwiftUI components.

---

## 1. Timer List View (Main Screen)

### Default State (With Timers)

```
┌─────────────────────────────────────┐
│  ☰  My Timers                   +   │  Navigation Bar
├─────────────────────────────────────┤
│                                     │
│  ┌─────────────────────────────┐   │  Timer Card
│  │ 🏃 Workout Timer            │   │
│  │ 25:00                       │   │
│  │ ─────────────────────────  │   │
│  │ 3 to-dos • Notes added     │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │  Timer Card
│  │ 📚 Study Session            │   │
│  │ 45:00                       │   │
│  │ ─────────────────────────  │   │
│  │ 1 to-do • No notes         │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │  Timer Card
│  │ ☕ Coffee Break             │   │
│  │ 10:00                       │   │
│  │ ─────────────────────────  │   │
│  │ No to-dos • Notes added    │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │  Timer Card
│  │ 🍳 Cooking Timer            │   │
│  │ 15:00                       │   │
│  │ ─────────────────────────  │   │
│  │ 5 to-dos • No notes        │   │
│  └─────────────────────────────┘   │
│                                     │
│                                     │  Scrollable List
│                                     │
└─────────────────────────────────────┘
```

**Interactions**:
- Tap timer card → Navigate to Timer Detail View
- Tap (+) button → Navigate to Create Timer View
- Swipe left on card → Delete option
- Tap (☰) menu → Settings/About

---

### Empty State (No Timers)

```
┌─────────────────────────────────────┐
│  ☰  My Timers                   +   │
├─────────────────────────────────────┤
│                                     │
│                                     │
│                                     │
│            ⏱️                       │
│                                     │
│      No Timers Yet                  │
│                                     │
│  Tap + to create your first timer   │
│                                     │
│                                     │
│                                     │
│                                     │
│                                     │
│                                     │
└─────────────────────────────────────┘
```

---

### Swipe Actions

```
┌─────────────────────────────────────┐
│  ☰  My Timers                   +   │
├─────────────────────────────────────┤
│                                     │
│  ┌───────────────────────┬────────┐ │  Swiped Left
│  │ 🏃 Workout Timer      │        │ │
│  │ 25:00                 │ Delete │ │
│  │ ──────────────────── │        │ │
│  │ 3 to-dos • Notes     │  🗑️   │ │
│  └───────────────────────┴────────┘ │
│                                     │
└─────────────────────────────────────┘
```

---

## 2. Create Timer View

### Main Form

```
┌─────────────────────────────────────┐
│  Cancel   New Timer           Done  │  Navigation Bar
├─────────────────────────────────────┤
│                                     │
│  TIMER NAME                         │  Section Header
│  ┌─────────────────────────────┐   │
│  │ Workout Timer               │   │  Text Field
│  └─────────────────────────────┘   │
│                                     │
│  DURATION                           │  Section Header
│  ┌───────────────────────────────┐ │
│  │       ┌────┐ ┌────┐ ┌────┐   │ │  Picker Wheels
│  │       │ 00 │ │ 25 │ │ 00 │   │ │
│  │       │ 01 │ │ 26 │ │ 01 │   │ │
│  │       │ 02 │ │ 27 │ │ 02 │   │ │
│  │       └────┘ └────┘ └────┘   │ │
│  │       hours  mins   secs      │ │
│  └───────────────────────────────┘ │
│                                     │
│  ICON                               │  Section Header
│  ┌─────────────────────────────┐   │
│  │  ⏱️  🏃  📚  ☕  🍳  ✏️     │   │  Icon Grid
│  │                             │   │  (Scrollable)
│  │  🎮  🎵  💼  🧘  🚴  🛠️     │   │
│  └─────────────────────────────┘   │
│                                     │
│  COLOR                              │  Section Header
│  ┌─────────────────────────────┐   │
│  │  🔴 🟠 🟡 🟢 🔵 🟣 🟤 ⚫   │   │  Color Swatches
│  └─────────────────────────────┘   │
│                                     │
└─────────────────────────────────────┘
```

**Interactions**:
- Tap "Cancel" → Dismiss view
- Tap "Done" → Validate & create timer
- Text field → Keyboard appears
- Duration pickers → Scroll to select time
- Icon grid → Tap to select icon
- Color swatches → Tap to select color

---

### Validation Error

```
┌─────────────────────────────────────┐
│  Cancel   New Timer           Done  │
├─────────────────────────────────────┤
│  ⚠️ Timer name cannot be empty       │  Error Banner
├─────────────────────────────────────┤
│                                     │
│  TIMER NAME                         │
│  ┌─────────────────────────────┐   │
│  │                             │   │  Empty (Error State)
│  └─────────────────────────────┘   │
│     ↑ Required field                │  Helper Text
│                                     │
└─────────────────────────────────────┘
```

---

## 3. Timer Detail View (Timer Not Running)

### Main View

```
┌─────────────────────────────────────┐
│  < Timers   Workout Timer      Edit │  Navigation Bar
├─────────────────────────────────────┤
│                                     │
│         ┌─────────────┐             │
│         │             │             │
│         │   25:00     │             │  Large Timer Display
│         │             │             │  (Circular Progress Ring)
│         └─────────────┘             │
│                                     │
│      ┌──────────┐  ┌──────────┐    │
│      │  START   │  │  RESET   │    │  Action Buttons
│      └──────────┘  └──────────┘    │
│                                     │
├─────────────────────────────────────┤
│  To-Do Items                 (+)    │  Section Header
│  ─────────────────────────────────  │
│  ☐ Warm up 5 minutes          >     │  Todo Item
│  ☐ 20 push-ups                >     │  Todo Item
│  ☑ Stretch legs               >     │  Todo Item (Completed)
│  ☐ Core exercises             >     │  Todo Item
│  ☐ Cool down                  >     │  Todo Item
│                                     │
├─────────────────────────────────────┤
│  Notes                      (Edit)  │  Section Header
│  ─────────────────────────────────  │
│  Remember to hydrate!               │
│  Increase intensity next time       │  Notes Text
│  Focus on form                      │
│                                     │
└─────────────────────────────────────┘
```

**Visual Notes**:
- Timer ring shows full circle (not started)
- START button is prominent (primary color)
- RESET button is secondary/gray
- Checked to-do has strikethrough text (☑ Stretch legs)
- Chevron (>) indicates tappable to-do items

---

## 4. Timer Detail View (Timer Running)

### Running State

```
┌─────────────────────────────────────┐
│  < Timers   Workout Timer      Edit │
├─────────────────────────────────────┤
│                                     │
│         ┌─────────────┐             │
│         │    ╱╲       │             │
│         │   ╱  ╲      │             │  Progress Ring
│         │  │ 18:34│   │             │  (Depleting)
│         │   ╲  ╱      │             │
│         │    ╲╱       │             │
│         └─────────────┘             │
│                                     │
│      ┌──────────┐  ┌──────────┐    │
│      │  PAUSE   │  │  RESET   │    │  Action Buttons
│      └──────────┘  └──────────┘    │
│                                     │
├─────────────────────────────────────┤
│  To-Do Items                 (+)    │
│  ─────────────────────────────────  │
│  ☐ Warm up 5 minutes          >     │
│  ☐ 20 push-ups                >     │
│  ☑ Stretch legs               >     │
│  ☐ Core exercises             >     │
│  ☐ Cool down                  >     │
│                                     │
├─────────────────────────────────────┤
│  Notes                      (Edit)  │
│  ─────────────────────────────────  │
│  Remember to hydrate!               │
│  Increase intensity next time       │
│  Focus on form                      │
│                                     │
└─────────────────────────────────────┘
```

**Changes from Non-Running**:
- Timer counting down (18:34)
- Progress ring partially depleted
- START button changed to PAUSE

---

## 5. Timer Detail View (Timer Paused)

```
┌─────────────────────────────────────┐
│  < Timers   Workout Timer      Edit │
├─────────────────────────────────────┤
│                                     │
│         ┌─────────────┐             │
│         │    ╱╲       │             │
│         │   ╱  ╲      │             │
│         │  │ 18:34│   │             │  Ring (Paused State)
│         │   ╲  ╱      │             │  (Slightly Dimmed)
│         │    ╲╱       │             │
│         └─────────────┘             │
│            ⏸ PAUSED                 │  Status Label
│                                     │
│      ┌──────────┐  ┌──────────┐    │
│      │  RESUME  │  │  RESET   │    │  Action Buttons
│      └──────────┘  └──────────┘    │
│                                     │
├─────────────────────────────────────┤
│  To-Do Items                 (+)    │
│  ─────────────────────────────────  │
│  ☐ Warm up 5 minutes          >     │
│  ☐ 20 push-ups                >     │
│  ☑ Stretch legs               >     │
│  ☐ Core exercises             >     │
│  ☐ Cool down                  >     │
│                                     │
└─────────────────────────────────────┘
```

**Changes**:
- "PAUSED" status label
- PAUSE button changed to RESUME
- Timer frozen at last value

---

## 6. Edit Timer View

### Edit Form

```
┌─────────────────────────────────────┐
│  Cancel   Edit Timer          Save  │
├─────────────────────────────────────┤
│                                     │
│  TIMER NAME                         │
│  ┌─────────────────────────────┐   │
│  │ Workout Timer               │   │  Editable Field
│  └─────────────────────────────┘   │
│                                     │
│  DURATION                           │
│  ┌───────────────────────────────┐ │
│  │       ┌────┐ ┌────┐ ┌────┐   │ │
│  │       │ 00 │ │ 25 │ │ 00 │   │ │
│  │       │ 01 │ │ 26 │ │ 01 │   │ │
│  │       │ 02 │ │ 27 │ │ 02 │   │ │
│  │       └────┘ └────┘ └────┘   │ │
│  │       hours  mins   secs      │ │
│  └───────────────────────────────┘ │
│                                     │
│  ICON                               │
│  ┌─────────────────────────────┐   │
│  │  ⏱️  [🏃] 📚  ☕  🍳  ✏️    │   │  Currently Selected
│  │                             │   │  (Highlighted: 🏃)
│  │  🎮  🎵  💼  🧘  🚴  🛠️     │   │
│  └─────────────────────────────┘   │
│                                     │
│  COLOR                              │
│  ┌─────────────────────────────┐   │
│  │  [🔴] 🟠 🟡 🟢 🔵 🟣 🟤 ⚫  │   │  Currently Selected
│  └─────────────────────────────┘   │  (Highlighted: 🔴)
│                                     │
│  ┌─────────────────────────────┐   │
│  │      🗑️  Delete Timer        │   │  Destructive Action
│  └─────────────────────────────┘   │
│                                     │
└─────────────────────────────────────┘
```

---

## 7. Todo Item Detail/Edit Sheet

### Edit Todo

```
┌─────────────────────────────────────┐
│                                     │
│         Edit To-Do Item             │  Sheet Title
│                                     │
│  ┌─────────────────────────────┐   │
│  │ Warm up 5 minutes           │   │  Text Field
│  └─────────────────────────────┘   │  (Active/Focused)
│                                     │
│  ┌─────────────────────────────┐   │
│  │  ☐  Mark as completed       │   │  Toggle
│  └─────────────────────────────┘   │
│                                     │
│                                     │
│      ┌──────────┐  ┌──────────┐    │
│      │  Cancel  │  │   Save   │    │  Action Buttons
│      └──────────┘  └──────────┘    │
│                                     │
│                                     │
│  ┌─────────────────────────────┐   │
│  │      Delete To-Do Item       │   │  Destructive Action
│  └─────────────────────────────┘   │
│                                     │
└─────────────────────────────────────┘
```

**Interactions**:
- Text field for editing to-do text
- Toggle for completion status
- Delete button (destructive style)
- Presented as bottom sheet or modal

---

## 8. Add Todo Sheet

```
┌─────────────────────────────────────┐
│                                     │
│         Add To-Do Item              │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ Enter to-do text...         │   │  Text Field (Empty)
│  └─────────────────────────────┘   │
│                                     │
│                                     │
│                                     │
│      ┌──────────┐  ┌──────────┐    │
│      │  Cancel  │  │   Add    │    │
│      └──────────┘  └──────────┘    │
│                                     │
│                                     │
│                                     │
└─────────────────────────────────────┘
```

**Interactions**:
- Tap (+) in To-Do section → Shows this sheet
- Keyboard appears automatically
- "Add" button disabled until text entered

---

## 9. Edit Notes View

```
┌─────────────────────────────────────┐
│  Cancel      Notes             Save │
├─────────────────────────────────────┤
│                                     │
│  ┌─────────────────────────────┐   │
│  │ Remember to hydrate!        │   │
│  │                             │   │
│  │ Increase intensity next time│   │  Text Editor
│  │                             │   │  (Multi-line)
│  │ Focus on form               │   │
│  │                             │   │
│  │                             │   │
│  │                             │   │
│  │                             │   │
│  └─────────────────────────────┘   │
│                                     │
└─────────────────────────────────────┘
```

**Interactions**:
- Tap "Edit" in Notes section → Navigate here
- Full-screen text editor
- Auto-saves on "Save" tap

---

## 10. Timer Completion Alert

### Local Notification (Lock Screen)

```
┌─────────────────────────────────────┐
│   🏃 Timer Complete                 │
│   Workout Timer                     │
│   Your 25:00 timer has finished!    │
│                                     │
│   [Dismiss]  [Restart]              │
└─────────────────────────────────────┘
```

### In-App Alert

```
┌─────────────────────────────────────┐
│  < Timers   Workout Timer      Edit │
├─────────────────────────────────────┤
│                                     │
│    ┌───────────────────────────┐   │
│    │    ⏱️ Timer Complete!     │   │
│    │                           │   │
│    │  Your Workout Timer has   │   │  Alert Dialog
│    │  finished!                │   │
│    │                           │   │
│    │   [Restart]  [Dismiss]    │   │
│    └───────────────────────────┘   │
│                                     │
│         ┌─────────────┐             │
│         │             │             │
│         │   00:00     │             │  Timer at 00:00
│         │             │             │
│         └─────────────┘             │
│                                     │
└─────────────────────────────────────┘
```

---

## 11. Delete Confirmation Alert

```
┌─────────────────────────────────────┐
│  ☰  My Timers                   +   │
├─────────────────────────────────────┤
│                                     │
│    ┌───────────────────────────┐   │
│    │   Delete Timer?           │   │
│    │                           │   │
│    │  This will permanently    │   │  Alert Dialog
│    │  delete "Workout Timer"   │   │
│    │  and all its to-dos and   │   │
│    │  notes.                   │   │
│    │                           │   │
│    │  [Cancel]  [Delete]       │   │  Delete = Red
│    └───────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ 🏃 Workout Timer            │   │  (Dimmed background)
│  │ 25:00                       │   │
└─────────────────────────────────────┘
```

---

## 12. Settings/Menu View

```
┌─────────────────────────────────────┐
│  < Back      Settings               │
├─────────────────────────────────────┤
│                                     │
│  NOTIFICATIONS                      │
│  ┌─────────────────────────────┐   │
│  │ Timer Completion Alerts  ✓  │   │  Toggle
│  └─────────────────────────────┘   │
│  ┌─────────────────────────────┐   │
│  │ Sound                    >  │   │  Disclosure
│  └─────────────────────────────┘   │
│                                     │
│  SYNC                               │
│  ┌─────────────────────────────┐   │
│  │ Watch Connected          ✓  │   │  Status
│  └─────────────────────────────┘   │
│  ┌─────────────────────────────┐   │
│  │ Sync Now                    │   │  Action
│  └─────────────────────────────┘   │
│                                     │
│  ABOUT                              │
│  ┌─────────────────────────────┐   │
│  │ Version 1.0.0               │   │  Info
│  └─────────────────────────────┘   │
│  ┌─────────────────────────────┐   │
│  │ Privacy Policy           >  │   │  Disclosure
│  └─────────────────────────────┘   │
│                                     │
└─────────────────────────────────────┘
```

---

## Design Tokens & Specifications

### Typography
- **Large Title**: Timer display (48-60pt, bold)
- **Title**: Screen headers (34pt, bold)
- **Headline**: Section headers (17pt, semibold)
- **Body**: Regular text (17pt, regular)
- **Caption**: Helper text (12pt, regular)

### Spacing
- **Screen padding**: 16pt horizontal
- **Card padding**: 16pt all sides
- **Section spacing**: 24pt between sections
- **Item spacing**: 12pt between list items

### Colors
- **Primary**: System blue (#007AFF)
- **Destructive**: System red (#FF3B30)
- **Gray**: System gray (#8E8E93)
- **Background**: System background (dynamic)
- **Card**: System secondary background

### Components
- **Timer Card**: Rounded corners (12pt), shadow
- **Buttons**: Height 44pt minimum (accessibility)
- **Text Fields**: Height 44pt, rounded (8pt)
- **Icon Size**: 24x24pt for UI, 40x40pt for selection

---

## Accessibility Considerations

### VoiceOver Labels
- Timer cards: "Workout Timer, 25 minutes, 3 to-dos, notes added"
- Timer display: "18 minutes 34 seconds remaining"
- Buttons: Clear action labels ("Start timer", "Pause timer")

### Dynamic Type
- All text scales with user's preferred text size
- Layout adapts to larger text sizes
- Minimum touch targets: 44x44pt

### Color & Contrast
- All text meets WCAG AA contrast requirements
- Icons paired with labels
- Color not sole indicator (checkmarks for completion)

### Haptic Feedback
- Button taps: Light impact
- Timer start: Medium impact
- Timer complete: Heavy impact + sound
- To-do toggle: Selection feedback

---

## Navigation Flow Summary

```
Timer List View
    │
    ├──> Create Timer View ──> (Save) ──> Timer List View
    │
    ├──> Timer Detail View
    │       │
    │       ├──> Edit Timer View ──> (Save) ──> Timer Detail View
    │       │
    │       ├──> Edit Todo Sheet ──> (Save) ──> Timer Detail View
    │       │
    │       ├──> Add Todo Sheet ──> (Add) ──> Timer Detail View
    │       │
    │       └──> Edit Notes View ──> (Save) ──> Timer Detail View
    │
    └──> Settings View
```

---

## Next Steps

See `views-structure.md` for detailed SwiftUI component breakdown and implementation guidance.
