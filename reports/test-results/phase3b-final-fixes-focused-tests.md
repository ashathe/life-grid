# Phase 3B Final Fixes — Focused Test Evidence

- Verification date: 2026-07-21 (America/New_York)
- Base revision: `a096b4058f8badae1690880552e0d473c0f5ed74`
- Device: iPhone 17 Pro Simulator, iOS 26.5 (23F77)
- Device UDID: `F2492AA8-2640-4FD9-B9F3-D856A407F2F8`
- Scope: Final-review persistence-result, repeat/haptic, stable-identity, relaunch, and feedback corrections only

## RED

Command:

```text
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -quiet \
  -project LifeGrid.xcodeproj -scheme LifeGrid \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -only-testing:LifeGridTests/AppStateStoreTests \
  -only-testing:LifeGridTests/CommanderDamageChangeTests \
  -only-testing:LifeGridTests/OpponentDamageInteractionTests \
  -resultBundlePath /tmp/phase3b-final-red.9UYJ4u/result.xcresult
```

Expected result: `** TEST FAILED **` during compilation because the tests referenced the not-yet-implemented `OpponentMutationResult`, stable exact-entry identifier/feedback helpers, and `OpponentDamageInteractionController`. The failure was the intended RED: the requested production contracts did not exist.

## Focused GREEN

The same selected unit suites were rerun after the minimal production changes with a fresh result bundle at `/tmp/phase3b-final-green.ilZQg3/result.xcresult`.

Result: Passed, 44 tests, 0 failed, 0 skipped.

Covered behavior includes:

- add and primary-damage save failures report `retainedInMemory` while preserving the in-memory mutation;
- successful saves report `persisted`, and rejected/no-op intents report `rejected`;
- the appended opponent retains prior IDs/order and appears last in the saved snapshot;
- production opponent hold-repeat uses the approved 350 ms initial delay and 120 ms interval;
- one real repeat mutation records exactly one adjustment haptic;
- a repeated decrement at zero records no haptic and no save;
- gesture cancellation stops repeats and permits a later hold;
- exact-entry identifiers include the opponent UUID and feedback distinguishes a missing opponent from other rejection/save outcomes.

## UI runner recovery and selected UI GREEN

The first selected UI attempt produced no app test result because the simulator rejected the UI runner launch:

```text
Simulator device failed to launch com.ashathe.lifegrid.uitests.xctrunner.
The request was denied by service delegate (SBMainWorkspace) for reason:
Busy ("Application failed preflight checks").
```

At that time the exact selected UDID was `Shutdown`, no Life Grid runner remained active, and the already-completed focused unit result was still Passed (44/44). No app code was changed for this infrastructure failure.

Recovery:

```text
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun simctl boot F2492AA8-2640-4FD9-B9F3-D856A407F2F8
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun simctl bootstatus F2492AA8-2640-4FD9-B9F3-D856A407F2F8 -b
```

`bootstatus -b` reached terminal `Finished`, and `simctl list devices` reported the exact UDID `Booted`.

The known existing smoke test `testFourTabsRemainAvailable` then passed 1/1 with a fresh result bundle. Only after that pass, the two selected affected UI tests were rerun:

```text
- testOpponentCardsAddDamageAndPersist
- testPrimaryDamageExactEntryLethalAndInvalidInput
```

Result: Passed, 2 tests, 0 failed, 0 skipped. The add flow now asserts `Opponent 4` exists after relaunch, and the invalid exact-entry flow proves the sheet remains present through its text field and navigation title without relying on a shared identifier.

## Final artifacts

- Full suite: `reports/test-results/phase3b-tests.xcresult`
  - Result: Passed
  - Logical tests: 106 passed, 0 failed, 0 skipped
  - Device executions: 120 passed
- iPhone build: `reports/test-results/phase3b-iphone-build.xcresult`
  - Status: succeeded
  - Errors: 0
  - Warnings: 0

The stable Game screenshot was not regenerated because these correctness and failure-state changes do not alter the captured successful-state appearance.
