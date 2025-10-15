# Timer App with To-Dos & Notes - Project Overview

## Project Description

A simple iOS and watchOS application that allows users to create multiple timers, each with associated to-do lists and notes. The app syncs seamlessly between iPhone and Apple Watch using Watch Connectivity Framework.

---

## Tech Stack

### Core Technologies

- **Language**: Swift 6
- **UI Framework**: SwiftUI (shared codebase for iOS and watchOS)
- **Architecture**: MVVM (Model-View-ViewModel)
- **Data Persistence**: SwiftData (local storage on each device)
- **Device Sync**: Watch Connectivity Framework (Bluetooth-based sync)
- **Async Operations**: Swift Concurrency (async/await)
- **Notifications**: UserNotifications framework

### Why This Stack?

**SwiftUI**
- Write once, deploy to both iOS and watchOS
- Modern declarative syntax
- Native Apple framework with best performance
- Excellent integration with SwiftData

**SwiftData**
- Modern replacement for Core Data
- Declarative model definitions with Swift macros
- Automatic persistence
- Type-safe queries
- Easier to learn and maintain

**Watch Connectivity**
- Direct Bluetooth communication between devices
- No iCloud account required
- Works offline (just needs device pairing)
- Real-time sync when devices are in range
- Simpler implementation than CloudKit
- Works in simulator (with paired Watch simulator)

**MVVM Architecture**
- Clear separation of concerns
- Testable business logic
- Works naturally with SwiftUI's state management
- ViewModels handle Watch Connectivity logic

---

## Core Features (MVP)

### 1. Timer Management

**Create/Edit/Delete Timers**
- Timer name/title
- Duration (hours, minutes, seconds)
- Optional icon/color for visual identification
- Persistent storage via SwiftData

**Timer Controls**
- Start/Pause/Resume functionality
- Reset to original duration
- Visual countdown display
- Background support (timer continues when app backgrounded)

### 2. To-Do Lists Per Timer

**Add/Edit/Delete To-Dos**
- Simple text entries for each to-do item
- Checkbox to mark items complete/incomplete
- Reorder items (drag & drop on iOS)
- Persistent across app launches

**Features**
- Each timer has its own independent to-do list
- Unlimited to-dos per timer
- Quick access from timer detail view

### 3. Notes Per Timer

**Free-form Notes**
- Simple text field for each timer
- Quick jotting during or after timer runs
- Useful for observations, reminders, adjustments
- Optional (not required for timer to function)

### 4. Cross-Device Sync

**Watch Connectivity Framework**
- Real-time sync between iPhone and Apple Watch
- Bidirectional updates:
  - Timer created on iPhone → appears on Watch
  - To-do checked on Watch → updates iPhone
  - Notes added on iPhone → syncs to Watch
- Background transfers for bulk data
- Interactive messaging for real-time updates

**Sync Behavior**
- iPhone is primary data source
- Watch maintains local cache
- Changes propagate immediately when devices are in range
- Graceful handling when devices are disconnected

### 5. Notifications

**Timer Completion Alerts**
- Local notifications when timer reaches 00:00
- Haptic feedback on Apple Watch
- Notification shows timer name
- Quick actions to restart timer

---

## User Experience Flow

### iOS App Flow
1. Launch app → See list of all timers
2. Tap (+) → Create new timer (name, duration, optional icon)
3. Tap timer → View detail (timer display, to-dos, notes)
4. Start timer → Countdown begins, notification scheduled
5. Add to-dos → Quick entry, checkbox toggles
6. Add notes → Free-form text entry
7. Timer completes → Notification fires

### watchOS App Flow
1. Launch app → See scrollable list of timers
2. Tap timer → Large timer display with Start button
3. Start timer → Countdown begins on watch face
4. Scroll down → View/toggle to-dos
5. Scroll down → View notes (read-only or simple add)
6. Timer completes → Haptic + notification

---

## Architecture Overview

### Data Flow

```
┌─────────────┐         Watch Connectivity          ┌─────────────┐
│   iPhone    │◄─────────────────────────────────►  │ Apple Watch │
│             │                                      │             │
│  SwiftData  │   • Background Context Transfer     │  SwiftData  │
│  (Primary)  │   • Interactive Messages            │  (Cache)    │
│             │   • User Info Transfer              │             │
└─────────────┘                                      └─────────────┘
```

**iPhone (Primary)**
- Full CRUD operations on timers, to-dos, notes
- SwiftData persistence (source of truth)
- Sends updates to Watch via WCSession
- Receives Watch updates and merges into local DB

**Apple Watch (Secondary)**
- Receives timer data from iPhone
- Local SwiftData cache for offline viewing
- Can start/stop timers, toggle to-dos
- Sends user actions back to iPhone
- iPhone confirms and sends updated state

### Watch Connectivity Methods

**Application Context** (`updateApplicationContext`)
- Send complete timer list from iPhone to Watch
- Replaces previous context (latest state)
- Delivered when Watch is reachable
- Best for: Initial sync, bulk updates

**Interactive Messaging** (`sendMessage`)
- Real-time bidirectional communication
- Requires both devices active and reachable
- Immediate response
- Best for: Timer start/stop, to-do toggles, live updates

**User Info Transfer** (`transferUserInfo`)
- Guaranteed delivery (queued if unreachable)
- Non-urgent updates
- Best for: Note updates, timer edits

---

## Project Structure

```
TimerApp/
├── TimerApp/                    # iOS App Target
│   ├── Models/                  # SwiftData models
│   │   ├── Timer.swift
│   │   └── TodoItem.swift
│   ├── ViewModels/              # MVVM ViewModels
│   │   ├── TimerListViewModel.swift
│   │   └── TimerDetailViewModel.swift
│   ├── Views/                   # SwiftUI Views (iOS)
│   │   ├── TimerListView.swift
│   │   ├── TimerDetailView.swift
│   │   ├── CreateTimerView.swift
│   │   └── Components/
│   ├── Services/                # Business logic
│   │   ├── WatchConnectivityService.swift
│   │   ├── NotificationService.swift
│   │   └── TimerService.swift
│   └── TimerAppApp.swift        # App entry point
│
├── TimerWatchApp/               # watchOS App Target
│   ├── Models/                  # Same models (shared)
│   ├── ViewModels/              # Watch-specific ViewModels
│   ├── Views/                   # SwiftUI Views (watchOS)
│   │   ├── TimerListView.swift
│   │   ├── TimerDetailView.swift
│   │   └── Components/
│   └── Services/                # WatchConnectivityService
│
└── Shared/                      # Shared code
    ├── Models/                  # SwiftData models
    └── Extensions/              # Shared utilities
```

---

## Development Phases

### Phase 1: Core iOS App
- [ ] SwiftData models (Timer, TodoItem)
- [ ] iOS UI (list, detail, create views)
- [ ] Basic timer functionality
- [ ] To-do CRUD operations
- [ ] Notes functionality
- [ ] Local notifications

### Phase 2: watchOS App
- [ ] watchOS UI (list, detail views)
- [ ] Timer display and controls
- [ ] To-do viewing/toggling
- [ ] Notes viewing

### Phase 3: Watch Connectivity
- [ ] WCSession setup on both platforms
- [ ] Application context transfer (bulk data)
- [ ] Interactive messaging (real-time updates)
- [ ] Bidirectional sync logic
- [ ] Conflict resolution

### Phase 4: Polish & Testing
- [ ] Error handling
- [ ] Loading states
- [ ] Empty states
- [ ] Haptic feedback
- [ ] Accessibility (VoiceOver, Dynamic Type)
- [ ] Real device testing (sync behavior)

---

## Key Implementation Decisions

### Why iPhone as Primary Data Source?
- Larger screen = easier data entry
- More storage capacity
- Users more likely to create timers on iPhone
- Watch serves as companion/quick access device

### Timer State Sync Strategy
- Timer definitions (name, duration) sync bidirectionally
- Timer running state is device-specific (doesn't sync)
- Rationale: User may want timer running on iPhone but not Watch, or vice versa

### Conflict Resolution
- Last-write-wins for most operations
- Timestamps track latest update
- iPhone breaks ties (as primary device)

### Offline Behavior
- Both apps work fully offline
- Changes queue when devices disconnected
- Automatic sync when connection restored
- No data loss

---

## Future Enhancements (Post-MVP)

- [ ] Timer templates/presets
- [ ] Repeat/recurring timers
- [ ] Timer history and statistics
- [ ] Voice notes (Watch dictation)
- [ ] Multiple timer categories
- [ ] Timer widgets (iOS Lock Screen, Watch complications)
- [ ] Siri shortcuts integration
- [ ] Dark mode customization
- [ ] Export timer data
- [ ] iCloud backup (optional, in addition to Watch Connectivity)

---

## Testing Strategy

### Unit Tests
- SwiftData model logic
- ViewModel business logic
- Watch Connectivity message parsing
- Timer calculation logic

### UI Tests
- Navigation flows
- Timer start/stop behavior
- To-do CRUD operations
- Form validation

### Integration Tests
- Watch Connectivity sync scenarios
- Background notification delivery
- Data persistence across app launches

### Device Testing (Real Hardware)
- Watch Connectivity only works on real Apple Watch (not simulator)
- Test sync in various scenarios:
  - Devices in range
  - Devices out of range
  - Airplane mode
  - Background app states

---

## Getting Started

### Prerequisites
- Xcode 15+ (for Swift 6, SwiftData, SwiftUI)
- iOS 17+ SDK (for latest SwiftData features)
- watchOS 10+ SDK
- Apple Developer account (for device provisioning)
- Paired iPhone and Apple Watch for testing

### Setup Steps
1. Create new Xcode project (iOS App)
2. Add watchOS app target
3. Enable App Groups (for shared data container)
4. Configure Watch Connectivity entitlements
5. Set deployment targets (iOS 17+, watchOS 10+)
6. Install on devices and pair

---

## Resources

- [SwiftData Documentation](https://developer.apple.com/documentation/swiftdata)
- [Watch Connectivity Framework](https://developer.apple.com/documentation/watchconnectivity)
- [Creating a watchOS App - Apple Tutorial](https://developer.apple.com/tutorials/swiftui/creating-a-watchos-app)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [UserNotifications Framework](https://developer.apple.com/documentation/usernotifications)
