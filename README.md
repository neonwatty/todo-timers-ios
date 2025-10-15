# TodoTimers - iOS & watchOS App

A simple timer app for iOS and Apple Watch that allows users to create multiple timers, each with associated to-do lists and notes. Timers sync seamlessly between iPhone and Apple Watch using Watch Connectivity Framework.

## Features

- **Multiple Timers**: Create unlimited timers with custom names, durations, icons, and colors
- **To-Do Lists**: Add to-do items to each timer, check them off as you complete them
- **Notes**: Add free-form notes to any timer for reminders or observations
- **Real-Time Sync**: Timers, to-dos, and notes sync instantly between iPhone and Apple Watch via Bluetooth
- **Notifications**: Get notified when a timer completes
- **watchOS Complications**: Show your timers on your watch face
- **Offline Support**: Both apps work fully offline; sync when devices reconnect

## Tech Stack

- **Language**: Swift 6
- **UI Framework**: SwiftUI (shared codebase for iOS and watchOS)
- **Architecture**: MVVM (Model-View-ViewModel)
- **Data Persistence**: SwiftData (local storage on each device)
- **Device Sync**: Watch Connectivity Framework (Bluetooth-based, no iCloud required)
- **Async Operations**: Swift Concurrency (async/await)
- **Notifications**: UserNotifications framework

## Requirements

- **Xcode**: 15+ (for Swift 6, SwiftData, SwiftUI)
- **iOS**: 17.0+
- **watchOS**: 10.0+
- **macOS**: Sonoma or later (for development)
- **Apple Developer Account**: Free account works for development

## Getting Started

See [GETTING-STARTED.md](GETTING-STARTED.md) for detailed implementation instructions.

### Quick Start

1. **Read the documentation** in the `plans/` directory
2. **Create Xcode project** following [GETTING-STARTED.md](GETTING-STARTED.md)
3. **Implement step-by-step** using the detailed code examples provided

## Documentation

All planning and implementation documentation is in the `plans/` directory:

| File | Contents |
|------|----------|
| [`00-overview.md`](plans/00-overview.md) | Tech stack, architecture, features overview |
| [`01-data-model.md`](plans/01-data-model.md) | SwiftData models, DTOs, serialization |
| [`02-watch-connectivity.md`](plans/02-watch-connectivity.md) | Sync strategy, WCSession implementation |
| [`ios/mockups.md`](plans/ios/mockups.md) | All iOS screen designs (ASCII mockups) |
| [`ios/views-structure.md`](plans/ios/views-structure.md) | Complete SwiftUI code for iOS views |
| [`watchos/mockups.md`](plans/watchos/mockups.md) | All watchOS screen designs |
| [`watchos/views-structure.md`](plans/watchos/views-structure.md) | Complete SwiftUI code for watchOS views |

## Project Structure

```
todo-timers/
├── README.md                           # This file
├── GETTING-STARTED.md                  # Implementation guide
└── plans/                              # Detailed planning docs
    ├── 00-overview.md
    ├── 01-data-model.md
    ├── 02-watch-connectivity.md
    ├── ios/
    │   ├── mockups.md
    │   └── views-structure.md
    └── watchos/
        ├── mockups.md
        └── views-structure.md
```

## Implementation Roadmap

- [x] **Phase 1**: Planning and documentation
- [ ] **Phase 2**: Xcode project setup
- [ ] **Phase 3**: SwiftData models
- [ ] **Phase 4**: iOS app implementation
- [ ] **Phase 5**: Watch Connectivity service
- [ ] **Phase 6**: watchOS app implementation
- [ ] **Phase 7**: Notifications and haptics
- [ ] **Phase 8**: Polish and testing

## Screenshots

Coming soon after implementation!

## Design Philosophy

- **iPhone First**: iPhone is the primary device for creating and editing timers
- **Watch as Companion**: Apple Watch provides quick access and glanceable information
- **Simplicity**: Clean, intuitive interface following Apple's Human Interface Guidelines
- **Offline-First**: App fully functional without network; sync when possible
- **Privacy**: All data stored locally, sync via Bluetooth only

## Key Features Detail

### Timer Management
- Create timers with hours, minutes, and seconds
- Choose from 12+ SF Symbol icons
- Pick from 8 preset colors
- Edit or delete timers anytime

### To-Do Lists
- Add unlimited to-do items to each timer
- Check off items as you complete them
- Reorder items (iOS only)
- Syncs completion status to Watch

### Notes
- Add free-form text notes to any timer
- Great for tracking observations or adjustments
- Full editing on iPhone, read-only on Watch

### Watch Connectivity
- Real-time bidirectional sync
- Works when devices are paired and in range
- Graceful offline handling
- No iCloud account required

### Notifications
- Alert when timer completes
- Haptic feedback on Apple Watch
- Quick action to restart timer

### watchOS Complications
- Show timers on your watch face
- Circular, modular, and graphic styles
- Updates in real-time when timer running

## Testing

### Simulator Testing
- Test UI and basic functionality in iOS Simulator
- Pair watchOS Simulator with iOS Simulator for basic sync testing

### Real Device Testing (Required for)
- Watch Connectivity sync (Bluetooth)
- Background timer behavior
- Notifications
- Haptic feedback
- Complications
- Always-On Display
- Battery impact

## Future Enhancements

- [ ] Timer templates/presets
- [ ] Repeat/recurring timers
- [ ] Timer history and statistics
- [ ] Voice notes (Watch dictation)
- [ ] Multiple timer categories
- [ ] Lock Screen widgets (iOS)
- [ ] Siri shortcuts integration
- [ ] iCloud backup (optional, in addition to Watch Connectivity)

## Contributing

This is a planning and documentation repository. Feel free to use these plans to build your own Timer app!

## License

This project documentation is provided as-is for educational and development purposes.

## Acknowledgments

- Built with SwiftUI and SwiftData
- Designed for iOS 17+ and watchOS 10+
- Follows Apple's Human Interface Guidelines

---

**Ready to build?** Start with [GETTING-STARTED.md](GETTING-STARTED.md)!
