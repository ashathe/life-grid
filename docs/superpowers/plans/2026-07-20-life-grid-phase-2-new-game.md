# Life Grid Phase 2 New Game and Auto-Resume Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the approved compact New Game flow, persistent default starting life, replacement confirmation, four-tab shell, and exact active-game relaunch restoration without implementing Phase 3 gameplay.

**Architecture:** Keep `AppStateStore` as the only persisted-state owner, add a pure transient `NewGameDraft` for form behavior, and construct complete games through a pure `ActiveGameFactory`. SwiftUI feature views consume these interfaces inside a four-tab root; schema version 2 migrates version-1 snapshots without data loss.

**Tech Stack:** Swift 6, SwiftUI, Observation, Swift Testing, XCTest/XCUITest, Codable, Foundation, Xcode 26.6, iOS/iPadOS 17.0+

## Global Constraints

- Product name remains exactly `Life Grid`; bundle identifier remains `com.ashathe.lifegrid`.
- Minimum deployment target remains iOS/iPadOS 17.0.
- Use native SwiftUI with no third-party runtime or project-generation dependency.
- Storage remains local Application Support JSON only; add no network, iCloud, CloudKit, account, analytics, or related entitlement.
- The bottom shell has exactly four tabs in this order: Game, Counters, Dice, Settings.
- Opponent life totals and Initiative must not appear in state, behavior, tests, or UI.
- Phase 2 implements no Phase 3 life controls or final Game layout.
- New Game follows the approved page-2 visual reference; the Settings addition is limited to the user-approved Default Starting Life correction.
- Custom life accepts only a positive whole number representable by Swift `Int`.
- Every meaningful persisted mutation saves immediately and keeps usable in-memory state after a write failure.
- Executable behavior follows red-green-refactor; every task stops on its first failed test or build.
- Use `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` for every Xcode command.
- Manual user approval is required after Phase 2 evidence; tests and screenshots are not approval.

---

## File Map

### Existing files to modify

- `LifeGrid.xcodeproj/project.pbxproj` - register every new application and test source file in the correct target and group.
- `LifeGrid/App/LifeGridApp.swift` - install the feature root and load state once.
- `LifeGrid/App/AppStateStore.swift` - expose focused New Game and preference intents.
- `LifeGrid/Models/AppPreferences.swift` - persist default starting life and remember-last-setup.
- `LifeGrid/Models/PersistedAppState.swift` - advance the current schema to version 2.
- `LifeGrid/Persistence/StateMigration.swift` - migrate complete version-1 snapshots.
- `LifeGrid/Shared/Theme/AppearanceTokens.swift` - map semantic appearance roles to SwiftUI colors.
- `LifeGridTests/Models/PersistedAppStateTests.swift` - version-2 defaults and round trips.
- `LifeGridTests/Persistence/JSONAppStateRepositoryTests.swift` - version-1 migration and version-2 repository behavior.
- `LifeGridTests/App/AppStateStoreTests.swift` - game creation, preference precedence, save failure, and replacement behavior.
- `LifeGridUITests/LifeGridUITests.swift` - first launch, form validation, replacement, settings precedence, and relaunch restoration.
- `protocol/requirements.json` - Phase 2 traceability and verification evidence.
- `protocol/visual-references.json` - New Game comparison evidence status only; do not approve the full Settings or visual gate.

### New application files

- `LifeGrid/Features/NewGame/StartingLifeInput.swift` - preset/custom selection and positive-integer validation.
- `LifeGrid/Features/NewGame/NewGameDraft.swift` - transient player-count, name, and setup validation.
- `LifeGrid/Features/NewGame/ActiveGameFactory.swift` - pure complete-game construction.
- `LifeGrid/Features/NewGame/NewGameScreen.swift` - compact approved form and replacement confirmation.
- `LifeGrid/Features/Game/ActiveGameSummaryScreen.swift` - neutral restored-game summary and New Game access.
- `LifeGrid/Features/Settings/SettingsScreen.swift` - Default Starting Life only.
- `LifeGrid/App/LifeGridRootView.swift` - four-tab shell and active-game routing.
- `LifeGrid/Shared/Components/LifeGridCard.swift` - approved card surface treatment.
- `LifeGrid/Shared/Components/StartingLifePicker.swift` - reusable preset/custom control.

### New tests and evidence

- `LifeGridTests/Features/NewGame/StartingLifeInputTests.swift` - exact numeric validation matrix.
- `LifeGridTests/Features/NewGame/NewGameDraftTests.swift` - initialization, resizing, normalization, and setup production.
- `LifeGridTests/Features/NewGame/ActiveGameFactoryTests.swift` - complete deterministic initial game state.
- `changes/CR-001-default-starting-life.md` - immutable record of the explicitly approved Settings correction.
- `reviews/visuals/new-game/phase2-comparison.md` - implementation/reference comparison and blocking variance list.
- `reviews/visuals/settings/phase2-default-life-variance.md` - records the approved narrow addition without claiming full Settings approval.
- `reports/test-results/phase2-verification.md` - commands, destinations, result bundles, screenshots, risks, and manual-gate status.

---

### Task 1: Register the approved correction and migrate persistence to schema version 2

**Requirement IDs:** NEW-005, SET-001

**Files:**
- Create: `changes/CR-001-default-starting-life.md`
- Modify: `LifeGrid/Models/AppPreferences.swift`
- Modify: `LifeGrid/Models/PersistedAppState.swift`
- Modify: `LifeGrid/Persistence/StateMigration.swift`
- Modify: `LifeGridTests/Models/PersistedAppStateTests.swift`
- Modify: `LifeGridTests/Persistence/JSONAppStateRepositoryTests.swift`

**Interfaces:**
- Produces: `AppPreferences.defaultStartingLife: Int`, `AppPreferences.rememberLastSetup: Bool`, and `PersistedAppState.currentSchemaVersion == 2`.
- Produces: `StateMigration.migrate(_:)` support for schema 1 and 2 while rejecting every other version.

- [ ] **Step 1: Record the approved product correction**

Create `changes/CR-001-default-starting-life.md` from `changes/TEMPLATE.md` with status `approved`, requester and approver `User`, request/approval date `2026-07-20`, affected requirement `SET-001`, affected layout `Settings page 6`, and this exact decision: Settings owns Default Starting Life; it uses 20, 25, 30, 40, 60, and Custom; changing it updates only the remembered setup's life and never the active game. Leave `Implementation commit` and `Completion evidence` explicitly `Pending Phase 2 implementation` until the reviewed implementation commit exists.

- [ ] **Step 2: Write failing version-2 default and migration tests**

Add assertions to `PersistedAppStateTests.swift`:

```swift
#expect(PersistedAppState.currentSchemaVersion == 2)
#expect(state.schemaVersion == 2)
#expect(state.preferences.defaultStartingLife == 40)
#expect(state.preferences.rememberLastSetup)
```

Add a repository test that encodes a private `LegacyPersistedAppStateV1` and `LegacyAppPreferencesV1` mirroring every version-1 field, writes it as `life-grid-state.json`, loads it through `JSONAppStateRepository`, and asserts:

```swift
#expect(loaded.schemaVersion == 2)
#expect(loaded.activeGame == legacy.activeGame)
#expect(loaded.lastSetup == legacy.lastSetup)
#expect(loaded.customCounters == legacy.customCounters)
#expect(loaded.savedDice == legacy.savedDice)
#expect(loaded.diceHistory == legacy.diceHistory)
#expect(loaded.preferences.defaultStartingLife == 40)
#expect(loaded.preferences.rememberLastSetup)
```

- [ ] **Step 3: Run the focused tests and verify RED**

Run:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project LifeGrid.xcodeproj -scheme LifeGrid \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max,OS=26.5' \
  -derivedDataPath /tmp/life-grid-phase2-task1-red \
  -only-testing:LifeGridTests/PersistedAppStateTests \
  -only-testing:LifeGridTests/JSONAppStateRepositoryTests test
```

Expected: FAIL because schema version is 1 and the new preference properties do not exist.

- [ ] **Step 4: Add preference defaults and the ordered migration**

Add to `AppPreferences` and `.default`:

```swift
var defaultStartingLife: Int
var rememberLastSetup: Bool

defaultStartingLife: 40,
rememberLastSetup: true,
```

Set `PersistedAppState.currentSchemaVersion = 2`. In `StateMigration.migrate`, switch on the envelope version:

```swift
switch schemaVersion {
case 1:
    let legacy = try decoder.decode(PersistedAppStateV1.self, from: data)
    return PersistedAppState(
        schemaVersion: 2,
        preferences: AppPreferences(
            playerName: legacy.preferences.playerName,
            commanderEnabled: legacy.preferences.commanderEnabled,
            ownPartnerCommanderEnabled: legacy.preferences.ownPartnerCommanderEnabled,
            commanderDamageChangesLife: legacy.preferences.commanderDamageChangesLife,
            keepScreenAwakeDuringGames: legacy.preferences.keepScreenAwakeDuringGames,
            hapticsEnabled: legacy.preferences.hapticsEnabled,
            soundEffectsEnabled: legacy.preferences.soundEffectsEnabled,
            appearance: legacy.preferences.appearance,
            appScale: legacy.preferences.appScale,
            defaultStartingLife: 40,
            rememberLastSetup: true
        ),
        lastSetup: legacy.lastSetup,
        activeGame: legacy.activeGame,
        customCounters: legacy.customCounters,
        savedDice: legacy.savedDice,
        diceHistory: legacy.diceHistory
    )
case 2:
    return try decoder.decode(PersistedAppState.self, from: data)
default:
    throw StateMigrationError.unsupportedSchema(schemaVersion)
}
```

Define private Codable `PersistedAppStateV1` and `AppPreferencesV1` structures in `StateMigration.swift` with every version-1 property and no new fields.

- [ ] **Step 5: Run focused and regression tests**

Repeat the Task 1 command. Expected: PASS for both selected suites. Then run `-only-testing:LifeGridTests`; expected: all unit tests PASS after updating existing version assertions to 2.

- [ ] **Step 6: Commit the migration slice**

```bash
git add changes/CR-001-default-starting-life.md LifeGrid/Models/AppPreferences.swift LifeGrid/Models/PersistedAppState.swift LifeGrid/Persistence/StateMigration.swift LifeGridTests/Models/PersistedAppStateTests.swift LifeGridTests/Persistence/JSONAppStateRepositoryTests.swift
git commit -m "feat: migrate Life Grid setup preferences"
```

---

### Task 2: Implement starting-life input and the transient New Game draft

**Requirement IDs:** NEW-001, NEW-002, NEW-003, NEW-005, NEW-006

**Files:**
- Create: `LifeGrid/Features/NewGame/StartingLifeInput.swift`
- Create: `LifeGrid/Features/NewGame/NewGameDraft.swift`
- Create: `LifeGridTests/Features/NewGame/StartingLifeInputTests.swift`
- Create: `LifeGridTests/Features/NewGame/NewGameDraftTests.swift`
- Modify: `LifeGrid.xcodeproj/project.pbxproj`

**Interfaces:**
- Produces: `StartingLifeChoice`, `StartingLifeInput.value`, `StartingLifeInput.validationMessage`.
- Produces: `NewGameDraft.init(state:)`, `setTotalPlayers(_:)`, and `validatedSetup: GameSetup?`.

- [ ] **Step 1: Write failing starting-life tests**

Create table-driven Swift Testing cases for presets 20/25/30/40/60 and custom values `"1"`, `"40"`, and `String(Int.max)` as valid. Assert `""`, `"abc"`, `"0"`, `"-1"`, `"1.5"`, whitespace-only, and a decimal string larger than `Int.max` are invalid. Also assert a typed custom value survives selecting a preset and then selecting Custom again.

- [ ] **Step 2: Write failing draft tests**

Cover these exact cases:

```swift
@Test func rememberedSetupSeedsEveryField()
@Test func disabledRememberingUsesFourPlayersBlankNamesAndSettingsLife()
@Test func reducingPlayersDiscardsNamesAndReaddingCreatesBlanks()
@Test func validatedSetupTrimsNamesAndSuppliesStableFallbacks()
@Test func duplicateNamesRemainAllowed()
@Test func invalidCustomLifePreventsSetup()
```

- [ ] **Step 3: Register the four files and verify RED**

Add explicit PBX file references, app/test source build entries, and `Features/NewGame` plus matching test groups to `project.pbxproj`. Run the two selected test suites. Expected: compile FAIL because the production types do not exist.

- [ ] **Step 4: Implement the pure input model**

Create `StartingLifeInput.swift`:

```swift
enum StartingLifeChoice: Equatable, Sendable {
    case preset(Int)
    case custom
}

struct StartingLifeInput: Equatable, Sendable {
    static let presets = [20, 25, 30, 40, 60]

    var choice: StartingLifeChoice
    var customText: String

    init(value: Int) {
        if Self.presets.contains(value) {
            choice = .preset(value)
            customText = ""
        } else {
            choice = .custom
            customText = String(value)
        }
    }

    var value: Int? {
        switch choice {
        case .preset(let value): return value
        case .custom:
            guard !customText.isEmpty,
                  customText.allSatisfy(\.isNumber),
                  let value = Int(customText), value > 0 else { return nil }
            return value
        }
    }

    var validationMessage: String? {
        choice == .custom && value == nil ? "Enter a positive whole number." : nil
    }
}
```

- [ ] **Step 5: Implement the transient draft**

Create `NewGameDraft.swift` with stored `totalPlayers`, `startingLife`, `opponentNames`, and `rememberLastSetup`. Initialize from `state.lastSetup` only when remembering is enabled; otherwise initialize four players, blank names, and `state.preferences.defaultStartingLife`. `setTotalPlayers(_:)` clamps to 2...6, truncates excess names, and appends empty strings. `validatedSetup` returns nil unless life is valid, then trims names with `trimmingCharacters(in: .whitespacesAndNewlines)` and substitutes `Opponent N`.

```swift
import Foundation

struct NewGameDraft: Equatable, Sendable {
    var totalPlayers: Int
    var startingLife: StartingLifeInput
    var opponentNames: [String]
    var rememberLastSetup: Bool

    init(state: PersistedAppState) {
        rememberLastSetup = state.preferences.rememberLastSetup
        let setup = rememberLastSetup
            ? state.lastSetup
            : GameSetup(
                totalPlayers: 4,
                startingLife: state.preferences.defaultStartingLife,
                opponentNames: []
            )
        totalPlayers = min(max(setup.totalPlayers, 2), 6)
        startingLife = StartingLifeInput(value: setup.startingLife)
        opponentNames = Array(setup.opponentNames.prefix(totalPlayers - 1))
        while opponentNames.count < totalPlayers - 1 { opponentNames.append("") }
    }

    mutating func setTotalPlayers(_ value: Int) {
        totalPlayers = min(max(value, 2), 6)
        opponentNames = Array(opponentNames.prefix(totalPlayers - 1))
        while opponentNames.count < totalPlayers - 1 { opponentNames.append("") }
    }

    var validatedSetup: GameSetup? {
        guard let life = startingLife.value else { return nil }
        let normalized = opponentNames.enumerated().map { index, name in
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? "Opponent \(index + 1)" : trimmed
        }
        return GameSetup(
            totalPlayers: totalPlayers,
            startingLife: life,
            opponentNames: normalized
        )
    }
}
```

- [ ] **Step 6: Run tests and commit**

Run both focused suites and then all `LifeGridTests`; expected PASS. Verify `xcodebuild -project LifeGrid.xcodeproj -list` succeeds. Commit:

```bash
git add LifeGrid.xcodeproj/project.pbxproj LifeGrid/Features/NewGame LifeGridTests/Features/NewGame
git commit -m "feat: add validated New Game draft"
```

---

### Task 3: Construct complete games and add atomic store intents

**Requirement IDs:** NAV-002, NEW-004, NEW-005, NEW-007, NEW-008

**Files:**
- Create: `LifeGrid/Features/NewGame/ActiveGameFactory.swift`
- Create: `LifeGridTests/Features/NewGame/ActiveGameFactoryTests.swift`
- Modify: `LifeGrid/App/AppStateStore.swift`
- Modify: `LifeGridTests/App/AppStateStoreTests.swift`
- Modify: `LifeGrid.xcodeproj/project.pbxproj`

**Interfaces:**
- Produces: `ActiveGameFactory.make(setup:id:opponentIDs:startedAt:) -> ActiveGame`, with generated UUID defaults for production and injectable UUIDs for tests.
- Produces: `AppStateStore.startGame(using:rememberLastSetup:)`, `setRememberLastSetup(_:)`, `setDefaultStartingLife(_:)`, and `saveForLifecycle()` async intents.

- [ ] **Step 1: Write the failing factory test**

Pass fixed game/opponent UUIDs and a fixed date. Assert starting/current life match the setup; opponents have stable IDs, trimmed/fallback names, are visible, have zero commander damage and no status; tax/counters are zero; Day/Night is Not Set; monarch and City's Blessing are absent; pins are empty; keep-awake override is nil.

- [ ] **Step 2: Write failing store-intent tests**

Add tests proving:

- `startGame` creates and immediately saves a complete active game.
- Remembering on replaces `lastSetup`; remembering off preserves it.
- `setDefaultStartingLife(25)` updates preferences and `lastSetup.startingLife` but leaves an existing `activeGame` byte-for-byte equal.
- `setRememberLastSetup(false)` saves immediately without clearing `lastSetup`.
- `saveForLifecycle()` retries the current state after an earlier failed write.
- A replacement is one saved snapshot containing the complete new game.
- A failing save retains the new in-memory game and exposes `persistenceErrorDescription`.

- [ ] **Step 3: Register files and verify RED**

Add the application/test file references and source build entries. Run `ActiveGameFactoryTests` and `AppStateStoreTests`; expected compile FAIL for missing interfaces.

- [ ] **Step 4: Implement deterministic game construction**

Build all numeric built-in counters at zero with:

```swift
let counters = Dictionary(uniqueKeysWithValues:
    BuiltInCounterID.allCases
        .filter { $0 != .dayNight }
        .map { (CounterID.builtIn($0), 0) }
)
```

Create opponents from the validated setup and supplied IDs. Precondition that player count is 2...6, life is positive, and opponent ID count matches opponent-name count. Return every `ActiveGame` field explicitly; use no hidden defaults.

```swift
import Foundation

enum ActiveGameFactory {
    static func make(
        setup: GameSetup,
        id: UUID = UUID(),
        opponentIDs: [UUID]? = nil,
        startedAt: Date
    ) -> ActiveGame {
        precondition((2...6).contains(setup.totalPlayers))
        precondition(setup.startingLife > 0)
        precondition(setup.opponentNames.count == setup.totalPlayers - 1)
        let ids = opponentIDs ?? setup.opponentNames.map { _ in UUID() }
        precondition(ids.count == setup.opponentNames.count)

        let opponents = zip(ids, setup.opponentNames).map { id, name in
            OpponentState(
                id: id,
                displayName: name,
                isVisible: true,
                primaryCommanderName: nil,
                primaryCommanderDamage: 0,
                partner: nil,
                hasCitysBlessing: false
            )
        }
        let counters = Dictionary(uniqueKeysWithValues:
            BuiltInCounterID.allCases
                .filter { $0 != .dayNight }
                .map { (CounterID.builtIn($0), 0) }
        )
        return ActiveGame(
            id: id,
            startedAt: startedAt,
            startingLife: setup.startingLife,
            currentLife: setup.startingLife,
            opponents: opponents,
            ownCommanderAName: nil,
            ownCommanderBName: nil,
            ownCommanderTaxA: 0,
            ownCommanderTaxB: 0,
            currentMonarchPlayerID: nil,
            playerHasCitysBlessing: false,
            counterValues: counters,
            dayNightState: .notSet,
            pinnedCounterIDs: [],
            keepAwakeOverride: nil
        )
    }
}
```

- [ ] **Step 5: Implement focused store intents**

Add:

```swift
func startGame(using setup: GameSetup, rememberLastSetup: Bool) async {
    let startedAt = await environment.clock.now()
    let game = ActiveGameFactory.make(
        setup: setup,
        startedAt: startedAt
    )
    await mutateAndPersist { state in
        state.preferences.rememberLastSetup = rememberLastSetup
        state.activeGame = game
        if rememberLastSetup { state.lastSetup = setup }
    }
}

func setRememberLastSetup(_ enabled: Bool) async {
    await mutateAndPersist { $0.preferences.rememberLastSetup = enabled }
}

func setDefaultStartingLife(_ value: Int) async {
    guard value > 0 else { return }
    await mutateAndPersist { state in
        state.preferences.defaultStartingLife = value
        state.lastSetup.startingLife = value
    }
}

func saveForLifecycle() async {
    await persistCurrentState()
}
```

Rename the private foundation mutation path to `mutateAndPersist`, retain `applyFoundationMutation` as a thin test-compatible wrapper if existing Phase 1 tests still use it, and keep save-error behavior unchanged.

- [ ] **Step 6: Run tests and commit**

Run the two focused suites, all unit tests, and an iPhone simulator build. Expected PASS. Commit the exact slice:

```bash
git add LifeGrid.xcodeproj/project.pbxproj LifeGrid/Features/NewGame/ActiveGameFactory.swift LifeGrid/App/AppStateStore.swift LifeGridTests/Features/NewGame/ActiveGameFactoryTests.swift LifeGridTests/App/AppStateStoreTests.swift
git commit -m "feat: create and persist active games"
```

---

### Task 4: Build reusable approved surfaces and starting-life control

**Requirement IDs:** NEW-002, NEW-006

**Files:**
- Create: `LifeGrid/Shared/Components/LifeGridCard.swift`
- Create: `LifeGrid/Shared/Components/StartingLifePicker.swift`
- Modify: `LifeGrid/Shared/Theme/AppearanceTokens.swift`
- Modify: `LifeGrid.xcodeproj/project.pbxproj`

**Interfaces:**
- Produces: `LifeGridPalette`, `LifeGridCard`, and `StartingLifePicker(input:)`.

- [ ] **Step 1: Add a compile-level test expectation**

Extend `FoundationSmokeTests` to instantiate `StartingLifePicker(input: .constant(StartingLifeInput(value: 40)))` and apply `LifeGridCard()` to a `Text`. Register the two application files in the project. Run `FoundationSmokeTests`; expected compile FAIL.

- [ ] **Step 2: Implement semantic visual primitives**

Map approved dark-first roles to adaptive SwiftUI `Color` values: near-black background, elevated dark-purple surface, purple accent, red destructive/lethal, primary near-white text, and muted lavender-gray secondary text. Do not hard-code product meaning in feature views.

Implement `LifeGridCard` as a `ViewModifier` with approved padding, rounded rectangle fill, and subtle border. Implement `StartingLifePicker` as a two-row adaptive grid of the six choices. It binds `StartingLifeInput`, gives each button a 44-point minimum target, exposes selected state to VoiceOver, and shows a numeric text field plus `validationMessage` only when Custom is selected.

```swift
import SwiftUI

enum LifeGridPalette {
    static let background = Color(red: 0.045, green: 0.04, blue: 0.065)
    static let surface = Color(red: 0.105, green: 0.09, blue: 0.135)
    static let border = Color(red: 0.19, green: 0.16, blue: 0.24)
    static let accent = Color(red: 0.53, green: 0.29, blue: 0.95)
    static let destructive = Color(red: 0.76, green: 0.12, blue: 0.18)
    static let primaryText = Color(red: 0.96, green: 0.95, blue: 0.98)
    static let secondaryText = Color(red: 0.62, green: 0.59, blue: 0.68)
}

struct LifeGridCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(LifeGridPalette.surface, in: RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(LifeGridPalette.border, lineWidth: 1)
            }
    }
}

extension View {
    func lifeGridCard() -> some View { modifier(LifeGridCard()) }
}

struct StartingLifePicker: View {
    @Binding var input: StartingLifeInput
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(StartingLifeInput.presets, id: \.self) { value in
                    choiceButton(String(value), choice: .preset(value))
                }
                choiceButton("Custom", choice: .custom)
            }
            if input.choice == .custom {
                TextField("Starting life", text: $input.customText)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier("custom-starting-life")
                if let message = input.validationMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(LifeGridPalette.destructive)
                        .accessibilityIdentifier("custom-starting-life-error")
                }
            }
        }
    }

    private func choiceButton(_ title: String, choice: StartingLifeChoice) -> some View {
        let selected = input.choice == choice
        return Button(title) { input.choice = choice }
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(selected ? LifeGridPalette.accent : LifeGridPalette.border)
            .foregroundStyle(LifeGridPalette.primaryText)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .accessibilityAddTraits(selected ? .isSelected : [])
            .accessibilityIdentifier("starting-life-\(title.lowercased())")
    }
}
```

- [ ] **Step 3: Build and commit**

Run `FoundationSmokeTests`, all unit tests, and iPhone/iPad builds. Expected PASS. Commit:

```bash
git add LifeGrid.xcodeproj/project.pbxproj LifeGrid/Shared/Components LifeGrid/Shared/Theme/AppearanceTokens.swift LifeGridTests/FoundationSmokeTests.swift
git commit -m "feat: add Life Grid setup controls"
```

---

### Task 5: Implement the compact New Game screen and replacement confirmation

**Requirement IDs:** NEW-001 through NEW-008

**Files:**
- Create: `LifeGrid/Features/NewGame/NewGameScreen.swift`
- Modify: `LifeGrid.xcodeproj/project.pbxproj`
- Modify: `LifeGridTests/FoundationSmokeTests.swift`

**Interfaces:**
- Consumes: `NewGameDraft`, `StartingLifePicker`, and `AppStateStore` intents.
- Produces: `NewGameScreen(store:onGameStarted:)`.

- [ ] **Step 1: Add the failing compile test**

Instantiate `NewGameScreen(store:onGameStarted:)` with a test store and an empty closure. Run `FoundationSmokeTests`; expected compile FAIL because the screen does not exist.

- [ ] **Step 2: Implement the approved compact hierarchy**

Create a `NavigationStack` containing, in order: title/subtitle, Total Players card with decrement/value/increment controls, Starting Life card using `StartingLifePicker`, Opponent Names card with exactly `totalPlayers - 1` text fields, Remember last setup card, and a full-width purple Start Game button. Give stable accessibility identifiers:

```text
new-game-screen
player-count
player-count-decrement
player-count-increment
starting-life-20 / 25 / 30 / 40 / 60 / custom
custom-starting-life
custom-starting-life-error
opponent-name-1 ... opponent-name-5
remember-last-setup
start-game
```

Disable Start Game when `draft.validatedSetup` is nil. Persist Remember toggle changes through `store.setRememberLastSetup` without altering the active game.

Use this state and submission structure; extract the repeated card rows into private computed views in the same file without changing their order or identifiers:

```swift
import SwiftUI

struct NewGameScreen: View {
    @Bindable var store: AppStateStore
    let onGameStarted: () -> Void
    @State private var draft: NewGameDraft
    @State private var showsReplacement = false

    init(store: AppStateStore, onGameStarted: @escaping () -> Void = {}) {
        self.store = store
        self.onGameStarted = onGameStarted
        _draft = State(initialValue: NewGameDraft(state: store.state))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("New Game").font(.title2.bold())
                    Text("Start with your preferred table setup")
                        .font(.caption).foregroundStyle(LifeGridPalette.secondaryText)
                    playerCountCard
                    VStack(alignment: .leading) {
                        Text("Starting Life").font(.headline)
                        StartingLifePicker(input: $draft.startingLife)
                    }.lifeGridCard()
                    opponentNamesCard
                    Toggle("Remember last setup", isOn: $draft.rememberLastSetup)
                        .onChange(of: draft.rememberLastSetup) { _, value in
                            Task { await store.setRememberLastSetup(value) }
                        }
                        .accessibilityIdentifier("remember-last-setup")
                        .lifeGridCard()
                    Button("Start Game", action: submit)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .buttonStyle(.borderedProminent)
                        .tint(LifeGridPalette.accent)
                        .disabled(draft.validatedSetup == nil)
                        .accessibilityIdentifier("start-game")
                }.padding()
            }
            .background(LifeGridPalette.background.ignoresSafeArea())
            .foregroundStyle(LifeGridPalette.primaryText)
            .accessibilityIdentifier("new-game-screen")
            .confirmationDialog(
                "Replace current game?",
                isPresented: $showsReplacement,
                titleVisibility: .visible
            ) {
                Button("Start New Game", role: .destructive) { startValidatedGame() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This creates a new game and replaces the autosaved active game.")
            }
        }
    }

    private var playerCountCard: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Total Players").font(.headline)
                Text("Includes you").font(.caption).foregroundStyle(LifeGridPalette.secondaryText)
            }
            Spacer()
            Button("−") { draft.setTotalPlayers(draft.totalPlayers - 1) }
                .disabled(draft.totalPlayers == 2)
                .accessibilityIdentifier("player-count-decrement")
            Text("\(draft.totalPlayers)")
                .frame(minWidth: 32)
                .accessibilityIdentifier("player-count")
            Button("+") { draft.setTotalPlayers(draft.totalPlayers + 1) }
                .disabled(draft.totalPlayers == 6)
                .accessibilityIdentifier("player-count-increment")
        }.lifeGridCard()
    }

    private var opponentNamesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Opponent Names").font(.headline)
            Text("Optional · Blank names use Opponent 1, 2, 3…")
                .font(.caption).foregroundStyle(LifeGridPalette.secondaryText)
            ForEach(draft.opponentNames.indices, id: \.self) { index in
                TextField("Opponent \(index + 1)", text: $draft.opponentNames[index])
                    .textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier("opponent-name-\(index + 1)")
            }
        }.lifeGridCard()
    }

    private func submit() {
        guard draft.validatedSetup != nil else { return }
        if store.state.activeGame == nil { startValidatedGame() }
        else { showsReplacement = true }
    }

    private func startValidatedGame() {
        guard let setup = draft.validatedSetup else { return }
        Task {
            await store.startGame(
                using: setup,
                rememberLastSetup: draft.rememberLastSetup
            )
            onGameStarted()
        }
    }
}
```

- [ ] **Step 3: Implement replacement confirmation**

If `store.state.activeGame != nil`, Start Game presents a destructive confirmation titled `Replace current game?`, message `This creates a new game and replaces the autosaved active game.`, destructive button `Start New Game`, and cancel button `Cancel`. Cancel preserves the edited draft. Confirm calls `store.startGame(using:rememberLastSetup:)` once and invokes `onGameStarted` only after the in-memory mutation completes. With no active game, start immediately without confirmation.

- [ ] **Step 4: Build, inspect, and commit**

Run all unit tests and iPhone/iPad builds. Launch on iPhone and use Accessibility Inspector or XCUITest debug output to confirm identifiers and 44-point controls. Commit:

```bash
git add LifeGrid.xcodeproj/project.pbxproj LifeGrid/Features/NewGame/NewGameScreen.swift LifeGridTests/FoundationSmokeTests.swift
git commit -m "feat: build compact New Game screen"
```

---

### Task 6: Install the four-tab shell, neutral restoration screen, and default-life Settings slice

**Requirement IDs:** NAV-001, NAV-002, SET-001

**Files:**
- Create: `LifeGrid/App/LifeGridRootView.swift`
- Create: `LifeGrid/Features/Game/ActiveGameSummaryScreen.swift`
- Create: `LifeGrid/Features/Settings/SettingsScreen.swift`
- Modify: `LifeGrid/App/LifeGridApp.swift`
- Delete: `LifeGrid/App/FoundationRootView.swift`
- Modify: `LifeGrid.xcodeproj/project.pbxproj`
- Modify: `LifeGridTests/FoundationSmokeTests.swift`

**Interfaces:**
- Produces: the production root and stable identifiers `tab-game`, `tab-counters`, `tab-dice`, `tab-settings`, `active-game-summary`, and `settings-default-life`.

- [ ] **Step 1: Update the smoke test and verify RED**

Replace `FoundationRootView()` with `LifeGridRootView(store:)` and add compile instances of `ActiveGameSummaryScreen` and `SettingsScreen`. Run `FoundationSmokeTests`; expected compile FAIL.

- [ ] **Step 2: Implement Settings Default Starting Life**

Render the approved Settings title/subtitle and one `LifeGridCard` labeled Default Starting Life. Reuse `StartingLifePicker`. Selecting a valid preset persists immediately. Custom text remains local and displays inline validation; a `Set Default` button is enabled only for valid Custom input and calls `store.setDefaultStartingLife`. After persistence, the selected value remains visible. Do not render any Phase 6 setting.

```swift
import SwiftUI

struct SettingsScreen: View {
    @Bindable var store: AppStateStore
    @State private var input: StartingLifeInput

    init(store: AppStateStore) {
        self.store = store
        _input = State(initialValue: StartingLifeInput(
            value: store.state.preferences.defaultStartingLife
        ))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Settings").font(.title2.bold())
                    Text("Saved locally on this device")
                        .font(.caption).foregroundStyle(LifeGridPalette.secondaryText)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Default Starting Life").font(.headline)
                        StartingLifePicker(input: $input)
                        if input.choice == .custom {
                            Button("Set Default") { persistCurrentValue() }
                                .buttonStyle(.borderedProminent)
                                .disabled(input.value == nil)
                        }
                    }
                    .lifeGridCard()
                    .accessibilityIdentifier("settings-default-life")
                }.padding()
            }
            .background(LifeGridPalette.background.ignoresSafeArea())
            .foregroundStyle(LifeGridPalette.primaryText)
            .onChange(of: input.choice) { _, choice in
                if case .preset = choice { persistCurrentValue() }
            }
        }
    }

    private func persistCurrentValue() {
        guard let value = input.value else { return }
        Task { await store.setDefaultStartingLife(value) }
    }
}
```

- [ ] **Step 3: Implement the neutral active-game summary**

Show only `Game Active`, starting life, total players, local display name (`You` when blank), and opponent names. Add toolbar action `New Game` that presents `NewGameScreen` as a sheet. Dismiss the sheet after confirmed replacement. Do not show current-life controls, commander controls, counters, statuses, or the approved Phase 3 card layout.

```swift
import SwiftUI

struct ActiveGameSummaryScreen: View {
    @Bindable var store: AppStateStore
    @State private var showsNewGame = false

    var body: some View {
        NavigationStack {
            List {
                Section("Game Active") {
                    LabeledContent("Starting Life", value: "\(game.startingLife)")
                    LabeledContent("Total Players", value: "\(game.opponents.count + 1)")
                }
                Section("Players") {
                    Text(store.state.preferences.playerName.isEmpty
                         ? "You" : store.state.preferences.playerName)
                    ForEach(game.opponents) { Text($0.displayName) }
                }
            }
            .navigationTitle("Game")
            .toolbar { Button("New Game") { showsNewGame = true } }
            .accessibilityIdentifier("active-game-summary")
            .sheet(isPresented: $showsNewGame) {
                NewGameScreen(store: store) { showsNewGame = false }
            }
        }
    }

    private var game: ActiveGame {
        precondition(store.state.activeGame != nil)
        return store.state.activeGame!
    }
}
```

- [ ] **Step 4: Implement and install the tab root**

Create a `TabView` in the exact approved order. Game switches reactively between `NewGameScreen` and `ActiveGameSummaryScreen` based on `store.state.activeGame`. Counters and Dice use neutral labeled views with no controls. Settings uses `SettingsScreen`.

When `store.persistenceErrorDescription != nil`, `LifeGridRootView` displays an accessible, non-destructive banner reading `Couldn’t access saved data. Life Grid will retry.` with identifier `persistence-error`. It disappears after a successful save. Replace `FoundationRootView` in `LifeGridApp` with `LifeGridRootView(store: store)`, keep the one startup `.task { await store.load() }`, observe `scenePhase`, and call `store.saveForLifecycle()` when the app becomes inactive or enters the background.

```swift
import SwiftUI

struct LifeGridRootView: View {
    @Bindable var store: AppStateStore

    var body: some View {
        TabView {
            Group {
                if store.state.activeGame == nil { NewGameScreen(store: store) }
                else { ActiveGameSummaryScreen(store: store) }
            }
            .tabItem { Label("Game", systemImage: "heart.fill") }
            .accessibilityIdentifier("tab-game")

            neutral("Counters", symbol: "number")
                .tabItem { Label("Counters", systemImage: "number") }
                .accessibilityIdentifier("tab-counters")
            neutral("Dice", symbol: "die.face.6.fill")
                .tabItem { Label("Dice", systemImage: "die.face.6.fill") }
                .accessibilityIdentifier("tab-dice")
            SettingsScreen(store: store)
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .accessibilityIdentifier("tab-settings")
        }
        .tint(LifeGridPalette.accent)
        .safeAreaInset(edge: .top) {
            if store.persistenceErrorDescription != nil {
                Text("Couldn’t access saved data. Life Grid will retry.")
                    .frame(maxWidth: .infinity).padding(8)
                    .background(LifeGridPalette.destructive)
                    .foregroundStyle(.white)
                    .accessibilityIdentifier("persistence-error")
            }
        }
    }

    private func neutral(_ title: String, symbol: String) -> some View {
        ContentUnavailableView(title, systemImage: symbol, description: Text("Coming in an approved phase."))
    }
}

@main
struct LifeGridApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var store = AppStateStore(environment: .live())

    var body: some Scene {
        WindowGroup {
            LifeGridRootView(store: store)
                .task { await store.load() }
                .onChange(of: scenePhase) { _, phase in
                    guard phase != .active else { return }
                    Task { await store.saveForLifecycle() }
                }
        }
    }
}
```

- [ ] **Step 5: Build, run unit tests, and commit**

Run all unit tests plus iPhone and iPad builds. Expected PASS. Commit:

```bash
git add -A LifeGrid.xcodeproj/project.pbxproj LifeGrid/App LifeGrid/Features/Game LifeGrid/Features/Settings LifeGridTests/FoundationSmokeTests.swift
git commit -m "feat: add Life Grid Phase 2 shell"
```

---

### Task 7: Add end-to-end UI behavior and relaunch restoration tests

**Requirement IDs:** NAV-001, NAV-002, NEW-001 through NEW-008, SET-001

**Files:**
- Modify: `LifeGrid/App/AppEnvironment.swift`
- Modify: `LifeGridUITests/LifeGridUITests.swift`

**Interfaces:**
- Produces: test-only launch argument `--ui-testing-reset-state`, which removes only the app's own `life-grid-state.json` before store construction.

- [ ] **Step 1: Write failing UI tests**

Add helpers `launchResetApp()` and `launchPreservingApp()`. Implement tests with explicit waits:

```swift
func testFirstLaunchCreatesAndRestoresGame()
func testInvalidCustomLifeKeepsDraftAndDisablesStart()
func testReplacementCancelPreservesGameAndDraft()
func testReplacementConfirmCreatesNewGame()
func testSettingsDefaultUpdatesNextNewGameWithoutChangingActiveGame()
func testFourTabsRemainAvailable()
```

The relaunch test starts a 3-player, 25-life game named Amanda and Chris, terminates the app, launches without reset, and asserts the active summary shows 25, 3, Amanda, and Chris.

- [ ] **Step 2: Run UI tests and verify RED**

Run:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project LifeGrid.xcodeproj -scheme LifeGrid \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max,OS=26.5' \
  -derivedDataPath /tmp/life-grid-phase2-task7-red \
  -only-testing:LifeGridUITests test
```

Expected: FAIL because reset isolation is not implemented or one of the end-to-end behaviors is incorrect.

- [ ] **Step 3: Add narrowly scoped UI-test reset support**

In production composition only when `ProcessInfo.processInfo.arguments.contains("--ui-testing-reset-state")`, delete the explicit snapshot URL under `Application Support/Life Grid/life-grid-state.json` before constructing the repository. Never delete the directory recursively, never activate this path without the exact argument, and keep the second relaunch argument-free so restoration is real.

- [ ] **Step 4: Run UI, unit, and build verification**

Run the complete UI suite, complete unit suite, iPhone build, and iPad build. Expected: all PASS. Commit:

```bash
git add LifeGrid/App/AppEnvironment.swift LifeGridUITests/LifeGridUITests.swift
git commit -m "test: verify New Game relaunch flows"
```

---

### Task 8: Capture visual, traceability, and Phase 2 verification evidence

**Requirement IDs:** NAV-001, NAV-002, NEW-001 through NEW-008, SET-001, TEST-001 through TEST-004

**Files:**
- Create: `reviews/visuals/new-game/phase2-comparison.md`
- Create: `reviews/visuals/settings/phase2-default-life-variance.md`
- Create: `reports/test-results/phase2-verification.md`
- Create: `reports/test-results/phase2-*.xcresult`
- Create: `reports/test-results/phase2-*.png`
- Modify: `protocol/requirements.json`
- Modify: `protocol/visual-references.json`
- Modify: `changes/CR-001-default-starting-life.md`

**Interfaces:**
- Produces: reviewed Phase 2 evidence without marking Visual Gate 2 or Build Gate 3 approved.

- [ ] **Step 1: Run fresh final verification into named result bundles**

Use new `/tmp/life-grid-phase2-final-*` Derived Data paths and repository result-bundle paths for: full unit/UI tests on iPhone, iPhone build, and iPad build. Also run:

```bash
python3 -m unittest discover -s protocol/tests -v
python3 protocol/validate.py gate architecture
python3 -m json.tool protocol/requirements.json >/dev/null
python3 -m json.tool protocol/visual-references.json >/dev/null
git diff --check
```

Expected: every command PASS. Stop at the first failure and do not write a success report.

- [ ] **Step 2: Capture representative implementation screenshots**

Capture New Game on iPhone portrait, the Default Starting Life Settings slice, the replacement confirmation, the neutral restored-game screen, and the iPad tab shell. Store PNGs under `reports/test-results/` with `phase2-` prefixes. Do not fabricate missing appearance/app-scale variants or call them approved.

- [ ] **Step 3: Write visual comparisons and variance evidence**

In the New Game report, compare hierarchy, spacing, typography, cards, selected states, controls, and tab shell against PDF page 2; list every measurable mismatch and classify blockers. In the Settings variance report, cite CR-001 and state that the added Default Starting Life control is user-approved but the complete page-6 Settings screen remains unimplemented and unapproved.

- [ ] **Step 4: Update traceability truthfully**

For NAV-001, NAV-002, and NEW-001 through NEW-008, populate exact implementation, test, and evidence paths and set `verified` only after their checks pass. For SET-001, add the Phase 2 files/evidence but leave the status `in_progress` because the other approved default Settings controls are deferred to Phase 6. Keep the full `settings` visual reference `not_started`; set `new-game` to the existing schema value `in_review` after comparison evidence exists. Neither value claims Visual Gate 2 approval.

- [ ] **Step 5: Write the verification report and close the change record**

Record exact commands, Xcode/Swift versions, simulator destinations, test counts, result-bundle paths, screenshot paths, migration result, restoration result, risks, and `Phase 2 manual approval: Pending`. Update CR-001 with the reviewed implementation commit only after that commit exists; completion evidence cites Settings tests and the variance report.

- [ ] **Step 6: Commit the evidence and stop at the manual gate**

```bash
git add changes/CR-001-default-starting-life.md protocol/requirements.json protocol/visual-references.json reviews/visuals reports/test-results
git commit -m "test: record Life Grid Phase 2 verification"
```

Present the reviewed commit, test/build evidence, screenshots, visual variances, and remaining limitations. Do not start Phase 3 and do not create a Phase 2 approval record unless the user explicitly approves the reviewed implementation.

---

## Final Execution Rules

- Execute tasks in order; later interfaces depend on earlier tasks.
- Each RED run must fail for the expected missing behavior, not for an unrelated project or simulator error.
- Each GREEN run must include the focused test first, then the stated regression scope.
- Never weaken or delete a test merely to obtain green.
- Keep unrelated user changes untouched.
- A test/build/privacy/protocol failure is a hard stop with exact evidence.
- Phase 2 ends with a manual user approval request; it does not authorize Phase 3.
