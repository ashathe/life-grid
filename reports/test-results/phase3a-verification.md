# Life Grid Phase 3A Verification

- Verification date: 2026-07-21
- Reviewed implementation tip: `713c7001f099d437b58b7c0bc602e3f7f16051f5` (`feat: show local life game screen`)
- Xcode: 26.6 (17F113)
- Swift: 6.3.3
- Host: macOS 26.5.2 (25F84)
- Active delivery scope: iPhone portrait only under `changes/CR-002-iphone-primary-delivery.md`
- Manual approval: Required before any later Phase 3 slice

## Simulator discovery

The host's global `xcode-select` points to `/Library/Developer/CommandLineTools`, so every Xcode command below explicitly used `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`.

`DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun simctl list devices available` confirmed that no iPhone 16 Pro simulator is installed. The exact selected destination was:

`platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5`

- Device: iPhone 17 Pro
- OS: iOS 26.5 (23F77)
- UDID: `F2492AA8-2640-4FD9-B9F3-D856A407F2F8`
- Orientation used by the UI suite and screenshot: Portrait

No iPad command was run.

## Commands and outcomes

### Complete unit and UI suite

```text
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -project LifeGrid.xcodeproj -scheme LifeGrid -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' -derivedDataPath /tmp/life-grid-phase3a-task5-tests-followup -resultBundlePath reports/test-results/phase3a-tests.xcresult
```

Outcome: `** TEST SUCCEEDED **`.

`xcresulttool get test-results summary` reports 82 logical tests passed, 0 failed, 0 skipped, and 0 expected failures. Xcode's console split is 70 Swift Testing tests in 11 suites plus 12 XCTest UI tests. The device configuration reports 96 passed executions because parameterized Swift tests expand into multiple runs.

The result bundle contains zero `ActorIsolatedCall` issues. It does contain 18 warning issue records comprising nine distinct Xcode messages, each duplicated across actions, about not stripping signed XCTest, Testing, XCUI, and test-support binaries. These are non-failing toolchain diagnostics; this report does not claim that the test action is warning-free. The UI runner console also emitted non-failing simulator diagnostics about a missing debugger-version snapshot and duplicate WebCore/WebKit accessibility bundle classes.

### iPhone build

```text
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild build -project LifeGrid.xcodeproj -scheme LifeGrid -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' -derivedDataPath /tmp/life-grid-phase3a-task5-build-followup -resultBundlePath reports/test-results/phase3a-iphone-build.xcresult
```

Outcome: `** BUILD SUCCEEDED **`.

`xcresulttool get build-results` records status `succeeded`, error count 0, warning count 0, and the same iPhone 17 Pro / iOS 26.5 destination. The console emitted the nonblocking App Intents metadata message that extraction was skipped because the target has no AppIntents dependency.

### Result summaries

```text
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun xcresulttool get test-results summary --path reports/test-results/phase3a-tests.xcresult
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun xcresulttool get build-results --path reports/test-results/phase3a-iphone-build.xcresult
```

## Behavior and persistence results

| Area | Evidence | Result |
| --- | --- | --- |
| Local name | `ManualLifeChangeTests` and the portrait screenshot | Blank/whitespace resolves to `You`; a stored nonblank value is trimmed and displayed. Editing remains deferred. |
| Tap life controls | `AppStateStoreTests` and `testLocalLifeControlsUndoAndPersistence` | Left/right operations persist one complete snapshot and update by -1/+1. |
| Hold repeat | `RepeatActionButtonTests` and `ManualLifeChangeTests.localLifeCardHoldPersistsMultipleChangesWithOneUndo` | Driver tests cover immediate first action, 350 ms delay, 120 ms repeat interval, serialization, haptic repeat ticks, and cancellation. The integrated controller/store test persists three mutations from 40 through 43, exposes no Undo before release, then exposes one Undo restoring the pre-hold value 40; a second Undo returns false and writes no additional snapshot. |
| Exact and negative life | `exactLocalLifeEntryAcceptsIntegerBounds`, `testExactLifeEntryAcceptsNegativeUndoAndRejectsInvalidInput`, and JSON round-trip tests | Signed `Int` input including `-7`, `Int.min`, and `Int.max` is accepted when representable; invalid or overflowing text does not mutate state. |
| Undo | `ManualLifeChangeTests.localLifeCardUndoExpiresAfterExactlyFourSeconds`, the integrated grouped-hold test, `testLocalLifeControlsUndoAndPersistence`, `testExactLifeEntryAcceptsNegativeUndoAndRejectsInvalidInput`, and `testReplacingGameClearsPendingLifeUndo` | Integrated controller/store coverage proves one-shot restore after a grouped hold. The UI suite proves a newer persisted manual operation replaces the prior pending Undo, and exact entry is undoable. An injected controlled sleeper observes the exact `.seconds(4)` request, advances it without wall-clock delay, and proves Undo expires while life remains persisted at 41. Navigation/game replacement clears transient history. |
| Commander tax | `AppStateStoreTests`, `testCommanderTaxUsesTwoPointFloorWithoutLifeUndo`, and `testCommanderDisabledFixtureHidesTaxAndKeepsLifeControls` | Local A tax changes by two, floors at zero, rejects overflow, persists through the store, respects commander mode, leaves life unchanged, and creates no life Undo. |
| Save safety | `localLifeAndTaxIntentsRespectFailedLoadProtection` and `localLifeAndTaxIntentsRetainInMemoryStateAfterSaveFailure` | Unreadable initial state is protected; failed saves keep usable in-memory state and retry on later persistence. |
| Relaunch | `testLocalLifeControlsUndoAndPersistence` | After decrement, increment, and Undo produce `39`, the app is terminated and relaunched without a reset argument; Game resumes at `39`. |

`changeLocalLife(by:)` rejects arithmetic overflow without mutation. Exact entry performs no arithmetic and accepts the full `Int` range. Commander tax rejects overflowing addition and clamps valid negative movement to zero. These checks avoid overflow and negative-tax corruption.

## Screenshot and visual evidence

- `reports/test-results/phase3a-game-iphone.png`
  - 1206 x 2622 pixels (402 x 874 points)
  - Extracted from the refreshed final suite's `phase3a-local-life` attachment for `LifeGridUITests/testLocalLifeControlsUndoAndPersistence()`
  - Exported attachment: `30AC1149-2627-4F27-8C87-DC0AAEC50741.png`, timestamp `2026-07-21T22:14:10.875Z`
  - SHA-256: `027d06ec933532082be419b71de08723ab9070b2b948b52fb66c8aaee5f86aa7`; byte-for-byte comparison with the exported attachment passed
  - Stable post-Undo and pre-relaunch state: local life `39`, commander tax `0`
- `reviews/visuals/game/phase3a-local-life-comparison.md`
  - Direct comparison with page 3 of `docs/approved/Life_Grid_Approved_Designs.pdf`
  - Records shell/scale differences and explicitly defers later Game regions

The passing result bundle separately records normal +/-1 interaction, signed `-7` exact entry, invalid-entry rejection, transient Undo presence/use, commander tax floor/+2 behavior, and the commander-disabled state. Only the required iPhone portrait screenshot is retained.

## Accessibility checks

- Life decrement/increment regions are 72 points high; the exact-value button has an 88 x 72-point minimum.
- Commander-tax controls are 44 x 44 points; Undo has a 44-point minimum.
- Life controls, exact entry, Undo, and tax controls expose semantic labels and hints; life and tax expose current accessibility values.
- The player name permits two lines and keeps its full accessibility label. Native text styles and vertical growth support Dynamic Type without a fixed card height.
- The screenshot at the simulator's default Dynamic Type setting shows no clipped Phase 3A text.
- Reduce Motion was off for the capture. The Phase 3A interactions add no required animation, so their meaning does not depend on motion.
- No manual VoiceOver navigation session was performed; this report relies on source-level semantic checks and the UI automation's accessibility queries and values.

## Requirement mapping

| Requirement | Verified Phase 3A scope | Primary implementation and tests |
| --- | --- | --- |
| `LIFE-001` | Saved local name display with `You` fallback | `LocalLifeCard.swift`, `ManualLifeChangeTests.swift`, final screenshot |
| `LIFE-002`, `LIFE-003` | Persisted left/right -1/+1 controls | `AppStateStore.swift`, `LocalLifeCard.swift`, `AppStateStoreTests.swift`, local-life UI test |
| `LIFE-004` | Immediate tap plus cancellable hold repeat; multiple persisted hold mutations are grouped into exactly one post-release Undo restoring the pre-hold value | `RepeatActionButton.swift`, `ManualLifeChange.swift`, `LocalLifeCard.swift`, `RepeatActionButtonTests.swift`, `ManualLifeChangeTests.swift` |
| `LIFE-005`, `LIFE-006` | Signed exact whole-number entry, negative values, and invalid/overflow rejection | `LocalLifeCard.swift`, `AppStateStoreTests.swift`, exact-entry UI test |
| `LIFE-007` | One transient direct-manual-life Undo with replacement behavior, one-shot restore, exact four-second expiration, and nonpersistent history | `ManualLifeChange.swift`, `LocalLifeCard.swift`, `ManualLifeChangeTests.swift`, UI tests |
| `CMD-001`, `CMD-002` | Local primary tax row, +/-2, floor zero, overflow safety, and no life Undo | `AppStateStore.swift`, `LocalLifeCard.swift`, store and UI tests |
| `CMD-003` | Respect the persisted default-on commander preference and hide tax when disabled | `AppPreferences.swift`, `LocalLifeCard.swift`, commander-disabled UI fixture/test |

## Approved variance and deferred scope

- `LIFE-001` verifies display/fallback only; local-name editing in Settings and the local-card menu is deferred.
- `LIFE-004` grouped-hold behavior is verified deterministically through the same interaction controller and real app-state store used by `LocalLifeCard`; no claim depends on a flaky raw long-press UI duration.
- `LIFE-007` four-second expiration is verified with injected time control, while existing UI automation verifies replacement by a newer manual operation.
- `CMD-001` and `CMD-002` verify the one default primary local tax row; own-partner A/B selection, names, and configuration are deferred.
- `CMD-003` is verified only as default-preference respect. The production Settings toggle is deferred.
- `CMD-004` and later commander requirements remain unverified.
- Opponents, counters, statuses, lethal warnings, Add Opponent, pinned counters, and Out of Game remain unverified and are not visually claimed complete.
- The original `game-ipad` visual-reference history is preserved in the requirement manifest.

iPad implementation and verification are deferred under changes/CR-002-iphone-primary-delivery.md; TARGETED_DEVICE_FAMILY remains 1,2.

## Approval gate

The Phase 3A evidence is prepared for user review. This report does not authorize Phase 3B or any later Phase 3 slice; explicit user approval is required first.
