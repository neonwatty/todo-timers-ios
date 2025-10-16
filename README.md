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
- [x] **Phase 2**: Xcode project setup and App Groups
- [x] **Phase 3**: SwiftData models and DTOs
- [x] **Phase 4**: iOS app implementation (views, components, services)
- [x] **Phase 5**: Watch Connectivity service (bi-directional sync)
- [x] **Phase 6**: Comprehensive test suite (109+ tests)
- [ ] **Phase 7**: watchOS app implementation
- [ ] **Phase 8**: Notifications and haptics
- [ ] **Phase 9**: Polish and App Store preparation

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

The project includes a comprehensive test suite with **109+ tests** covering unit, integration, and end-to-end scenarios.

### Running Tests

**Run All Tests:**
- Press `⌘U` in Xcode to run the full test suite

**Run Specific Test File:**
- Click the diamond icon next to test class/method in code
- Or use Test Navigator (`⌘6`) to run individual tests

**Test Coverage:**
- Enable code coverage: `Product` → `Scheme` → `Edit Scheme` → `Test` → `Options` → Check "Code Coverage"
- View coverage report: `Report Navigator` (`⌘9`) → Select latest test run

### Test Suite Structure

**Unit Tests** (`TodoTimersTests/UnitTests/`) - **80 tests**
- `Models/TimerTests.swift` (17 tests): Initialization, validation, computed properties
- `Models/TodoItemTests.swift` (10 tests): Initialization, validation, behavior
- `DTOs/TimerDTOTests.swift` (10 tests): Model ↔ DTO conversion, Codable
- `DTOs/TodoItemDTOTests.swift` (10 tests): Model ↔ DTO conversion, Codable
- `DTOs/WatchPayloadsTests.swift` (10 tests): Sync payloads, update messages
- `Extensions/ColorExtensionTests.swift` (9 tests): Hex color parsing
- `Services/TimerServiceTests.swift` (14 tests): Timer countdown, state management

**Integration Tests** (`TodoTimersTests/IntegrationTests/`) - **15 tests**
- `SwiftDataIntegrationTests.swift`: Timer/TodoItem CRUD, relationships, queries, cascade delete

**End-to-End UI Tests** (`TodoTimersUITests/E2ETests/`) - **30+ tests**
- `TimerManagementUITests.swift` (13 tests): Create timer, detail view, controls
- `TodoManagementUITests.swift` (11 tests): Add todos, toggle completion, empty states
- `NavigationUITests.swift` (11 tests): Navigation flows, sheet behavior, back navigation

**Test Helpers:**
- `TestModelContainer.swift`: In-memory SwiftData containers
- `TestDataFactory.swift`: Factory methods for test data
- `MockWCSession.swift`: Mock WatchConnectivity session
- `XCUIElementExtensions.swift`: UI test helper extensions

### Test Coverage Goals

- **Business Logic**: >80% coverage
- **Models & DTOs**: 100% coverage (achieved)
- **Services**: >75% coverage
- **UI**: Critical user flows covered

### Simulator vs Real Device Testing

**Simulator Testing (Available):**
- All unit and integration tests
- UI tests for basic flows
- SwiftData persistence
- Basic sync simulation

**Real Device Testing (Required for):**
- Watch Connectivity sync (Bluetooth, requires paired devices)
- Background timer behavior
- Push notifications
- Haptic feedback accuracy
- watchOS Complications
- Always-On Display
- Battery impact

### Running Tests in CI

The test suite is designed to run in CI environments:
- Uses in-memory SwiftData containers (no file system dependencies)
- Mock WCSession for Watch Connectivity tests
- Deterministic test data via factory methods

**GitHub Actions Example:**
```yaml
- name: Run Tests
  run: xcodebuild test -scheme TodoTimers -destination 'platform=iOS Simulator,name=iPhone 15'
```

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
