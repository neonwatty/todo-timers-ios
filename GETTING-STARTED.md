# Getting Started - TodoTimers iOS & watchOS App

## 📋 Overview

This guide will walk you through implementing the TodoTimers app from the planning documentation in this repository.

---

## 🚀 Implementation Roadmap

### **Phase 1: Project Setup** ⭐ START HERE
1. Create Xcode project with iOS + watchOS targets
2. Set up folder structure
3. Configure SwiftData and Watch Connectivity entitlements

### **Phase 2: Core Data Layer**
1. Implement SwiftData models (Timer, TodoItem)
2. Create transfer objects (DTOs) for Watch Connectivity
3. Add sample data for testing

### **Phase 3: iOS App**
1. Build Timer List View
2. Build Timer Detail View
3. Build Create/Edit Timer Views
4. Add Timer Service (countdown logic)

### **Phase 4: Watch Connectivity**
1. Implement WatchConnectivityService
2. Wire up sync on iOS side
3. Test syncing between devices

### **Phase 5: watchOS App**
1. Build Timer List View
2. Build Timer Detail View
3. Wire up Watch Connectivity
4. Add complications

### **Phase 6: Polish**
1. Notifications
2. Haptics
3. Accessibility
4. Testing & bug fixes

---

## 🛠️ Prerequisites

Before you begin, make sure you have:

- **macOS Sonoma** or later
- **Xcode 15+** (for Swift 6, SwiftData, SwiftUI)
- **iOS 17+ SDK** (for latest SwiftData features)
- **watchOS 10+ SDK**
- **Apple Developer Account** (free account works for development)
- **Paired iPhone and Apple Watch** (for testing sync features)

---

## 📱 Phase 1: Project Setup (5-10 minutes)

### Step 1: Create iOS Project in Xcode

1. **Open Xcode**
2. **File → New → Project**
3. Choose **iOS** tab → **App** template
4. Click **Next**
5. Configure project:
   - **Product Name**: `TodoTimers`
   - **Team**: Select your Apple ID
   - **Organization Identifier**: `com.yourname` (or your domain)
   - **Interface**: **SwiftUI**
   - **Storage**: **None** (we'll add SwiftData manually)
   - **Language**: **Swift**
   - **Include Tests**: ✅ Yes
6. Click **Next**
7. Choose save location (e.g., Desktop)
8. Click **Create**

### Step 2: Add watchOS Target

1. **File → New → Target**
2. Choose **watchOS** tab → **Watch App for iOS App**
3. Click **Next**
4. Configure:
   - **Product Name**: `TodoTimers Watch App`
   - **Bundle Identifier**: Should auto-fill as `com.yourname.TodoTimers.watchkitapp`
5. Click **Finish**
6. When asked **"Activate scheme?"** → Click **Activate**

### Step 3: Create Folder Structure

In Xcode's Project Navigator, create these groups (folders):

**For iOS App (TodoTimers):**
```
TodoTimers/
├── Models/              (Right-click TodoTimers → New Group)
├── ViewModels/
├── Views/
│   └── Components/
├── Services/
└── TodoTimersApp.swift  (Already exists)
```

**For watchOS App:**
```
TodoTimers Watch App/
├── Views/
├── Services/
└── TodoTimers_Watch_AppApp.swift  (Already exists)
```

**Shared between both:**
```
Shared/
├── Models/              (Will contain Timer.swift, TodoItem.swift)
├── DTOs/                (Data Transfer Objects)
└── Extensions/
```

### Step 4: Configure Deployment Targets

1. Select **TodoTimers** project (blue icon at top of Project Navigator)
2. Select **TodoTimers** target (under TARGETS)
3. **General** tab → **Deployment Info**
   - **Minimum Deployments**: iOS 17.0
4. Select **TodoTimers Watch App** target
5. **General** tab → **Deployment Info**
   - **Minimum Deployments**: watchOS 10.0

### Step 5: Enable App Groups (for shared data)

**For iOS Target:**
1. Select **TodoTimers** target
2. **Signing & Capabilities** tab
3. Click **+ Capability**
4. Add **App Groups**
5. Click **+** under App Groups
6. Enter: `group.com.yourname.TodoTimers`
7. Click **OK**

**For watchOS Target:**
1. Select **TodoTimers Watch App** target
2. Repeat steps 2-7 above
3. **Use the same App Group identifier**

### Step 6: Enable Watch Connectivity

**For iOS Target:**
1. **Signing & Capabilities** tab
2. Should already have **Background Modes** capability
3. If not, click **+ Capability** → **Background Modes**
4. Check: ✅ **Remote notifications**

**For watchOS Target:**
1. No additional capabilities needed (Watch Connectivity works by default)

---

## 📂 File Organization Best Practices

### Shared Files

Files that both iOS and watchOS use (like models) should be added to **both targets**:

1. Create file in **Shared/Models/** group
2. When saving, in **Target Membership** section (right panel), check:
   - ✅ TodoTimers
   - ✅ TodoTimers Watch App

### Platform-Specific Files

- **iOS-only**: Views, ViewModels specific to iPhone
- **watchOS-only**: Views, Complications specific to Watch
- **Services**: WatchConnectivityService should be in both targets (different implementations)

---

## 🎯 Next Steps: Implementation Order

Once your Xcode project is set up, implement in this order:

### 1️⃣ **Data Models First** (Foundation)

Implement these files (see `plans/01-data-model.md`):
- `Shared/Models/Timer.swift`
- `Shared/Models/TodoItem.swift`
- `Shared/DTOs/TimerDTO.swift`
- `Shared/DTOs/TodoItemDTO.swift`

**Why first?** Everything else depends on these models.

### 2️⃣ **iOS App - Basic Views** (See results quickly)

Implement these files (see `plans/ios/views-structure.md`):
- `Views/TimerListView.swift`
- `Views/Components/TimerCardView.swift`
- `Views/Components/EmptyStateView.swift`

**Test:** Run on iOS Simulator → You should see empty state

### 3️⃣ **iOS App - Create Timer** (Add functionality)

Implement:
- `Views/CreateTimerView.swift`
- `Views/Components/IconButton.swift`
- `Views/Components/ColorButton.swift`

**Test:** Create a timer → It should appear in list

### 4️⃣ **iOS App - Timer Detail** (Core feature)

Implement:
- `Views/TimerDetailView.swift`
- `Views/Components/TimerDisplayView.swift`
- `Views/Components/TimerControlsView.swift`
- `Services/TimerService.swift`

**Test:** Tap timer → Start/Pause/Reset should work

### 5️⃣ **iOS App - To-Dos & Notes**

Implement:
- `Views/Components/TodoListSectionView.swift`
- `Views/Components/TodoItemRow.swift`
- `Views/Components/NotesSectionView.swift`
- `Views/AddTodoView.swift`
- `Views/EditNotesView.swift`

**Test:** Add to-dos, toggle completion, add notes

### 6️⃣ **Watch Connectivity Service**

Implement (see `plans/02-watch-connectivity.md`):
- `Services/WatchConnectivityService.swift` (iOS version)
- `Services/WatchConnectivityService.swift` (watchOS version - simplified)

**Test:** Not yet (need watchOS app first)

### 7️⃣ **watchOS App**

Implement (see `plans/watchos/views-structure.md`):
- `Watch App/Views/TimerListView.swift`
- `Watch App/Views/TimerRowView.swift`
- `Watch App/Views/TimerDetailView.swift`
- `Watch App/Views/Components/...`

**Test on Watch Simulator:** Basic UI should work

### 8️⃣ **Test Sync on Real Devices**

- **Deploy to iPhone**: Connect iPhone via USB
- **Deploy to Watch**: Watch must be paired with iPhone
- **Test sync**: Create timer on iPhone → Should appear on Watch

### 9️⃣ **Notifications & Haptics**

Implement:
- `Services/NotificationService.swift`
- Add haptic feedback to buttons

### 🔟 **Polish & Testing**

- Add accessibility labels
- Test with VoiceOver
- Test with Dynamic Type (larger text)
- Add error handling
- Test edge cases

---

## 📚 Documentation Reference

All implementation details are in the `plans/` directory:

| File | Contents |
|------|----------|
| `00-overview.md` | Tech stack, architecture, features overview |
| `01-data-model.md` | SwiftData models, DTOs, serialization |
| `02-watch-connectivity.md` | Sync strategy, WCSession implementation |
| `ios/mockups.md` | All iOS screen designs (ASCII mockups) |
| `ios/views-structure.md` | Complete SwiftUI code for iOS views |
| `watchos/mockups.md` | All watchOS screen designs |
| `watchos/views-structure.md` | Complete SwiftUI code for watchOS views |

---

## 🧪 Testing Strategy

### Simulator Testing (Fast)

**iOS Simulator:**
- ✅ UI layout and navigation
- ✅ SwiftData persistence
- ✅ Timer countdown logic
- ✅ To-do CRUD operations
- ❌ Watch Connectivity (limited)

**watchOS Simulator (Paired):**
1. Xcode → Window → Devices and Simulators
2. Select Watch simulator
3. Pair with iPhone simulator
4. Run both apps

**Limitations:**
- Watch Connectivity works partially in simulator
- No real haptics
- No background tasks

### Real Device Testing (Required)

You **must test on real devices** for:
- ✅ Watch Connectivity sync (Bluetooth)
- ✅ Background timer behavior
- ✅ Notifications
- ✅ Haptic feedback
- ✅ Complications
- ✅ Always-On Display (Watch Series 5+)
- ✅ Battery impact

**Setup:**
1. Connect iPhone to Mac via USB
2. Open Xcode → Window → Devices and Simulators
3. Select your iPhone
4. Ensure Apple Watch is paired with iPhone
5. Xcode will detect Watch automatically

**Deploy:**
1. Select **TodoTimers** scheme → Your iPhone
2. Run (⌘R)
3. Select **TodoTimers Watch App** scheme → Your Watch
4. Run (⌘R)

---

## 🐛 Common Issues & Solutions

### Issue: "No accounts with App Store Connect access"

**Solution:**
1. Xcode → Settings → Accounts
2. Add your Apple ID
3. Free account works for development
4. For App Store submission, need paid Developer Program ($99/year)

### Issue: "Signing requires a development team"

**Solution:**
1. Select project → Target → Signing & Capabilities
2. Select your Team (Personal Team is fine)
3. Xcode will generate provisioning profile

### Issue: Watch app won't install

**Solution:**
1. Ensure Watch is unlocked
2. Watch must be on charger for first install
3. Wait a few minutes (watchOS deployment is slow)
4. Check Watch → Home Screen for app icon

### Issue: Watch Connectivity not working

**Solution:**
1. Ensure both apps running on real devices (not simulator)
2. iPhone and Watch must be paired
3. Bluetooth must be enabled
4. Apps must both call `WCSession.default.activate()`
5. Check logs: `print("WCSession state: \(session.activationState.rawValue)")`

### Issue: SwiftData not persisting

**Solution:**
1. Ensure `.modelContainer(for: [Timer.self, TodoItem.self])` is added to App
2. Check for SwiftData errors in console
3. Delete app and reinstall (clears corrupt data)

---

## 📖 Learning Resources

### Apple Documentation
- [SwiftData Documentation](https://developer.apple.com/documentation/swiftdata)
- [Watch Connectivity Framework](https://developer.apple.com/documentation/watchconnectivity)
- [Creating a watchOS App - Tutorial](https://developer.apple.com/tutorials/swiftui/creating-a-watchos-app)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)

### WWDC Videos
- **WWDC 2024**: "What's new in SwiftData"
- **WWDC 2023**: "Meet SwiftData"
- **WWDC 2023**: "Build programmatic UI with SwiftUI"
- **watchOS Videos**: Search "watchOS" on Apple Developer

### Community Resources
- [Hacking with Swift - SwiftUI](https://www.hackingwithswift.com/quick-start/swiftui)
- [Hacking with Swift - SwiftData](https://www.hackingwithswift.com/quick-start/swiftdata)

---

## 🎯 Success Milestones

Track your progress:

- [ ] Phase 1: Xcode project created with iOS + watchOS targets
- [ ] Phase 2: SwiftData models implemented and working
- [ ] Phase 3: iOS app shows timer list, can create timers
- [ ] Phase 4: iOS timer detail works (start/pause/reset)
- [ ] Phase 5: iOS to-dos and notes functional
- [ ] Phase 6: WatchConnectivityService implemented
- [ ] Phase 7: watchOS app shows synced timers
- [ ] Phase 8: Sync working on real devices
- [ ] Phase 9: Notifications and haptics working
- [ ] Phase 10: App polished and tested

---

## 🚀 Let's Build!

You're now ready to start implementing. Begin with **Phase 1: Project Setup** above, then follow the implementation order.

**Questions?** Refer to the detailed documentation in the `plans/` directory.

**Need help?** Each `.md` file contains complete code examples and explanations.

Happy coding! 🎉
