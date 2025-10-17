# Next Steps for TodoTimers

## Current Status

**Completed Phases:**
- ✅ Phase 1: SwiftData models and database schema
- ✅ Phase 2: iOS App UI foundation
- ✅ Phase 3: Timer functionality and services
- ✅ Phase 4: Watch Connectivity infrastructure
- ✅ Phase 5: Todo management features
- ✅ Phase 6: Testing infrastructure (109+ tests: Unit, Integration, E2E)

**Build Status:** ✅ All targets compile successfully

**Test Status:** ⚠️ Tests added to project but need verification

---

## Immediate Next Steps

### 1. Verify Test Suite (Priority: High)
**Goal:** Ensure all 109+ tests pass and provide adequate coverage

**Tasks:**
- [ ] Run full test suite with ⌘U in Xcode
- [ ] Review test results in Test Navigator
- [ ] Fix any failing tests
- [ ] Verify code coverage meets targets:
  - Models: 80%+ coverage
  - Services: 70%+ coverage
  - ViewModels: 60%+ coverage
- [ ] Run tests on physical device (if available)

**Deliverable:** All tests passing with green checkmarks

---

### 2. Phase 7: watchOS App Views (Priority: High)
**Goal:** Build out the Watch app UI to display and interact with timers

**Current State:**
- ✅ Watch Connectivity Service implemented
- ✅ SwiftData models shared with Watch target
- ✅ WatchTimerListView implemented (displays synced timers)
- ✅ WatchTimerDetailView implemented (countdown display with controls)
- ✅ WatchTimerCard, WatchTimerDisplay, WatchTimerControls implemented
- ✅ WatchTodoList implemented (can toggle todos from Watch)
- ✅ Real-time sync with iPhone working
- ❌ Watch app cannot CREATE timers (read-only for timer creation)

**Completed Tasks:**
- [x] Design Watch app navigation structure
- [x] Implement TimerListView with synced timers
- [x] Implement TimerDetailView with countdown and controls
- [x] Implement quick actions (toggle todos, update notes)
- [x] Real-time sync with iPhone

**Remaining Tasks:**
- [ ] Add complications (Watch face widgets)
  - Show active timer countdown
  - Quick launch to timer detail
- [ ] Test Watch app on physical device

**Deliverable:** Fully functional Watch app that mirrors iPhone functionality

---

### 2a. Watch Timer Creation Feature (Priority: High)
**Goal:** Enable creating new timers directly on Apple Watch without requiring iPhone

**Current State:**
- ❌ Watch app can only VIEW timers synced from iPhone
- ❌ Empty state tells users: "Create timers on your iPhone"
- ✅ WatchPayloads already support `.created` message type
- ✅ Watch Connectivity infrastructure supports bi-directional sync

**Implementation Plan:**

**Phase 1: Create WatchCreateTimerView**
- [ ] Build new `WatchCreateTimerView.swift` with Watch-optimized UI
  - Text field for timer name with dictation support
  - Digital Crown-friendly duration picker (minutes + seconds only)
  - Compact icon grid (6 most common icons)
  - Compact color grid (4 primary colors)
  - Done/Cancel buttons with proper validation
- [ ] Implement form validation
  - Disable Done button when name is empty
  - Disable Done button when duration is zero
  - Show inline validation hints

**Phase 2: Integrate with WatchTimerListView**
- [ ] Add toolbar "+" button to `WatchTimerListView.swift`
- [ ] Add sheet presentation for `WatchCreateTimerView`
- [ ] Update empty state message to mention Watch creation capability
  - Change from: "Create timers on your iPhone"
  - Change to: "Tap + to create a timer"

**Phase 3: Local Persistence & Sync**
- [ ] Save new timer to local SwiftData on Watch
- [ ] Immediately sync to iPhone via `WatchConnectivityService.sendTimerUpdate(type: .created)`
- [ ] Handle offline scenario:
  - Queue sync message when iPhone unavailable
  - Show user indicator that sync is pending
  - Retry when connection restored
  - Handle sync conflicts (timestamp-based resolution)

**Phase 4: Testing**
- [ ] Test timer creation on Watch independently
- [ ] Verify sync: Watch → iPhone
- [ ] Verify bi-directional sync still works: iPhone → Watch
- [ ] Test offline creation and queued sync
- [ ] Test concurrent creation from both devices
- [ ] Test with iPhone app closed/backgrounded
- [ ] Test form validation (empty name, zero duration)

**Files to Create:**
- `TodoTimersWatch Watch App/Views/WatchCreateTimerView.swift`

**Files to Modify:**
- `TodoTimersWatch Watch App/Views/WatchTimerListView.swift` (add toolbar button + sheet)
- `TodoTimers/Services/WatchConnectivityService.swift` (verify offline queue handling)

**Deliverable:** Watch app can independently create timers with full iPhone sync

---

### 3. Phase 8: Notifications and Background Tasks (Priority: Medium)
**Goal:** Add timer completion notifications and background countdown support

**Tasks:**
- [ ] Implement local notifications
  - Request notification permissions
  - Schedule notification when timer completes
  - Custom notification sound/haptic
  - Notification actions (restart timer, mark todos complete)
- [ ] Background timer support
  - Continue countdown when app backgrounded
  - Update app badge with remaining time
  - Handle app suspension/termination
- [ ] Watch app notifications
  - Mirror iPhone notifications on Watch
  - Haptic feedback on timer completion
  - Quick actions from notification

**Deliverable:** Users receive notifications when timers complete

---

### 4. Phase 9: Polish and Refinement (Priority: Medium)
**Goal:** Improve UX, add animations, handle edge cases

**Tasks:**
- [ ] Add animations and transitions
  - Timer card animations
  - Countdown number transitions
  - Progress ring animations
  - Todo check/uncheck animations
- [ ] Improve error handling
  - User-friendly error messages
  - Graceful degradation when Watch unavailable
  - Network/sync error recovery
- [ ] Add accessibility features
  - VoiceOver support
  - Dynamic Type support
  - Haptic feedback
  - Reduce motion support
- [ ] Performance optimization
  - Profile with Instruments
  - Optimize SwiftData queries
  - Reduce Watch battery consumption
- [ ] Edge case handling
  - Multiple timers running simultaneously
  - Very long timer durations (hours)
  - Sync conflicts resolution
  - App version migration

**Deliverable:** Polished, production-ready app

---

### 5. Phase 10: App Store Preparation (Priority: Low)
**Goal:** Prepare app for App Store submission

**Tasks:**
- [ ] App Store assets
  - App icon (iOS and Watch versions)
  - Screenshots for all device sizes
  - App preview videos
  - App Store description and keywords
- [ ] Privacy and compliance
  - Privacy policy (if needed)
  - Data collection disclosure
  - Terms of service
- [ ] App Store Connect setup
  - Create app record
  - Configure pricing and availability
  - Add App Store screenshots
  - Write app description
- [ ] Beta testing
  - TestFlight setup
  - Internal testing
  - External beta testing
  - Collect feedback and iterate
- [ ] Final submission
  - Submit for App Review
  - Address review feedback
  - Launch!

**Deliverable:** App live on the App Store

---

## Technical Debt and Known Issues

### Current Issues
1. **Watch Timer Creation:** Watch app cannot create timers (read-only, must use iPhone)
2. **UI Tests:** 2 tests disabled due to hang issues when testing disabled button states
3. **No Notifications:** Timer completion requires app to be open
4. **No Background Support:** Timers pause when app backgrounded
5. **No Watch Complications:** Watch face widgets not yet implemented

### Future Enhancements (Post-Launch)
- [ ] iCloud sync (replace Watch Connectivity for multi-device sync)
- [ ] Widget support (iOS Lock Screen and Home Screen)
- [ ] Apple Watch complications
- [ ] Siri shortcuts integration
- [ ] Timer templates and presets
- [ ] Timer history and analytics
- [ ] Export/import timer configurations
- [ ] Collaborative timers (share with other users)
- [ ] Apple Watch standalone mode (no iPhone required)

---

## Development Workflow

### Before Starting New Features
1. Create feature branch: `git checkout -b feature/watch-app-views`
2. Review relevant tests and documentation
3. Plan implementation in markdown (optional)

### During Development
1. Write tests first (TDD approach recommended)
2. Implement feature incrementally
3. Commit frequently with descriptive messages
4. Run tests after each major change

### Before Committing
1. Run full test suite: ⌘U
2. Check for build warnings
3. Review changes with `git diff`
4. Write clear commit message

### Merge to Main
1. Ensure all tests pass
2. Update README if needed
3. Create pull request (if working with team)
4. Merge and push to remote

---

## Questions and Decisions Needed

1. **Watch App Design:** Should Watch app support standalone mode (without iPhone)?
2. **Notification Strategy:** Use local notifications only, or also support remote notifications?
3. **iCloud Sync:** Add iCloud sync now or defer to post-launch?
4. **Monetization:** Free app, paid app, or freemium model?
5. **Target Devices:** Support older iOS/watchOS versions or latest only?

---

## Resources

- [Apple Human Interface Guidelines - watchOS](https://developer.apple.com/design/human-interface-guidelines/watchos)
- [Watch Connectivity Framework](https://developer.apple.com/documentation/watchconnectivity)
- [SwiftData Documentation](https://developer.apple.com/documentation/swiftdata)
- [User Notifications Framework](https://developer.apple.com/documentation/usernotifications)

---

**Last Updated:** 2025-10-16
