# Phase 3B Task 3 Focused Test Evidence

- Date: 2026-07-21 (America/New_York)
- Post-fix code commit under test: `e537083 test: cover opponent damage edge cases`
- Environment: Xcode at `/Applications/Xcode.app/Contents/Developer`; iPhone 17 Pro Simulator, iOS 26.5; scheme `LifeGrid`.
- Result bundle source: `/tmp/phase3b-task3-evidence.xcresult` (not staged or copied into the repository).

## Command

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test \
  -project LifeGrid.xcodeproj -scheme LifeGrid \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -only-testing:LifeGridTests/AppStateStoreTests \
  -only-testing:LifeGridUITests/LifeGridUITests/testPrimaryDamageExactEntryLethalAndInvalidInput \
  -only-testing:LifeGridUITests/LifeGridUITests/testCommanderDisabledFixtureHidesOpponentCardsWithoutBreakingLife \
  -resultBundlePath /tmp/phase3b-task3-evidence.xcresult
```

## Result summary

- Exit status: 0.
- `AppStateStoreTests`: 35 Swift Testing cases passed in one suite, including `repeatStyleDamageChangesAtThresholdAndZeroOnlyPersistRealMutations`.
- `testCommanderDisabledFixtureHidesOpponentCardsWithoutBreakingLife`: passed.
- `testPrimaryDamageExactEntryLethalAndInvalidInput`: passed.
- Total selected behavior tests: 37 passed, 0 failed.
- The XCTest compatibility wrapper also prints `Executed 0 tests`; Swift Testing reports its 35 cases separately, as shown by `Test run with 35 tests in 1 suite passed`.

## Warning context

- Xcode reported `DebuggerLLDB.DebuggerVersionStore.StoreError` / `no debugger version` while launching the simulator.
- CoreSimulator reported a duplicate `UIAccessibilityLoaderWebShared` implementation across WebCore and WebKit accessibility bundles.
- These are simulator/tooling warnings. The command completed with exit status 0 and all selected test results passed.
