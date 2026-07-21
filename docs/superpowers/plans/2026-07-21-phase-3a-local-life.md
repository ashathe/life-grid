# Life Grid Phase 3A — iPhone Local Life Plan

> **For Codex:** Follow `superpowers:executing-plans` to execute this plan task-by-task, with the user approval gate after the completed Phase 3A evidence review.

**Goal:** Replace the Phase 2 neutral active-game summary with the first approved iPhone gameplay slice: a persisted local-life card with split tap/hold controls, signed exact entry, temporary grouped Undo, haptic repeat feedback, and one local commander-tax row.

**Architecture:** `AppStateStore` stays the only writer of persisted game state. The Game feature owns transient interaction state: the four-second undo window and repeat gesture task. A small value type makes each persisted life mutation observable to the UI without persisting undo history. A UIKit-backed `HapticsClient` delivers feedback only for held-repeat ticks and only when the existing preference is enabled.

**Tech stack:** Swift 6, SwiftUI, Observation, UIKit haptics, Swift Testing, XCTest UI tests, Xcode/iPhone simulator.

## Scope and authority

This plan implements the first independently usable slice of Phase 3 from `docs/approved/Life_Grid_Codex_Implementation_Prompt.md` and Sections 10–11 of `docs/approved/Life_Grid_Product_Spec.md`.

`changes/CR-002-iphone-primary-delivery.md` is controlling for delivery scope: implement, test, build, screenshot, and review **iPhone portrait only**. Keep `TARGETED_DEVICE_FAMILY = "1,2"`; do not delete iPad eligibility or add iPad-specific code, tests, screenshots, builds, or claims of verification.

### Included requirements

| Requirement | Phase 3A behavior |
| --- | --- |
| LIFE-001 | Show saved local player name, falling back to `You`. Editing the name is deferred to the approved Settings/local-menu work. |
| LIFE-002, LIFE-003 | Entire left/right life-control halves persist −1/+1. |
| LIFE-004 | A hold performs the immediate first adjustment then repeats one point at a time; the complete hold is one Undo operation. |
| LIFE-005, LIFE-006 | Tapping the total opens signed whole-number entry; submitting any representable `Int`, including a negative value, persists it. |
| LIFE-007 | One direct manual life Undo is visible for four seconds; a newer direct manual operation replaces it. |
| CMD-001, CMD-002 | When commander mode is enabled and own Partner Commander is off, show a non-pinnable local tax row with −2/+2 controls and a floor of zero. |
| CMD-003 | Respect the persisted default-on `commanderEnabled` preference. The Settings control that changes it is deferred. |

### Explicitly deferred

- Local-name editing, commander naming, and Own Partner Commander configuration/UI (CMD-004 through CMD-007).
- Opponent cards, opponent commander damage, linked commander-damage life changes, lethal warnings, statuses, add/hide/restore, pinned counters, and the Out of Game tray.
- Landscape and all iPad-specific design or verification.
- Any change to the four-tab shell, New Game flow, settings default-starting-life ownership, schema version, target device family, networking, cloud, opponent life, or Initiative.

## Interaction contract

1. `LocalLifeCard` renders the current local life using `store.state.activeGame.currentLife`, the saved local name (or `You`), and helper text exactly: `Tap ±1 · Hold to repeat · Tap life total to set`.
2. The life row is a full-width control: the left half invokes `-1`, the right half invokes `+1`, and the central total invokes exact entry. Each touch target is at least 44 by 44 points.
3. A press applies its first ±1 immediately. If the press remains down for 0.35 seconds, a repeating task applies another ±1 every 0.12 seconds until release. Only the changes after the first are repeat ticks and request the light adjustment haptic.
4. A press/hold captures the pre-press value once. Repeats update the rendered and persisted value immediately but do not replace the pending Undo. Releasing makes the entire sequence one Undo operation back to the captured value.
5. A tap of the total presents a compact `Set Life Total` sheet with a signed decimal keypad field seeded with the current total. Empty, nonnumeric, or overflowing input stays open with accessible inline error text; valid whole-number input applies one exact manual operation. Negative totals are valid.
6. A manual tap, finished hold, or valid exact entry replaces the previous pending Undo, cancels its dismissal task, and shows `Undo` for four seconds. Undo restores the captured value, clears the affordance, and never creates another Undo.
7. The local tax row appears only while `preferences.commanderEnabled` is true. Phase 3A always uses the already-persisted A tax field because own-partner setup is deferred and defaults off. −2 clamps at zero; +2 has no arbitrary ceiling. Tax changes never create a life Undo.
8. Save failures retain existing store behavior: state remains usable in memory and the existing non-destructive persistence banner appears. The feature never writes persisted state directly.

## File map

| Path | Action | Purpose |
| --- | --- | --- |
| `LifeGrid/App/AppStateStore.swift` | Modify | Add explicit local-life and commander-tax intents that use the existing serialized persistence path. |
| `LifeGrid/App/AppEnvironment.swift` | Modify | Provide the UIKit haptics implementation in the live dependency graph. |
| `LifeGrid/Shared/Feedback/HapticsClient.swift` | Modify | Add the UIKit-backed implementation while retaining `NoOpHapticsClient`. |
| `LifeGrid/Features/Game/ManualLifeChange.swift` | Create | Define the returned manual-change result and commander-tax slot. |
| `LifeGrid/Features/Game/RepeatActionButton.swift` | Create | Encapsulate immediate press plus cancellable hold-repeat gesture behavior. |
| `LifeGrid/Features/Game/LocalLifeCard.swift` | Create | Render the local card, signed exact-entry alert, and temporary Undo state. |
| `LifeGrid/Features/Game/ActiveGameSummaryScreen.swift` | Modify | Replace the neutral summary body with the iPhone portrait Game screen composition and keep the existing New Game toolbar/sheet. |
| `LifeGrid.xcodeproj/project.pbxproj` | Modify | Add each new source/test file to its correct target and remove no platform support. |
| `LifeGridTests/App/AppStateStoreTests.swift` | Modify | Test all new persisted intents, no-active-game behavior, floor, and save snapshots. |
| `LifeGridTests/Features/Game/ManualLifeChangeTests.swift` | Create | Test value semantics used by the UI’s Undo contract. |
| `LifeGridTests/Features/Game/RepeatActionButtonTests.swift` | Create | Test repeat scheduling/cancellation with an injected clock rather than wall-clock sleeps. |
| `LifeGridUITests/LifeGridUITests.swift` | Modify | Cover the user-visible local life, exact signed entry, Undo, tax, persistence, and retained New Game flow on iPhone. |
| `protocol/requirements.json` | Modify at verification only | Add Phase 3A source, test, and evidence paths; mark only evidenced included requirements as `verified`. |
| `reviews/visuals/game/phase3a-local-life-comparison.md` | Create at verification only | Compare the iPhone local card to the approved Game iPhone reference and state all deferred regions. |
| `reports/test-results/phase3a-iphone-build.xcresult` | Create at verification only | iPhone build result bundle. |
| `reports/test-results/phase3a-tests.xcresult` | Create at verification only | Complete Phase 3A test result bundle. |
| `reports/test-results/phase3a-game-iphone.png` | Create at verification only | iPhone Game-screen screenshot. |
| `reports/test-results/phase3a-verification.md` | Create at verification only | Commands, results, screenshots, requirement links, and CR-002 iPad deferral statement. |

## Task 1 — Persisted local life and commander tax (test first)

**Files:**
- Modify: `LifeGrid/App/AppStateStore.swift`
- Create: `LifeGrid/Features/Game/ManualLifeChange.swift`
- Modify: `LifeGridTests/App/AppStateStoreTests.swift`
- Create: `LifeGridTests/Features/Game/ManualLifeChangeTests.swift`
- Modify: `LifeGrid.xcodeproj/project.pbxproj`

1. Write failing `AppStateStoreTests` for each public intent below using a fixture active game and `ScriptedAppStateRepository`:
   - ±1 changes `currentLife`, accepts a negative result, persists exactly one complete snapshot, and returns the prior/current values.
   - exact entry accepts `Int.min` and `Int.max` when no arithmetic is necessary, returns the prior/current values, and persists one snapshot.
   - all three life intents are no-ops and return `nil` when no active game exists.
   - A-tax ±2 persists, never falls below zero, leaves current life unchanged, and is a no-op without an active game.
   - each intent inherits the existing failed-load protection and failed-save in-memory behavior by routing through `mutateAndPersist`.
2. Add the minimal feature types:

   ```swift
   struct ManualLifeChange: Equatable, Sendable {
       let previousValue: Int
       let currentValue: Int
   }

   enum LocalCommanderTaxSlot: Equatable, Sendable {
       case primary
       case partner
   }
   ```

   `ManualLifeChangeTests` must assert its equality semantics, including a negative current value; it is the stable handoff between persisted mutation and transient Undo state.
3. Add these store methods without exposing mutable state:

   ```swift
   @discardableResult
   func changeLocalLife(by amount: Int) async -> ManualLifeChange?

   @discardableResult
   func setLocalLife(to value: Int) async -> ManualLifeChange?

   func restoreLocalLife(to value: Int) async

   func playHaptic(_ event: HapticEvent) async

   func adjustLocalCommanderTax(
       _ slot: LocalCommanderTaxSlot,
       by amount: Int
   ) async
   ```

   The life/tax methods must first establish an active game, then call one `mutateAndPersist` closure. For `changeLocalLife`, use `addingReportingOverflow`; on overflow return `nil` with no mutation. `restoreLocalLife` only writes `currentLife` and has no `ManualLifeChange` return, preventing recursive undo creation. `playHaptic` calls `environment.haptics.play(event)` only when `state.preferences.hapticsEnabled` is true; it never persists. Tax maps `.primary` to `ownCommanderTaxA` and `.partner` to `ownCommanderTaxB`, using `max(0, value.addingReportingOverflow(amount).partialValue)` only when the addition did not overflow; on overflow it makes no mutation.
4. Add the two new Swift files to the LifeGrid and LifeGridTests source build phases and groups in `project.pbxproj`. Do not change `TARGETED_DEVICE_FAMILY`.
5. Run focused tests, then commit only this coherent domain slice:

   ```bash
   xcodebuild test -project LifeGrid.xcodeproj -scheme LifeGrid \
     -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
     -only-testing:LifeGridTests/AppStateStoreTests \
     -only-testing:LifeGridTests/ManualLifeChangeTests \
     -resultBundlePath reports/test-results/phase3a-task1-tests.xcresult
   git add LifeGrid LifeGridTests LifeGrid.xcodeproj/project.pbxproj reports/test-results/phase3a-task1-tests.xcresult
   git commit -m "feat: add persisted local life intents"
   ```

## Task 2 — Repeat interaction and live haptic client (test first)

**Files:**
- Create: `LifeGrid/Features/Game/RepeatActionButton.swift`
- Create: `LifeGridTests/Features/Game/RepeatActionButtonTests.swift`
- Modify: `LifeGrid/Shared/Feedback/HapticsClient.swift`
- Modify: `LifeGrid/App/AppEnvironment.swift`
- Modify: `LifeGrid.xcodeproj/project.pbxproj`

1. Define a testable `RepeatActionSchedule` (not a view-only timing constant):

   ```swift
   struct RepeatActionSchedule: Equatable, Sendable {
       let initialDelay: Duration
       let interval: Duration

       static let localLife = Self(
           initialDelay: .milliseconds(350),
           interval: .milliseconds(120)
       )
   }
   ```

2. Write the red tests around `RepeatActionDriver`, an `@MainActor` observable helper injected with a `RepeatActionSchedule` and a sleep closure. Assert that `begin` invokes `onInitial` once immediately, performs no repeat before the delay, invokes repeat at the interval, and `end`/`cancel` prevents all later repeats. Use a controllable test sleep continuation; do not make unit tests wait 0.35 seconds.
3. Implement `RepeatActionDriver` and a `RepeatActionButton` view. The view uses `DragGesture(minimumDistance: 0)` to call `driver.begin` on first touch and `driver.end` on release/cancel. It must use `contentShape(Rectangle())`, a 44-point minimum height, `Button` accessibility traits/label/hint, and one actor-safe task for each resulting intent. It must not make an automatic haptic on the initial tap.
4. Implement `UIKitHapticsClient` in `HapticsClient.swift` with UIKit imported conditionally for iOS. Its `.adjustment` event calls `UIImpactFeedbackGenerator(style: .light).impactOccurred()` on the main actor. Other existing `HapticEvent` values retain a deliberate non-crashing mapping. Keep `NoOpHapticsClient` for tests and previews.
5. Change `AppEnvironment.live()` to inject `UIKitHapticsClient()`; tests continue injecting `RecordingHapticsClient`.
6. Run the focused tests and commit:

   ```bash
   xcodebuild test -project LifeGrid.xcodeproj -scheme LifeGrid \
     -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
     -only-testing:LifeGridTests/RepeatActionButtonTests \
     -only-testing:LifeGridTests/AppEnvironmentTests \
     -resultBundlePath reports/test-results/phase3a-task2-tests.xcresult
   git add LifeGrid LifeGridTests LifeGrid.xcodeproj/project.pbxproj reports/test-results/phase3a-task2-tests.xcresult
   git commit -m "feat: add life repeat feedback"
   ```

## Task 3 — Local life card, exact signed input, and grouped Undo (test first)

**Files:**
- Create: `LifeGrid/Features/Game/LocalLifeCard.swift`
- Modify: `LifeGrid/Features/Game/RepeatActionButton.swift`
- Modify: `LifeGridTests/Features/Game/ManualLifeChangeTests.swift`
- Modify: `LifeGrid.xcodeproj/project.pbxproj`

1. Extend the feature tests first with a `LocalLifeUndoState` value type:

   ```swift
   struct LocalLifeUndoState: Equatable, Sendable {
       let restoreValue: Int
       let operationID: UUID
   }
   ```

   Put `LocalLifeUndoState` beside `ManualLifeChange` so the test target can exercise it without rendering a view. Test that a replacement operation has a new ID and value, and that direct life changes—including negative values—can be represented. The four-second display timing itself belongs to the view task and is verified at UI level.
2. Implement `LocalLifeCard` with these explicit inputs:

   ```swift
   struct LocalLifeCard: View {
       @Bindable var store: AppStateStore
       let game: ActiveGame
   }
   ```

   Use `@State` for exact-entry text/error/presentation, current `LocalLifeUndoState?`, and its cancellation task. Display a name of `You` when `store.state.preferences.playerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty`.
3. Implement `applyManualDelta(_:)`, `applyExactLife()`, and `finishHeldOperation()` as the only paths that create/replace Undo. `applyManualDelta` calls `changeLocalLife`; the first press of a hold stores its original life once. A repeat calls `changeLocalLife` and then `await store.playHaptic(.adjustment)`; the store enforces the haptics preference, so `AppEnvironment` never leaks into the view. `finishHeldOperation` schedules a cancellable `Task.sleep(for: .seconds(4))` that clears only its matching operation ID.
4. Present exact entry as a compact SwiftUI `.sheet` titled `Set Life Total` with a `TextField("Life total", text: $exactLifeText)`, Cancel, and Set. The Set action parses `Int(exactLifeText)`; validation error is `Enter a whole-number life total.` and keeps the sheet presented until corrected or cancelled. Use `.keyboardType(.numbersAndPunctuation)`, seed the field from the current total, and give the form identifier `life-exact-entry`.
5. Render each side with `RepeatActionButton`; expose identifiers `life-decrement`, `life-increment`, `life-total`, and `life-undo`. The central value is a separate 44-point `Button`, so the value does not overlap either half’s hit target. Include the helper copy exactly once.
6. Render the commander tax section only when `store.state.preferences.commanderEnabled`. In this slice, only render the primary tax row, label it `Commander Tax`, and use `commander-tax-decrement`/`commander-tax-increment` identifiers. Both buttons call `adjustLocalCommanderTax(.primary, by: -2/+2)`. No tax control interacts with Undo or the haptics repeat feature.
7. Run focused compile/tests and commit:

   ```bash
   xcodebuild test -project LifeGrid.xcodeproj -scheme LifeGrid \
     -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
     -only-testing:LifeGridTests/ManualLifeChangeTests \
     -only-testing:LifeGridTests/AppStateStoreTests \
     -resultBundlePath reports/test-results/phase3a-task3-tests.xcresult
   git add LifeGrid LifeGridTests LifeGrid.xcodeproj/project.pbxproj reports/test-results/phase3a-task3-tests.xcresult
   git commit -m "feat: add local life card"
   ```

## Task 4 — Integrate the iPhone Game screen and prove the UI flow (test first)

**Files:**
- Modify: `LifeGrid/Features/Game/ActiveGameSummaryScreen.swift`
- Modify: `LifeGrid/App/LifeGridRootView.swift` only if the existing routing needs a naming/accessibility update
- Modify: `LifeGrid/App/AppEnvironment.swift` and `LifeGrid/App/AppStateStore.swift` to recognize the commander-disabled test launch fixture
- Modify: `LifeGridUITests/LifeGridUITests.swift`

1. Update the first active-game UI test before implementation to expect `game-screen`, not the former `active-game-summary`, after starting a game. Preserve every New Game replacement and reset test, changing only that screen locator.
2. Add a focused UI test that starts a default game, taps `life-decrement`, verifies `39`, taps `life-increment`, verifies `40`, taps `life-undo`, verifies `39`, and terminates/relaunches to verify the persisted value. Capture `phase3a-local-life`.
3. Add UI coverage for exact entry: tap `life-total`, enter `-7`, confirm, verify `-7`, then Undo to the preceding value. Also enter invalid text and assert the inline exact-entry error remains visible without changing life.
4. Add UI coverage for commander tax: default game shows tax `0`; decrement remains `0`; increment produces `2`; it does not add a life Undo. In a launch fixture with `commanderEnabled = false`, verify the tax section is absent while life controls remain present. Add a `uiTestingCommanderDisabled` Boolean to `AppEnvironment`, initialized by `AppEnvironment.live()` only when `--ui-testing-commander-disabled` is present. After a successful `load`, `AppStateStore` applies that Boolean only to the loaded in-memory preference before the first Game action. It must have no effect without that explicit argument and must not alter production defaults or migration data.
5. Replace the neutral summary’s player/summary cards with a `NavigationStack`/`ScrollView` containing the local card at the top, preserving the New Game toolbar/sheet. Its `game-screen` identifier must be on the logical Game root. Do not add placeholders that resemble unimplemented counters, opponents, statuses, or warnings.
6. Keep the existing dark palette, card treatment, and compact centered iPhone portrait width. Use Dynamic Type-friendly wrapping/vertical growth and minimum 44-point targets. Provide labels/hints for both life halves, exact entry, Undo, and tax controls; life/tax values expose a current `accessibilityValue`.
7. Execute the single UI test class on iPhone and commit:

   ```bash
   xcodebuild test -project LifeGrid.xcodeproj -scheme LifeGrid \
     -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
     -only-testing:LifeGridUITests/LifeGridUITests \
     -resultBundlePath reports/test-results/phase3a-ui-tests.xcresult
   git add LifeGrid LifeGridUITests reports/test-results/phase3a-ui-tests.xcresult
   git commit -m "feat: show local life game screen"
   ```

## Task 5 — Full verification, traceability, visual review, and manual approval gate

**Files:**
- Modify: `protocol/requirements.json`
- Create: `reviews/visuals/game/phase3a-local-life-comparison.md`
- Create: `reports/test-results/phase3a-verification.md`
- Create: the result bundle/screenshot paths listed in the file map

1. Run the complete unit/UI test suite and an iPhone-only build. Discover the installed iPhone simulator name first with `xcrun simctl list devices available`; substitute that exact available iPhone destination in every command rather than assuming it is `iPhone 16 Pro`.

   ```bash
   xcodebuild test -project LifeGrid.xcodeproj -scheme LifeGrid \
     -destination 'platform=iOS Simulator,name=<available-iphone>' \
     -resultBundlePath reports/test-results/phase3a-tests.xcresult
   xcodebuild build -project LifeGrid.xcodeproj -scheme LifeGrid \
     -destination 'platform=iOS Simulator,name=<available-iphone>' \
     -resultBundlePath reports/test-results/phase3a-iphone-build.xcresult
   ```

2. Capture the active local-life game at the approved iPhone portrait size after testing normal life, negative exact life, the temporary Undo affordance, and commander tax. Save only `reports/test-results/phase3a-game-iphone.png`; do not run or capture iPad.
3. Write `reviews/visuals/game/phase3a-local-life-comparison.md` with: reference source, direct iPhone portrait visual comparison, card hierarchy, dark palette/typography/control-size/accessibility assessment, the exact helper text, and an explicit statement that counters/opponents/statuses/out-of-game are deferred—not visually claimed complete.
4. Update the ten included requirement records in `protocol/requirements.json` only after passing evidence:
   - `LIFE-001` through `LIFE-007`, plus `CMD-001`, `CMD-002`, and `CMD-003` (ten records total; `CMD-003` is verified only as default-preference respect, while the Settings toggle remains deferred and must be stated in `approved_variance`).
   - Add only actual implementation/test/evidence paths, including Phase 3A iPhone files and reports.
   - Preserve every existing verified entry and the original `game-ipad` visual-reference history; set each Phase 3A entry’s `approved_variance` to cite CR-002’s iPhone-only verification and its deferred subcapabilities.
   - Do not mark CMD-004+ or any opponent/status/counter/warning requirement verified.
5. Write `reports/test-results/phase3a-verification.md` with the exact discovered iPhone destination, command/output summaries, test counts, build outcome, screenshot paths, requirement mapping, persistence/relaunch result, accessibility checks, and: `iPad implementation and verification are deferred under changes/CR-002-iphone-primary-delivery.md; TARGETED_DEVICE_FAMILY remains 1,2.`
6. Self-review before committing:

   ```bash
   git diff --check
   rg -n "TODO|TBD|Gameplay controls arrive" LifeGrid/Features/Game LifeGridTests/Features/Game LifeGridUITests protocol/requirements.json reviews/visuals/game reports/test-results/phase3a-verification.md
   xcrun xcresulttool get test-results summary --path reports/test-results/phase3a-tests.xcresult
   git status --short
   ```

   Resolve any relevant result rather than suppressing it.
7. Commit verification artifacts and stop. Do not push or begin Phase 3B without a fresh user instruction.

   ```bash
   git add protocol/requirements.json reviews/visuals/game reports/test-results
   git commit -m "docs: verify Phase 3A local life"
   ```

## Completion criteria

- Every included interaction persists safely through `AppStateStore`, survives relaunch, and avoids overflow/negative-tax corruption.
- A hold produces one grouped Undo and transient Undo expiration/replacement works without persisting history.
- Exact entry accepts negative whole numbers and rejects invalid/overflowing text without changing saved life.
- Commander tax is local-only, ±2, floor-zero, respects commander mode, and does not interact with life Undo.
- Unit tests, iPhone UI tests, and iPhone build pass with recorded evidence.
- The visual comparison does not overclaim unimplemented Phase 3B systems.
- The user is shown the reviewed commit/evidence and explicitly approves before any later Phase 3 slice.
