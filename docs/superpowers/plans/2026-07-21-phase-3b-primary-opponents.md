# Life Grid Phase 3B — Primary Opponent Cards Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver the first iPhone-only Commander opponent loop: persisted visible opponent cards, in-game Add Opponent, primary commander-damage controls, and optional linked local-life changes.

**Architecture:** `AppStateStore` remains the sole persistence writer. It updates one opponent’s damage and any linked local-life delta in one `mutateAndPersist` closure. `OpponentCard` owns presentation-only exact entry, and reuses the established `RepeatActionButton`; `ActiveGameSummaryScreen` only composes the ordered Game screen.

**Tech Stack:** Swift 6, SwiftUI, Observation, Swift Testing, XCTest UI tests, Xcode/iPhone simulator.

## Global Constraints

- Implement only `docs/superpowers/specs/2026-07-21-phase-3b-primary-opponents-design.md`; defer partner, rename, hide/restore, status, warning-banner, counter, Quick Restart, and Settings-control work.
- Do not display, infer, store, or test opponent life totals.
- iPhone portrait is the sole design, implementation, test, build, screenshot, and visual-review target under `changes/CR-002-iphone-primary-delivery.md`.
- Do not change `TARGETED_DEVICE_FAMILY = 1,2`, add iPad branches, or claim iPad verification.
- Every new direct target is at least 44 by 44 points, supports Dynamic Type growth, and has an opponent-specific accessibility label.
- Primary damage is a non-negative `Int`; 21+ uses destructive/red styling. Commander-damage changes never touch the Phase 3A life Undo.
- Use reporting-overflow arithmetic. A missing game/opponent, same exact value, decrement below zero, or overflow performs no mutation or persistence write.
- Use `apply_patch` for edits. Do not stage intermediate result bundles.

---

## File map

| Path | Action | Responsibility |
| --- | --- | --- |
| `LifeGrid/Models/OpponentState.swift` | Modify | Default-name allocation and factory. |
| `LifeGrid/Features/Game/CommanderDamageChange.swift` | Create | Store result type. |
| `LifeGrid/App/AppStateStore.swift` | Modify | Add/damage/life-link intents. |
| `LifeGrid/Features/Game/OpponentCard.swift` | Create | One visible card, repeat controls, exact sheet. |
| `LifeGrid/Features/Game/ActiveGameSummaryScreen.swift` | Modify | Commander-only Opponents composition. |
| `LifeGrid.xcodeproj/project.pbxproj` | Modify | Source registrations. |
| `LifeGridTests/Models/OpponentStateTests.swift` | Create | Name/factory tests. |
| `LifeGridTests/Features/Game/CommanderDamageChangeTests.swift` | Create | Result-type tests. |
| `LifeGridTests/App/AppStateStoreTests.swift` | Modify | Atomic persistence/safety tests. |
| `LifeGridUITests/LifeGridUITests.swift` | Modify | iPhone behavior and persistence tests. |
| `protocol/requirements.json` | Modify at verification only | Evidence-backed traceability. |
| `reviews/visuals/game/phase3b-primary-opponents-comparison.md` | Create at verification only | iPhone visual review. |
| `reports/test-results/phase3b-*` | Create at verification only | Result bundles, screenshot, report. |

## Task 1: Persisted opponent domain intents

**Files:**
- Modify: `LifeGrid/Models/OpponentState.swift`
- Create: `LifeGrid/Features/Game/CommanderDamageChange.swift`
- Modify: `LifeGrid/App/AppStateStore.swift`
- Create: `LifeGridTests/Models/OpponentStateTests.swift`
- Create: `LifeGridTests/Features/Game/CommanderDamageChangeTests.swift`
- Modify: `LifeGridTests/App/AppStateStoreTests.swift`
- Modify: `LifeGrid.xcodeproj/project.pbxproj`

**Interfaces produced:**

```swift
struct CommanderDamageChange: Equatable, Sendable {
    let previousDamage: Int
    let currentDamage: Int
    let previousLife: Int
    let currentLife: Int
}

extension OpponentState {
    static let maximumCount = 5
    static func nextDefaultDisplayName(in opponents: [OpponentState]) -> String
    static func newDefault(displayName: String) -> OpponentState
}

@discardableResult func addOpponent() async -> OpponentState?
@discardableResult func changePrimaryCommanderDamage(
    for opponentID: UUID, by amount: Int
) async -> CommanderDamageChange?
@discardableResult func setPrimaryCommanderDamage(
    for opponentID: UUID, to value: Int
) async -> CommanderDamageChange?
```

- [ ] **Step 1: Write failing model/result tests**

Create `LifeGridTests/Models/OpponentStateTests.swift`:

```swift
import Testing
@testable import LifeGrid

struct OpponentStateTests {
    @Test func nextDefaultNameUsesFirstUnusedCanonicalLabel() {
        let opponents = [
            OpponentState.newDefault(displayName: "Opponent 1"),
            OpponentState.newDefault(displayName: "Amanda"),
            OpponentState.newDefault(displayName: "Opponent 3"),
            OpponentState.newDefault(displayName: "opponent 2"),
        ]
        #expect(OpponentState.nextDefaultDisplayName(in: opponents) == "Opponent 2")
    }

    @Test func newDefaultOpponentHasOnlyPrimaryZeroState() {
        let opponent = OpponentState.newDefault(displayName: "Opponent 4")
        #expect(opponent.displayName == "Opponent 4")
        #expect(opponent.isVisible)
        #expect(opponent.primaryCommanderName == nil)
        #expect(opponent.primaryCommanderDamage == 0)
        #expect(opponent.partner == nil)
        #expect(!opponent.hasCitysBlessing)
    }
}
```

Create `LifeGridTests/Features/Game/CommanderDamageChangeTests.swift`:

```swift
import Testing
@testable import LifeGrid

struct CommanderDamageChangeTests {
    @Test func valuePreservesDamageAndLifeBoundaries() {
        let change = CommanderDamageChange(
            previousDamage: 20, currentDamage: 21,
            previousLife: 23, currentLife: 22
        )
        #expect(change.previousDamage == 20)
        #expect(change.currentDamage == 21)
        #expect(change.previousLife == 23)
        #expect(change.currentLife == 22)
    }
}
```

- [ ] **Step 2: Verify tests are red**

Run:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test \
  -project LifeGrid.xcodeproj -scheme LifeGrid \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -only-testing:LifeGridTests/OpponentStateTests \
  -only-testing:LifeGridTests/CommanderDamageChangeTests \
  -resultBundlePath /tmp/phase3b-task1-red.xcresult
```

Expected: compile failure because the factory, allocator, and result type do not exist.

- [ ] **Step 3: Write failing store tests**

Extend `LifeGridTests/App/AppStateStoreTests.swift` with an `activeGame(startingLife:opponentNames:)` fixture built through `ActiveGameFactory.make` using fixed opponent UUIDs. Add these tests plus explicit tests for exact-entry life delta, link-off, zero-floor/same-value no writes, missing opponent/no game, damage/life overflow, and independent two-opponent state:

```swift
@MainActor @Test func addOpponentAppendsDefaultAndStopsAtFive() async {
    var initial = PersistedAppState.default
    initial.activeGame = activeGame(startingLife: 40, opponentNames: [
        "Opponent 1", "Amanda", "Opponent 3", "Opponent 4",
    ])
    let repository = ScriptedAppStateRepository()
    let store = AppStateStore(environment: environment(repository: repository), initialState: initial)

    let added = await store.addOpponent()
    let blocked = await store.addOpponent()

    #expect(added?.displayName == "Opponent 2")
    #expect(store.state.activeGame?.opponents.count == 5)
    #expect(blocked == nil)
    #expect(await repository.savedSnapshots().count == 1)
}

@MainActor @Test func primaryDamageAtomicallyLinksLifeInBothDirections() async {
    var initial = PersistedAppState.default
    initial.activeGame = activeGame(startingLife: 40, opponentNames: ["Amanda"])
    let id = try! #require(initial.activeGame?.opponents[0].id)
    let repository = ScriptedAppStateRepository()
    let store = AppStateStore(environment: environment(repository: repository), initialState: initial)

    let up = await store.changePrimaryCommanderDamage(for: id, by: 3)
    let down = await store.changePrimaryCommanderDamage(for: id, by: -2)

    #expect(up == CommanderDamageChange(previousDamage: 0, currentDamage: 3, previousLife: 40, currentLife: 37))
    #expect(down == CommanderDamageChange(previousDamage: 3, currentDamage: 1, previousLife: 37, currentLife: 39))
    #expect(store.state.activeGame?.opponents[0].primaryCommanderDamage == 1)
    #expect(store.state.activeGame?.currentLife == 39)
    #expect(await repository.savedSnapshots().count == 2)
}
```

- [ ] **Step 4: Verify the store tests are red**

Run:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test \
  -project LifeGrid.xcodeproj -scheme LifeGrid \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -only-testing:LifeGridTests/AppStateStoreTests \
  -resultBundlePath /tmp/phase3b-task1-store-red.xcresult
```

Expected: compile failure because the intents do not exist.

- [ ] **Step 5: Implement model/result types**

Create `LifeGrid/Features/Game/CommanderDamageChange.swift`:

```swift
import Foundation

struct CommanderDamageChange: Equatable, Sendable {
    let previousDamage: Int
    let currentDamage: Int
    let previousLife: Int
    let currentLife: Int
}
```

Append this extension to `LifeGrid/Models/OpponentState.swift`:

```swift
extension OpponentState {
    static let maximumCount = 5

    static func nextDefaultDisplayName(in opponents: [OpponentState]) -> String {
        let occupied = Set(opponents.compactMap { opponent -> Int? in
            let prefix = "Opponent "
            guard opponent.displayName.hasPrefix(prefix),
                  let number = Int(opponent.displayName.dropFirst(prefix.count)),
                  number > 0 else { return nil }
            return number
        })
        var candidate = 1
        while occupied.contains(candidate) { candidate += 1 }
        return "Opponent \(candidate)"
    }

    static func newDefault(displayName: String) -> OpponentState {
        OpponentState(
            id: UUID(), displayName: displayName, isVisible: true,
            primaryCommanderName: nil, primaryCommanderDamage: 0,
            partner: nil, hasCitysBlessing: false
        )
    }
}
```

Only case-sensitive canonical `Opponent N` labels reserve a number; custom labels do not.

- [ ] **Step 6: Implement atomic store intents**

Add these methods above `saveForLifecycle()` in `LifeGrid/App/AppStateStore.swift`. Keep each accepted change in one `mutateAndPersist(onlyIf:)` closure.

```swift
@discardableResult
func addOpponent() async -> OpponentState? {
    var added: OpponentState?
    let didMutate = await mutateAndPersist(onlyIf: { state in
        guard var game = state.activeGame,
              game.opponents.count < OpponentState.maximumCount else { return false }
        let opponent = OpponentState.newDefault(
            displayName: OpponentState.nextDefaultDisplayName(in: game.opponents)
        )
        game.opponents.append(opponent)
        state.activeGame = game
        added = opponent
        return true
    })
    return didMutate ? added : nil
}

@discardableResult
func changePrimaryCommanderDamage(
    for opponentID: UUID, by amount: Int
) async -> CommanderDamageChange? {
    guard amount != 0 else { return nil }
    return await updatePrimaryCommanderDamage(for: opponentID) { current in
        let result = current.addingReportingOverflow(amount)
        guard !result.overflow else { return nil }
        return max(0, result.partialValue)
    }
}

@discardableResult
func setPrimaryCommanderDamage(
    for opponentID: UUID, to value: Int
) async -> CommanderDamageChange? {
    guard value >= 0 else { return nil }
    return await updatePrimaryCommanderDamage(for: opponentID) { _ in value }
}
```

Implement private `updatePrimaryCommanderDamage(for:transform:)` as follows: locate the active opponent by UUID; compute and reject unchanged targets; calculate `damageDelta`; if linked, use `previousLife.subtractingReportingOverflow(damageDelta)` (never unary negation) and reject overflow; update the selected damage and local life in the same `ActiveGame` value; set `state.activeGame`; return a complete `CommanderDamageChange`. Every guard failure must preserve the entire state and avoid a save.

- [ ] **Step 7: Register files, verify green, commit**

Register both source files and both new tests in their established Models/Game groups and LifeGrid/LifeGridTests build phases, using fresh PBX IDs. Then run:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test \
  -project LifeGrid.xcodeproj -scheme LifeGrid \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -only-testing:LifeGridTests/OpponentStateTests \
  -only-testing:LifeGridTests/CommanderDamageChangeTests \
  -only-testing:LifeGridTests/AppStateStoreTests \
  -resultBundlePath /tmp/phase3b-task1-tests.xcresult
git add LifeGrid/Models/OpponentState.swift \
  LifeGrid/Features/Game/CommanderDamageChange.swift \
  LifeGrid/App/AppStateStore.swift \
  LifeGridTests/Models/OpponentStateTests.swift \
  LifeGridTests/Features/Game/CommanderDamageChangeTests.swift \
  LifeGridTests/App/AppStateStoreTests.swift \
  LifeGrid.xcodeproj/project.pbxproj
git commit -m "feat: add persisted opponent damage"
```

Expected: selected tests pass with zero application-code warnings, followed by one coherent domain commit.

## Task 2: Render iPhone opponent cards

**Files:**
- Create: `LifeGrid/Features/Game/OpponentCard.swift`
- Modify: `LifeGrid/Features/Game/ActiveGameSummaryScreen.swift`
- Modify: `LifeGridUITests/LifeGridUITests.swift`
- Modify: `LifeGrid.xcodeproj/project.pbxproj`

**Consumes:** Task 1 intents, `RepeatActionButton`, `LifeGridPalette`, and `lifeGridCard()`.

**Produces:**

```swift
struct OpponentCard: View {
    @Bindable var store: AppStateStore
    let opponentID: UUID
}
```

`OpponentCard` looks up the live opponent by ID in `store.state.activeGame`; no stale captured opponent value may become authoritative.

- [ ] **Step 1: Write a failing primary card UI test**

Add to `LifeGridUITests/LifeGridUITests.swift`:

```swift
@MainActor
func testOpponentCardsAddDamageAndPersist() {
    let app = launchResetApp()
    startDefaultGame(in: app)

    XCTAssertTrue(app.buttons["add-opponent"].waitForExistence(timeout: 2))
    XCTAssertTrue(app.staticTexts["Opponent 1"].exists)
    XCTAssertFalse(app.staticTexts["Opponent 1 life"].exists)

    let total = app.buttons["Set Opponent 1's commander damage"]
    XCTAssertEqual(total.value as? String, "0")
    app.buttons["Add one commander damage from Opponent 1"].tap()
    assertValue("1", for: total)
    assertValue("39", for: app.buttons["life-total"])

    app.buttons["add-opponent"].tap()
    XCTAssertTrue(app.staticTexts["Opponent 4"].waitForExistence(timeout: 2))
    attachScreenshot(named: "phase3b-primary-opponents", app: app)

    app.terminate()
    let restored = launchPreservingApp()
    XCTAssertTrue(element("game-screen", in: restored).waitForExistence(timeout: 3))
    assertValue("1", for: restored.buttons["Set Opponent 1's commander damage"])
    assertValue("39", for: restored.buttons["life-total"])
}
```

- [ ] **Step 2: Verify the UI test is red**

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test \
  -project LifeGrid.xcodeproj -scheme LifeGrid \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -only-testing:LifeGridUITests/LifeGridUITests/testOpponentCardsAddDamageAndPersist \
  -resultBundlePath /tmp/phase3b-task2-red.xcresult
```

Expected: failure because the Opponents section is absent.

- [ ] **Step 3: Implement `OpponentCard`**

Create `LifeGrid/Features/Game/OpponentCard.swift` with this outer structure:

```swift
import SwiftUI

struct OpponentCard: View {
    @Bindable var store: AppStateStore
    let opponentID: UUID
    @State private var exactDamageText = ""
    @State private var exactDamageError: String?
    @State private var showsExactDamageEntry = false

    var body: some View {
        if let opponent = currentOpponent {
            VStack(alignment: .leading, spacing: 12) {
                Text(displayName(for: opponent)).font(.headline).lineLimit(2)
                Text("Commander Damage")
                    .font(.caption)
                    .foregroundStyle(LifeGridPalette.secondaryText)
                damageControls(for: opponent)
            }
            .foregroundStyle(LifeGridPalette.primaryText)
            .lifeGridCard()
            .sheet(isPresented: $showsExactDamageEntry) {
                exactDamageSheet(for: opponent)
            }
        }
    }

    private var currentOpponent: OpponentState? {
        store.state.activeGame?.opponents.first(where: { $0.id == opponentID })
    }
}
```

`damageControls(for:)` is a three-column `HStack(spacing: 0)` matching `LocalLifeCard.lifeControls`: left/right are `RepeatActionButton`s, have 72-point tall label views, and are separated from a central `.plain` exact-value `Button` by existing border dividers. Labels and central identifier must be exact:

```swift
let name = displayName(for: opponent)
// left accessibilityLabel: "Remove one commander damage from \(name)"
// right accessibilityLabel: "Add one commander damage from \(name)"
// central accessibilityLabel and identifier: "Set \(name)'s commander damage"
```

On initial press, call `applyDamageDelta(-1)` or `applyDamageDelta(1)`. On repeat, use this exact pattern so a no-op at zero does not haptic:

```swift
if await applyDamageDelta(1) {
    await store.playHaptic(.adjustment)
}
```

Implement the helper:

```swift
@MainActor
private func applyDamageDelta(_ amount: Int) async -> Bool {
    guard let change = await store.changePrimaryCommanderDamage(
        for: opponentID, by: amount
    ) else { return false }
    return change.currentDamage != change.previousDamage
}
```

The central value uses `.largeTitle.bold().monospacedDigit()`. At `>= 21`, foreground style is `LifeGridPalette.destructive` and accessibility value is `"\(damage), commander lethal"`; below it, accessibility value is `"\(damage)"`. Include no `life` text, partner row, status badge, menu button, or warning banner.

Use this corruption-safe name helper without altering stored state:

```swift
nonisolated static func displayName(for opponent: OpponentState) -> String {
    let trimmed = opponent.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? "Opponent" : trimmed
}
```

- [ ] **Step 4: Compose the Commander-only section**

In `LifeGrid/Features/Game/ActiveGameSummaryScreen.swift`, retain the ScrollView, NavigationStack, New Game toolbar/sheet, palette, and centered width. Replace the one-card body with a `VStack(alignment: .leading, spacing: 16)` that renders the existing `LocalLifeCard` then `opponentsSection` only when `store.state.preferences.commanderEnabled` is true.

```swift
private var opponentsSection: some View {
    VStack(alignment: .leading, spacing: 12) {
        HStack {
            Text("Opponents").font(.headline)
            Spacer()
            if game.opponents.count < OpponentState.maximumCount {
                Button("Add Opponent") {
                    Task { await store.addOpponent() }
                }
                .buttonStyle(.borderedProminent)
                .tint(LifeGridPalette.accent)
                .accessibilityHint("Adds a new opponent to this game")
                .accessibilityIdentifier("add-opponent")
            }
        }

        ForEach(game.opponents.filter(\.isVisible)) { opponent in
            OpponentCard(store: store, opponentID: opponent.id)
        }
    }
}
```

The stored count, not visible count, controls the maximum. Do not add an inactive overflow affordance simply to match a future design.

- [ ] **Step 5: Register source, verify green, and commit**

Register `OpponentCard.swift` in the Game group / LifeGrid source build phase. Re-run the Task 2 command, then commit:

```bash
git add LifeGrid/Features/Game/OpponentCard.swift \
  LifeGrid/Features/Game/ActiveGameSummaryScreen.swift \
  LifeGridUITests/LifeGridUITests.swift \
  LifeGrid.xcodeproj/project.pbxproj
git commit -m "feat: show primary opponent cards"
```

Expected: the UI test passes and its attachment shows local life followed by Opponents and cards only.

## Task 3: Exact entry, lethal state, disabled behavior, and repeat feedback

**Files:**
- Modify: `LifeGrid/Features/Game/OpponentCard.swift`
- Modify: `LifeGridUITests/LifeGridUITests.swift`
- Modify: `LifeGridTests/App/AppStateStoreTests.swift` only for any missing domain edge from Task 1

**Consumes:** Task 1 atomic intents and Task 2 identifiers.

- [ ] **Step 1: Write failing exact/lethal and disabled UI tests**

Add:

```swift
@MainActor
func testPrimaryDamageExactEntryLethalAndInvalidInput() {
    let app = launchResetApp()
    startDefaultGame(in: app)
    let total = app.buttons["Set Opponent 1's commander damage"]

    total.tap()
    let entry = app.textFields["Commander damage"]
    XCTAssertTrue(entry.waitForExistence(timeout: 2))
    replaceText(in: entry, with: "21")
    app.buttons["Set"].tap()
    assertValue("21, commander lethal", for: total)
    assertValue("19", for: app.buttons["life-total"])

    total.tap()
    XCTAssertTrue(entry.waitForExistence(timeout: 2))
    replaceText(in: entry, with: "-1")
    app.buttons["Set"].tap()
    XCTAssertTrue(app.staticTexts[
        "Enter a non-negative whole-number commander damage value."
    ].waitForExistence(timeout: 2))
    XCTAssertTrue(element("opponent-damage-exact-entry", in: app).exists)
    app.buttons["Cancel"].tap()
    assertValue("21, commander lethal", for: total)
}

@MainActor
func testCommanderDisabledFixtureHidesOpponentCardsWithoutBreakingLife() {
    let app = launchResetApp(additionalArguments: [commanderDisabledArgument])
    startDefaultGame(in: app)
    XCTAssertTrue(app.buttons["life-total"].exists)
    XCTAssertFalse(app.staticTexts["Opponents"].exists)
    XCTAssertFalse(app.buttons["add-opponent"].exists)
    XCTAssertFalse(app.buttons["Set Opponent 1's commander damage"].exists)
}
```

Add a store test if not already present: a repeat-style +1 from 20 to 21 changes life once; a repeat-style −1 at zero returns nil, persists nothing, and leaves life unchanged.

- [ ] **Step 2: Verify these tests are red**

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test \
  -project LifeGrid.xcodeproj -scheme LifeGrid \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -only-testing:LifeGridUITests/LifeGridUITests/testPrimaryDamageExactEntryLethalAndInvalidInput \
  -only-testing:LifeGridUITests/LifeGridUITests/testCommanderDisabledFixtureHidesOpponentCardsWithoutBreakingLife \
  -resultBundlePath /tmp/phase3b-task3-red.xcresult
```

Expected: failure until exact-entry and lethal details are complete.

- [ ] **Step 3: Finish exact entry and display details**

Add an exact-entry sheet in `OpponentCard.swift` with this contract:

```swift
private func openExactDamageEntry(for opponent: OpponentState) {
    exactDamageText = "\(opponent.primaryCommanderDamage)"
    exactDamageError = nil
    showsExactDamageEntry = true
}

@MainActor
private func applyExactDamage() async {
    guard let value = Int(exactDamageText), value >= 0 else {
        exactDamageError = "Enter a non-negative whole-number commander damage value."
        return
    }
    guard let currentOpponent else {
        exactDamageError = "Opponent is no longer in this game."
        return
    }
    guard currentOpponent.primaryCommanderDamage != value else {
        exactDamageError = nil
        showsExactDamageEntry = false
        return
    }
    guard await store.setPrimaryCommanderDamage(for: opponentID, to: value) != nil else {
        exactDamageError = "Opponent is no longer in this game."
        return
    }
    exactDamageError = nil
    showsExactDamageEntry = false
}
```

The sheet is `NavigationStack` + `Form`, with `TextField("Commander damage", text: $exactDamageText).keyboardType(.numberPad)`, `.accessibilityIdentifier("opponent-damage-exact-entry")`, title `Set Commander Damage`, cancellation `Cancel`, confirmation `Set`, and inline destructive error text. Keep it open for invalid/removed-opponent cases. It must not interact with `LocalLifeInteractionController`.

Ensure each RepeatActionButton’s `onRepeat` calls `store.playHaptic(.adjustment)` only after `applyDamageDelta` returns true. The initial action never haptics.

- [ ] **Step 4: Verify behavior and commit**

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test \
  -project LifeGrid.xcodeproj -scheme LifeGrid \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -only-testing:LifeGridTests/AppStateStoreTests \
  -only-testing:LifeGridUITests/LifeGridUITests/testPrimaryDamageExactEntryLethalAndInvalidInput \
  -only-testing:LifeGridUITests/LifeGridUITests/testCommanderDisabledFixtureHidesOpponentCardsWithoutBreakingLife \
  -resultBundlePath /tmp/phase3b-task3-tests.xcresult
git add LifeGrid/Features/Game/OpponentCard.swift \
  LifeGridTests/App/AppStateStoreTests.swift \
  LifeGridUITests/LifeGridUITests.swift
git commit -m "feat: complete opponent damage controls"
```

Expected: all selected tests pass. Do not weaken a value/accessibility assertion to accept an incorrect lethal or life-link state.

## Task 4: Full verification, traceability, visual review, and approval gate

**Files:**
- Modify: `protocol/requirements.json`
- Create: `reviews/visuals/game/phase3b-primary-opponents-comparison.md`
- Create: `reports/test-results/phase3b-verification.md`
- Create: final result bundles and screenshot listed in the file map

**Consumes:** Completed Task 1 through Task 3 commits.

- [ ] **Step 1: Discover the available iPhone target and run full verification**

Discover the exact simulator before testing:

```bash
xcrun simctl list devices available | rg -n 'iPhone'
```

Then substitute the discovered name/OS and run:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test \
  -project LifeGrid.xcodeproj -scheme LifeGrid \
  -destination 'platform=iOS Simulator,name=<available-iphone>,OS=<available-os>' \
  -resultBundlePath reports/test-results/phase3b-tests.xcresult

DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild build \
  -project LifeGrid.xcodeproj -scheme LifeGrid \
  -destination 'platform=iOS Simulator,name=<available-iphone>,OS=<available-os>' \
  -resultBundlePath reports/test-results/phase3b-iphone-build.xcresult
```

Expected: both exit 0. Keep external Xcode/simulator diagnostics separate from app-code warnings; never treat an incomplete result bundle as a pass.

- [ ] **Step 2: Capture and visually review the iPhone Game screen**

Start a fresh default Commander game, adjust a visible primary damage value, and save exactly `reports/test-results/phase3b-game-iphone.png`. Do not capture iPad.

Create `reviews/visuals/game/phase3b-primary-opponents-comparison.md`:

```markdown
# Phase 3B Primary Opponents — iPhone Visual Comparison

## Reference and scope

- Reference: `docs/approved/00_Approved_Designs_Overview.png`, Game iPhone panel.
- Target: <exact iPhone simulator and OS> portrait.
- Deferred: partners, rename/menu actions, statuses, Out of Game, counters, warning banners other than 21+ damage color, landscape, and iPad.

## Comparison

Describe local-card-to-Opponents hierarchy, card rhythm, dark palette, typography/contrast, 44-point controls, lethal color, and the absence of opponent life. Do not claim parity for deferred regions.

## Result

State pass/fail, actual discrepancy if one exists, and screenshot filename.
```

- [ ] **Step 3: Update requirement traceability from real evidence only**

After passing artifacts exist, update `protocol/requirements.json`:

- Mark `CMD-007`, `CMD-008`, `CMD-010`, `CMD-011`, `OPP-001`, `OPP-002`, `OPP-003`, `OPP-004`, and `OPP-005` as `verified`.
- Preserve CMD-003’s existing verified state; append Phase 3B files only if actually used.
- Add only real implementation/test/evidence paths and preserve all Phase 3A paths.
- For every Phase 3B record, state iPhone portrait verification/CR-002 iPad deferral and accurately name unimplemented adjacent scope (CMD-007 has no Settings toggle; OPP-004 has no rename UI; OPP-005 has no partner/menu/status content).
- Leave CMD-004 through CMD-006, CMD-009, and OPP-006 through OPP-013 unverified.

- [ ] **Step 4: Write verification report and self-review**

`reports/test-results/phase3b-verification.md` records Git revision, simulator, test count/failures/skips, build outcome, result-bundle integrity, focused UI flows, persistence/relaunch result, atomic/link-off/overflow checks, accessibility, screenshot hash/path, requirement mapping, visual result, and exactly:

```markdown
iPad implementation and verification are deferred under `changes/CR-002-iphone-primary-delivery.md`; `TARGETED_DEVICE_FAMILY` remains `1,2`.
```

Run:

```bash
git diff --check
rg -n "TODO|TBD|placeholder|implement later|Opponent [Ll]ife" \
  LifeGrid/Features/Game LifeGrid/App LifeGridTests LifeGridUITests \
  protocol/requirements.json reviews/visuals/game \
  reports/test-results/phase3b-verification.md
xcrun xcresulttool get test-results summary --path reports/test-results/phase3b-tests.xcresult
plutil -p reports/test-results/phase3b-tests.xcresult/Info.plist
plutil -p reports/test-results/phase3b-iphone-build.xcresult/Info.plist
git status --short
```

Expected: no whitespace errors, no unsupported product/placeholder text, passing summary, complete result bundles, and only intended Phase 3B paths.

- [ ] **Step 5: Commit evidence and stop for manual approval**

```bash
git add protocol/requirements.json \
  reviews/visuals/game/phase3b-primary-opponents-comparison.md \
  reports/test-results/phase3b-tests.xcresult \
  reports/test-results/phase3b-iphone-build.xcresult \
  reports/test-results/phase3b-game-iphone.png \
  reports/test-results/phase3b-verification.md
git commit -m "docs: verify Phase 3B primary opponents"
```

Do not push, merge, or begin a later Phase 3 subsystem. Present the screenshot, visual comparison, and evidence summary for explicit user approval.

## Coverage self-review

| Design requirement | Plan task |
| --- | --- |
| Commander-only list and Game order | Task 2 |
| Add through five, default names, stable IDs/order | Task 1 and Task 2 |
| Tap/hold/exact primary damage and floor | Task 1 through Task 3 |
| Atomic optional life link and link-off | Task 1 |
| No Phase 3A Undo interaction | Task 2 and Task 3 |
| 21+ lethal accessibility/style | Task 3 |
| Repeat haptics only on mutation | Task 2 and Task 3 |
| Disabled hiding with retained state | Task 1 and Task 3 |
| Accessibility, iPhone evidence, visual review | Task 2 through Task 4 |

No task adds partners, rename/menu actions, hide/restore, statuses, counters, opponent life, Quick Restart, Settings toggles, landscape, or iPad behavior.
