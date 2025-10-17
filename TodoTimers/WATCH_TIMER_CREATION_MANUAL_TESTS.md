# Watch Timer Creation - Manual Testing Checklist

**Date:** 2025-10-16
**Feature:** Watch Timer Creation (WatchCreateTimerView)
**Tester:** _____________
**Build:** _____________

## Prerequisites

- [ ] Build and run Watch app in Xcode simulator
- [ ] Verify iPhone simulator is paired with Watch simulator
- [ ] Confirm WatchConnectivityService shows "activated" in console
- [ ] Verify iPhone app is also running (for sync tests)

## Test 1: Basic Creation Flow

**Goal:** Create a timer with valid input and verify it appears in list

### Steps:
1. Launch Watch app in simulator
2. Tap "+" button in top-right toolbar
3. Enter timer name: "Test Timer"
4. Set duration to 5 minutes 30 seconds using pickers
5. Select "figure.run" icon from grid
6. Select green color from palette
7. Tap "Done" button

### Expected Results:
- [ ] Create sheet dismisses
- [ ] "Test Timer" appears in Watch timer list
- [ ] Timer shows 5:30 duration
- [ ] Timer shows run icon in green color
- [ ] Check iPhone app - timer synced with same properties

### Actual Results:
```
Pass: ☐  Fail: ☐  Notes: ____________________
```

---

## Test 2: Form Validation - Empty Name

**Goal:** Verify "Done" button is disabled when name is empty

### Steps:
1. Tap "+" button
2. Leave name field empty (default state)
3. Set duration to 1:00
4. Observe "Done" button state

### Expected Results:
- [ ] "Done" button is disabled/grayed out
- [ ] Tapping "Done" has no effect
- [ ] Cannot save timer with empty name

### Actual Results:
```
Pass: ☐  Fail: ☐  Notes: ____________________
```

---

## Test 3: Form Validation - Zero Duration

**Goal:** Verify "Done" button is disabled when duration is 0:00

### Steps:
1. Tap "+" button
2. Enter name: "Zero Test"
3. Set duration to 0 minutes, 0 seconds (default state)
4. Observe "Done" button state

### Expected Results:
- [ ] "Done" button is disabled/grayed out
- [ ] Tapping "Done" has no effect
- [ ] Cannot save timer with zero duration

### Actual Results:
```
Pass: ☐  Fail: ☐  Notes: ____________________
```

---

## Test 4: Cancel Behavior

**Goal:** Verify cancel doesn't save timer

### Steps:
1. Tap "+" button
2. Enter name: "Cancel Test"
3. Set duration to 2:00
4. Select book icon and blue color
5. Tap "Cancel" button

### Expected Results:
- [ ] Sheet dismisses
- [ ] No timer named "Cancel Test" in list
- [ ] No sync message sent to iPhone
- [ ] iPhone app shows no new timer

### Actual Results:
```
Pass: ☐  Fail: ☐  Notes: ____________________
```

---

## Test 5: Icon Selection

**Goal:** Verify all 6 icons can be selected

### Steps:
1. Tap "+" button
2. Tap each icon in grid:
   - timer
   - figure.run
   - book.fill
   - cup.and.saucer.fill
   - fork.knife
   - briefcase.fill
3. Observe visual selection state for each

### Expected Results:
- [ ] Each icon highlights with blue background when tapped
- [ ] Only one icon selected at a time
- [ ] Previously selected icon deselects
- [ ] Default selection is "timer" icon

### Actual Results:
```
Pass: ☐  Fail: ☐  Icons tested: ___/6
```

---

## Test 6: Color Selection

**Goal:** Verify all 4 colors can be selected

### Steps:
1. Tap "+" button
2. Tap each color button:
   - Red (#FF3B30)
   - Green (#34C759)
   - Blue (#007AFF)
   - Orange (#FF9500)
3. Observe visual selection state for each

### Expected Results:
- [ ] Each color shows white ring when selected
- [ ] Only one color selected at a time
- [ ] Previously selected color deselects
- [ ] Default selection is blue

### Actual Results:
```
Pass: ☐  Fail: ☐  Colors tested: ___/4
```

---

## Test 7: Sync - iPhone Reachable

**Goal:** Verify timer syncs to iPhone immediately when reachable

### Steps:
1. Ensure iPhone simulator is running and paired
2. Create timer on Watch:
   - Name: "Sync Test"
   - Duration: 10:00
   - Icon: briefcase
   - Color: orange
3. Tap "Done"
4. Switch to iPhone simulator
5. Open TodoTimers app

### Expected Results:
- [ ] Timer appears on iPhone within 2 seconds
- [ ] All properties match (name, duration, icon, color)
- [ ] Timer persists in iPhone's SwiftData
- [ ] Console shows "Timer update sent" or similar

### Actual Results:
```
Pass: ☐  Fail: ☐  Sync time: ___s
```

---

## Test 8: Sync - iPhone Unreachable

**Goal:** Verify graceful handling when iPhone is not reachable

### Steps:
1. Stop iPhone simulator (or disable Watch Connectivity)
2. Create timer on Watch:
   - Name: "Offline Test"
   - Duration: 5:00
3. Tap "Done"
4. Check console output

### Expected Results:
- [ ] Timer saves locally on Watch
- [ ] Timer appears in Watch timer list
- [ ] Console shows "Cannot send timer update: session not reachable"
- [ ] No crash or error dialog
- [ ] Timer persists on Watch after app restart

**Note:** Offline queue not yet implemented (TODO in code)

### Actual Results:
```
Pass: ☐  Fail: ☐  Notes: ____________________
```

---

## Test 9: Bi-Directional Sync

**Goal:** Verify Watch→iPhone sync doesn't break iPhone→Watch sync

### Steps:
1. Create timer on Watch: "Watch Timer 1"
2. Wait for sync to iPhone
3. Create timer on iPhone: "iPhone Timer 1"
4. Check Watch app

### Expected Results:
- [ ] "Watch Timer 1" appears on iPhone
- [ ] "iPhone Timer 1" appears on Watch
- [ ] Both timers persist on both devices
- [ ] No conflicts or duplicates

### Actual Results:
```
Pass: ☐  Fail: ☐  Notes: ____________________
```

---

## Test 10: Edge Case - Long Name

**Goal:** Verify UI handles long timer names

### Steps:
1. Tap "+" button
2. Enter name: "This is a very long timer name that exceeds typical length"
3. Set duration to 1:00
4. Tap "Done"

### Expected Results:
- [ ] Name saves without truncation
- [ ] Timer card displays name (may truncate with ellipsis)
- [ ] No crash or layout issues
- [ ] Syncs to iPhone correctly

### Actual Results:
```
Pass: ☐  Fail: ☐  Name length: ___chars
```

---

## Test 11: Edge Case - Maximum Duration

**Goal:** Verify maximum duration (59:59) works

### Steps:
1. Tap "+" button
2. Enter name: "Max Duration"
3. Set duration to 59 minutes, 59 seconds
4. Tap "Done"

### Expected Results:
- [ ] Duration saves as 59:59
- [ ] Displays as 59:59 in timer list
- [ ] Syncs to iPhone correctly
- [ ] No overflow or calculation errors

### Actual Results:
```
Pass: ☐  Fail: ☐  Notes: ____________________
```

---

## Test 12: Edge Case - Minimum Duration

**Goal:** Verify minimum duration (0:01) works

### Steps:
1. Tap "+" button
2. Enter name: "Min Duration"
3. Set duration to 0 minutes, 1 second
4. Tap "Done"

### Expected Results:
- [ ] Duration saves as 0:01
- [ ] Displays as 0:01 in timer list
- [ ] "Done" button is enabled (not zero)
- [ ] Syncs to iPhone correctly

### Actual Results:
```
Pass: ☐  Fail: ☐  Notes: ____________________
```

---

## Test 13: Edge Case - Rapid Creation

**Goal:** Verify app handles rapid timer creation

### Steps:
1. Create 5 timers in quick succession:
   - "Rapid 1" - 1:00
   - "Rapid 2" - 2:00
   - "Rapid 3" - 3:00
   - "Rapid 4" - 4:00
   - "Rapid 5" - 5:00
2. Check Watch list
3. Check iPhone list

### Expected Results:
- [ ] All 5 timers appear on Watch
- [ ] All 5 timers appear on iPhone
- [ ] No crashes or data loss
- [ ] Timers sorted correctly (by creation date)

### Actual Results:
```
Pass: ☐  Fail: ☐  Timers created: ___/5
```

---

## Test 14: Edge Case - iPhone Backgrounded

**Goal:** Verify sync works when iPhone app is backgrounded

### Steps:
1. Open iPhone app, then background it (Home button)
2. Create timer on Watch: "Background Test"
3. Wait 5 seconds
4. Switch back to iPhone app

### Expected Results:
- [ ] Timer appears on iPhone when foregrounded
- [ ] Background WCSession delivery works
- [ ] No data loss

### Actual Results:
```
Pass: ☐  Fail: ☐  Notes: ____________________
```

---

## Test 15: Edge Case - iPhone App Closed

**Goal:** Verify behavior when iPhone app is terminated

### Steps:
1. Fully quit iPhone app (swipe up in app switcher)
2. Create timer on Watch: "Closed Test"
3. Check Watch console for errors
4. Launch iPhone app

### Expected Results:
- [ ] Timer saves locally on Watch
- [ ] Console may show "not reachable" warning
- [ ] When iPhone app launches, sync occurs
- [ ] Timer appears on iPhone after launch

**Note:** Background message delivery may not work when app is fully closed

### Actual Results:
```
Pass: ☐  Fail: ☐  Notes: ____________________
```

---

## Summary

**Tests Passed:** ___/15
**Tests Failed:** ___/15
**Blockers Found:** ___

### Critical Issues:
```
1. ____________________
2. ____________________
3. ____________________
```

### Minor Issues:
```
1. ____________________
2. ____________________
3. ____________________
```

### Recommendations:
```
____________________
____________________
____________________
```

### Sign-off:
```
Tested By: _____________
Date: _____________
Build Version: _____________
Ready for Automated Tests: ☐ Yes  ☐ No
```
