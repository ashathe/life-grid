# Life Grid Phase 1 Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build and verify the protocol-controlled, test-first SwiftUI foundation for Life Grid through the pre-approval side of Architecture Gate 1.

**Architecture:** A native universal Xcode project contains a thin SwiftUI app target, unit and UI-test targets, value-type versioned domain state, an atomic JSON repository, and a main-actor observable store. A Python validator enforces repository structure and Gate 1 evidence; approved product artifacts and requirement traceability are checked into the repository without altering their content.

**Tech Stack:** Swift 6, SwiftUI, Observation, Swift Testing, XCTest, Codable, Foundation, Python 3 standard library, JSON Schema documents, Xcode 26.6, iOS/iPadOS 17.0+

## Global Constraints

- Product name is exactly `Life Grid`; provisional bundle identifier is `com.ashathe.lifegrid`.
- Minimum deployment target is iOS/iPadOS 17.0.
- The app is universal for iPhone and iPad and uses SwiftUI.
- Storage is local Application Support JSON only; no network, iCloud, CloudKit, account, analytics, or related entitlement.
- Opponent life totals and Initiative must not appear in code, state, tests, or UI.
- The app has exactly four approved feature boundaries: Game, Counters, Dice, Settings.
- Approved icon artwork must be copied without redesign; production icon generation is outside Phase 1.
- No product screen may be claimed implemented or visually approved in Phase 1.
- Executable Swift and Python behavior follows red-green-refactor; static project configuration, copied artifacts, schemas, and documentation are structurally verified.
- Use `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` for every Xcode command.
- Stop on the first failed test, build, validator, or source-integrity check and report the evidence.

---

## File Map

### Application and project

- `LifeGrid.xcodeproj/project.pbxproj` - native app, unit-test, and UI-test target definitions.
- `LifeGrid.xcodeproj/xcshareddata/xcschemes/LifeGrid.xcscheme` - shared build and test scheme.
- `LifeGrid/App/LifeGridApp.swift` - application entry point and production dependency composition.
- `LifeGrid/App/FoundationRootView.swift` - compile-only Phase 1 root view with no approved feature screen.
- `LifeGrid/App/AppEnvironment.swift` - injected live dependencies.
- `LifeGrid/App/AppStateStore.swift` - observable state owner, load/save, mutation, and retry flow.
- `LifeGrid/Models/*.swift` - versioned value-type state and stable identifiers.
- `LifeGrid/Persistence/*.swift` - repository protocol, JSON implementation, and migrations.
- `LifeGrid/Shared/Feedback/*.swift` - haptics and sound interfaces.
- `LifeGrid/Shared/Randomness/*.swift` - deterministic randomness interface.
- `LifeGrid/Shared/Time/*.swift` - injectable clock.
- `LifeGrid/Shared/Theme/*.swift` - appearance, app-scale, and touch-target tokens.
- `LifeGrid/Shared/Layout/*.swift` - pure responsive layout-mode resolver.

### Tests

- `LifeGridTests/Models/PersistedAppStateTests.swift` - defaults, identity, and Codable tests.
- `LifeGridTests/Persistence/JSONAppStateRepositoryTests.swift` - missing file, save/reload, corruption, and schema handling.
- `LifeGridTests/App/AppStateStoreTests.swift` - load, save, retained state, and retry tests.
- `LifeGridTests/Support/TestDoubles.swift` - deterministic repository, clock, random, haptics, and sound doubles.
- `LifeGridTests/Shared/LayoutFoundationTests.swift` - responsive mode and minimum touch-target tests.
- `LifeGridUITests/LifeGridUITests.swift` - compile-only launch smoke test, not a visual acceptance test.

### Protocol and evidence

- `AGENTS.md`, `PROTOCOL.md` - repository control instructions and the exact project protocol.
- `docs/approved/*` - exact supplied product spec, implementation prompt, PDF, overview, and icon references.
- `protocol/validate.py`, `protocol/tests/test_validate.py` - gate validator and tests.
- `protocol/requirements.json`, `protocol/visual-references.json` - traceability manifests.
- `protocol/schemas/*.json` - structural schemas.
- `approvals/*`, `changes/TEMPLATE.md`, `backlog/SUGGESTED_IMPROVEMENTS.md` - immutable gate and change-control structure.
- `reviews/architecture/*.md` - six Gate 1 architecture evidence documents.
- `reports/test-results/*` - machine-readable result bundles and evidence summaries.

---

### Task 1: Protocol validator and control structure

**Requirement IDs:** APP-001, APP-002, APP-003, TEST-001

**Files:**
- Create: `AGENTS.md`
- Create: `PROTOCOL.md`
- Create: `protocol/validate.py`
- Create: `protocol/tests/test_validate.py`
- Create: `protocol/schemas/requirements.schema.json`
- Create: `protocol/schemas/visual-references.schema.json`
- Create: `protocol/schemas/approval.schema.json`
- Create: `protocol/schemas/variance.schema.json`
- Create: `protocol/schemas/change-request.schema.json`
- Create: `approvals/templates/APPROVAL_TEMPLATE.md`
- Create: `approvals/01-architecture-approved.md`
- Create: `approvals/02-visuals-approved.md`
- Create: `approvals/03-build-approved.md`
- Create: `changes/TEMPLATE.md`
- Create: `backlog/SUGGESTED_IMPROVEMENTS.md`
- Create: `reports/COMPLIANCE_REPORT_TEMPLATE.md`

**Interfaces:**
- Consumes: repository root and JSON/Markdown evidence files.
- Produces: `python3 protocol/validate.py gate architecture`, `gate visuals`, `gate build`, and `full` commands with process exit status 0 on success and 1 on validation failure.

- [ ] **Step 1: Copy the approved project protocol exactly**

Copy the supplied `Life_Grid_Codex_Design_Control_Protocol.md` bytes to root `PROTOCOL.md`. Verify exact identity:

```bash
cmp -s '/Users/ashcraft/Library/Mobile Documents/com~apple~CloudDocs/Projects/Mtg life counter/Life_Grid_Codex_Design_Control_Protocol.md' PROTOCOL.md
```

Expected: exit 0 and no output.

- [ ] **Step 2: Write failing validator tests**

Create `protocol/tests/test_validate.py` with tests that construct temporary repositories and assert:

```python
import json
import tempfile
import unittest
from pathlib import Path

from protocol.validate import ValidationResult, validate_architecture


class ArchitectureValidationTests(unittest.TestCase):
    def test_missing_required_architecture_evidence_fails(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            result = validate_architecture(Path(directory))
        self.assertFalse(result.passed)
        self.assertIn("missing architecture evidence", "\n".join(result.errors))

    def test_duplicate_requirement_ids_fail(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            create_minimum_architecture_fixture(root)
            requirements = json.loads((root / "protocol/requirements.json").read_text())
            requirements.append(requirements[0])
            (root / "protocol/requirements.json").write_text(json.dumps(requirements))
            result = validate_architecture(root)
        self.assertFalse(result.passed)
        self.assertIn("duplicate requirement id", "\n".join(result.errors))

    def test_pending_approval_is_the_only_allowed_preapproval_blocker(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            create_minimum_architecture_fixture(root, approval_complete=False)
            result = validate_architecture(root)
        self.assertEqual(result.errors, ["architecture approval is pending"])
```

Include `create_minimum_architecture_fixture` in the same test file. It must create the six evidence files, one valid planned requirement, a referenced reviewed commit supplied as `HEAD`, and an incomplete or complete approval record.

- [ ] **Step 3: Run the validator tests and verify RED**

Run:

```bash
python3 -m unittest protocol.tests.test_validate -v
```

Expected: import failure because `protocol.validate` does not exist.

- [ ] **Step 4: Implement the minimal validator API**

Create `protocol/validate.py` with:

```python
from __future__ import annotations

import argparse
import json
import subprocess
from dataclasses import dataclass, field
from pathlib import Path


ARCHITECTURE_EVIDENCE = (
    "architecture-summary.md",
    "state-model.md",
    "dependency-map.md",
    "persistence-plan.md",
    "test-strategy.md",
    "risk-register.md",
)


@dataclass
class ValidationResult:
    errors: list[str] = field(default_factory=list)

    @property
    def passed(self) -> bool:
        return not self.errors


def _load_json(path: Path) -> object:
    return json.loads(path.read_text(encoding="utf-8"))


def _commit_exists(root: Path, commit: str) -> bool:
    completed = subprocess.run(
        ["git", "cat-file", "-e", f"{commit}^{{commit}}"],
        cwd=root,
        capture_output=True,
        check=False,
        text=True,
    )
    return completed.returncode == 0


def validate_architecture(root: Path) -> ValidationResult:
    result = ValidationResult()
    evidence_root = root / "reviews/architecture"
    missing = [name for name in ARCHITECTURE_EVIDENCE if not (evidence_root / name).is_file()]
    if missing:
        result.errors.append("missing architecture evidence: " + ", ".join(missing))

    requirements_path = root / "protocol/requirements.json"
    if not requirements_path.is_file():
        result.errors.append("missing requirement manifest")
    else:
        try:
            requirements = _load_json(requirements_path)
            identifiers = [entry["id"] for entry in requirements]
            duplicates = sorted({item for item in identifiers if identifiers.count(item) > 1})
            if duplicates:
                result.errors.append("duplicate requirement id: " + ", ".join(duplicates))
            for entry in requirements:
                if entry.get("architecture_relevant") and (
                    not entry.get("planned_implementation") or not entry.get("planned_tests")
                ):
                    result.errors.append(f"architecture requirement lacks plan: {entry['id']}")
        except (OSError, ValueError, KeyError, TypeError) as error:
            result.errors.append(f"invalid requirement manifest: {error}")

    approval_path = root / "approvals/01-architecture-approved.md"
    approval_text = approval_path.read_text(encoding="utf-8") if approval_path.is_file() else ""
    approval_complete = "Explicit approval statement: APPROVED" in approval_text
    if not approval_complete:
        result.errors.append("architecture approval is pending")
    else:
        reviewed_commit = next(
            (line.split(":", 1)[1].strip() for line in approval_text.splitlines() if line.startswith("- Reviewed commit:")),
            "",
        )
        if not reviewed_commit or not _commit_exists(root, reviewed_commit):
            result.errors.append("reviewed commit does not exist")
    return result


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("command", choices=("gate", "full"))
    parser.add_argument("gate_name", nargs="?", choices=("architecture", "visuals", "build"))
    parser.add_argument("--root", type=Path, default=Path.cwd())
    args = parser.parse_args()
    if args.command == "gate" and args.gate_name == "architecture":
        result = validate_architecture(args.root)
    else:
        result = ValidationResult(["gate is not available in Phase 1"])
    for error in result.errors:
        print(f"FAIL: {error}")
    if result.passed:
        print("PASS")
    return 0 if result.passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
```

Extend this minimal implementation in the same task so `gate visuals`, `gate build`, and `full` validate their required file categories without reporting success when those gates are pending. `full` must write `reports/final-compliance-report.md` only after running all three gates.

- [ ] **Step 5: Run validator tests and verify GREEN**

Run:

```bash
python3 -m unittest protocol.tests.test_validate -v
```

Expected: all validator tests pass.

- [ ] **Step 6: Create static schemas and templates**

Each JSON schema must require the exact fields stated in `PROTOCOL.md`. Approval files begin as clearly incomplete templates with `- Explicit approval statement:` blank; they must never contain inferred approval.

Root `AGENTS.md` must include all thirteen enforcement rules from Protocol section 5 and require a task declaration before modifications.

- [ ] **Step 7: Commit the protocol foundation**

```bash
git add AGENTS.md PROTOCOL.md protocol approvals changes backlog reports
git diff --cached --check
git commit -m "chore: establish Life Grid design controls"
```

Expected: commit succeeds only after the tests and exact protocol comparison pass.

### Task 2: Native Xcode project and compile-only app shell

**Requirement IDs:** APP-001, APP-002, APP-003, TEST-002

**Files:**
- Create: `LifeGrid.xcodeproj/project.pbxproj`
- Create: `LifeGrid.xcodeproj/xcshareddata/xcschemes/LifeGrid.xcscheme`
- Create: `LifeGrid/App/LifeGridApp.swift`
- Create: `LifeGrid/App/FoundationRootView.swift`
- Create: `LifeGridUITests/LifeGridUITests.swift`

**Interfaces:**
- Consumes: iOS 17 SwiftUI and the production `AppEnvironment` defined in Task 5.
- Produces: `LifeGrid.app`, `LifeGridTests.xctest`, `LifeGridUITests.xctest`, and the shared `LifeGrid` scheme.

- [ ] **Step 1: Create exact native project configuration**

Create a native project with three targets and file-system-synchronized groups for `LifeGrid`, `LifeGridTests`, and `LifeGridUITests`. Use these build settings in both Debug and Release where applicable:

```text
PRODUCT_NAME = "Life Grid"
PRODUCT_BUNDLE_IDENTIFIER = com.ashathe.lifegrid
IPHONEOS_DEPLOYMENT_TARGET = 17.0
SUPPORTED_PLATFORMS = "iphoneos iphonesimulator"
TARGETED_DEVICE_FAMILY = "1,2"
SWIFT_VERSION = 6.0
SWIFT_STRICT_CONCURRENCY = complete
GENERATE_INFOPLIST_FILE = YES
INFOPLIST_KEY_CFBundleDisplayName = "Life Grid"
INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES
CODE_SIGN_STYLE = Automatic
```

The app target links SwiftUI and Foundation only. Unit and UI targets depend on the app target. The shared scheme builds the app, runs both test targets, and uses Debug for tests.

- [ ] **Step 2: Add the compile-only app entry**

Create:

```swift
import SwiftUI

@main
struct LifeGridApp: App {
    var body: some Scene {
        WindowGroup {
            FoundationRootView()
        }
    }
}
```

and:

```swift
import SwiftUI

struct FoundationRootView: View {
    var body: some View {
        Color.clear
            .ignoresSafeArea()
            .accessibilityHidden(true)
    }
}
```

The clear view is intentionally not a New Game, Game, Counters, Dice, or Settings implementation.

- [ ] **Step 3: Add a launch smoke UI test**

```swift
import XCTest

final class LifeGridUITests: XCTestCase {
    func testFoundationAppLaunches() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertEqual(app.state, .runningForeground)
    }
}
```

- [ ] **Step 4: Build the app for iPhone and iPad simulators**

Run:

```bash
env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project LifeGrid.xcodeproj -scheme LifeGrid -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' build
```

Then run the same command with destination `platform=iOS Simulator,name=iPad Pro 13-inch (M5),OS=26.5`.

Expected: both commands end with `** BUILD SUCCEEDED **`.

- [ ] **Step 5: Commit the native shell**

```bash
git add LifeGrid.xcodeproj LifeGrid LifeGridUITests
git diff --cached --check
git commit -m "build: add native Life Grid app targets"
```

### Task 3: Versioned domain state and approved defaults

**Requirement IDs:** PST-001, PST-004, APP-004, SET-001, VIS-001

**Files:**
- Create: `LifeGrid/Models/PersistedAppState.swift`
- Create: `LifeGrid/Models/AppPreferences.swift`
- Create: `LifeGrid/Models/GameSetup.swift`
- Create: `LifeGrid/Models/ActiveGame.swift`
- Create: `LifeGrid/Models/OpponentState.swift`
- Create: `LifeGrid/Models/CounterModels.swift`
- Create: `LifeGrid/Models/DiceModels.swift`
- Create: `LifeGridTests/Models/PersistedAppStateTests.swift`

**Interfaces:**
- Produces: `PersistedAppState.default`, `PersistedAppState.currentSchemaVersion`, stable `PlayerID`, stable `CounterID`, and all Codable types consumed by persistence and store tasks.

- [ ] **Step 1: Write failing default and round-trip tests**

```swift
import Foundation
import Testing
@testable import LifeGrid

struct PersistedAppStateTests {
    @Test func approvedDefaultsAreStable() {
        let state = PersistedAppState.default
        #expect(state.schemaVersion == 1)
        #expect(state.preferences.playerName == "")
        #expect(state.preferences.commanderEnabled)
        #expect(!state.preferences.ownPartnerCommanderEnabled)
        #expect(state.preferences.commanderDamageChangesLife)
        #expect(state.preferences.keepScreenAwakeDuringGames)
        #expect(state.preferences.hapticsEnabled)
        #expect(!state.preferences.soundEffectsEnabled)
        #expect(state.preferences.appearance == .dark)
        #expect(state.preferences.appScale == .balanced)
        #expect(state.lastSetup == GameSetup(totalPlayers: 4, startingLife: 40, opponentNames: []))
        #expect(state.activeGame == nil)
        #expect(state.customCounters.isEmpty)
        #expect(state.savedDice.isEmpty)
        #expect(state.diceHistory.isEmpty)
    }

    @Test func completeStateRoundTripsThroughJSON() throws {
        let original = PersistedAppState.fixtureComplete
        let data = try JSONEncoder.lifeGrid.encode(original)
        let restored = try JSONDecoder.lifeGrid.decode(PersistedAppState.self, from: data)
        #expect(restored == original)
    }

    @Test func playerIdentityDoesNotDependOnName() {
        let id = UUID()
        #expect(PlayerID.opponent(id) == PlayerID.opponent(id))
        #expect(PlayerID.local != PlayerID.opponent(id))
    }
}
```

`fixtureComplete` must include one visible opponent, one hidden opponent, partner data, negative local life, tax, Monarch, City’s Blessing, numeric and Day/Night state, built-in and custom pins, saved custom dice, and five complete dice-roll entries.

- [ ] **Step 2: Run the tests and verify RED**

Run:

```bash
env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project LifeGrid.xcodeproj -scheme LifeGrid -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' -only-testing:LifeGridTests/PersistedAppStateTests test
```

Expected: compile failure because `PersistedAppState` is undefined.

- [ ] **Step 3: Implement the approved value model**

Use the product-spec conceptual model verbatim, adding `Equatable`, `Sendable`, and stable tagged identities. Required identity shapes are:

```swift
enum PlayerID: Codable, Equatable, Hashable, Sendable {
    case local
    case opponent(UUID)
}

enum BuiltInCounterID: String, Codable, CaseIterable, Sendable {
    case poison, energy, experience, treasure, radiation, storm, charge, doom, tickets, dayNight
}

enum CounterID: Codable, Equatable, Hashable, Sendable {
    case builtIn(BuiltInCounterID)
    case custom(UUID)
}
```

`PersistedAppState.default` uses total players 4 and starting life 40 exactly. `diceHistory` is stored as complete entries; no view-only collapse state is part of the model.

- [ ] **Step 4: Run all model tests and verify GREEN**

Run the Task 3 test command again.

Expected: all `PersistedAppStateTests` pass with no warnings.

- [ ] **Step 5: Commit domain state**

```bash
git add LifeGrid/Models LifeGridTests/Models
git diff --cached --check
git commit -m "feat: add versioned Life Grid domain state"
```

### Task 4: Atomic JSON repository and migrations

**Requirement IDs:** PST-002, PST-005, TEST-003

**Files:**
- Create: `LifeGrid/Persistence/AppStateRepository.swift`
- Create: `LifeGrid/Persistence/JSONAppStateRepository.swift`
- Create: `LifeGrid/Persistence/StateMigration.swift`
- Create: `LifeGridTests/Persistence/JSONAppStateRepositoryTests.swift`

**Interfaces:**
- Produces: `AppStateRepository.load() async throws -> PersistedAppState`, `save(_:) async throws`, and schema migration errors.

- [ ] **Step 1: Write failing repository tests**

Tests must verify:

```swift
@Test func missingFileLoadsApprovedDefaults() async throws
@Test func savedCompleteStateReloadsExactly() async throws
@Test func unsupportedFutureSchemaThrowsWithoutReplacingFile() async throws
@Test func corruptJSONThrowsWithoutDeletingFile() async throws
```

Each test uses a unique temporary directory supplied to the repository. `savedCompleteStateReloadsExactly` also asserts no sibling temporary file remains after success.

- [ ] **Step 2: Run repository tests and verify RED**

Run the Xcode test command with `-only-testing:LifeGridTests/JSONAppStateRepositoryTests`.

Expected: compile failure because `JSONAppStateRepository` does not exist.

- [ ] **Step 3: Implement repository and migration interfaces**

```swift
protocol AppStateRepository: Sendable {
    func load() async throws -> PersistedAppState
    func save(_ state: PersistedAppState) async throws
}

enum StateMigrationError: Error, Equatable {
    case unsupportedSchema(Int)
}

struct StateMigration: Sendable {
    func migrate(_ data: Data, decoder: JSONDecoder = .lifeGrid) throws -> PersistedAppState
}
```

`JSONAppStateRepository` is an actor. It creates Application Support on demand, encodes to data, and uses `Data.write(to:options: .atomic)` for replacement. It decodes a small schema-version envelope before invoking `StateMigration`.

- [ ] **Step 4: Run repository and model tests and verify GREEN**

Run both test suites. Expected: all pass with no warnings.

- [ ] **Step 5: Commit persistence**

```bash
git add LifeGrid/Persistence LifeGridTests/Persistence
git diff --cached --check
git commit -m "feat: add atomic local state persistence"
```

### Task 5: Injected environment and deterministic test doubles

**Requirement IDs:** TEST-001, DICE-001, SET-002

**Files:**
- Create: `LifeGrid/App/AppEnvironment.swift`
- Create: `LifeGrid/Shared/Randomness/RandomSource.swift`
- Create: `LifeGrid/Shared/Time/ClockClient.swift`
- Create: `LifeGrid/Shared/Feedback/HapticsClient.swift`
- Create: `LifeGrid/Shared/Feedback/SoundClient.swift`
- Create: `LifeGridTests/Support/TestDoubles.swift`
- Create: `LifeGridTests/App/AppEnvironmentTests.swift`

**Interfaces:**
- Produces: dependency interfaces used by the store and approved future feature intents.

- [ ] **Step 1: Write failing deterministic dependency tests**

```swift
@Test func deterministicRandomSourceReturnsScriptedValues() async
@Test func testClockReturnsFixedDate() async
@Test func recordingFeedbackClientsCaptureEvents() async
```

The random test scripts `[4, 1, 3]` and asserts the same order. Feedback tests record `.adjustment` and `.warning` haptic events and `.diceResult` sound events without using device hardware.

- [ ] **Step 2: Run and verify RED**

Expected: compile failure because the client protocols do not exist.

- [ ] **Step 3: Implement minimal interfaces and live no-op-safe clients**

```swift
protocol RandomSource: Sendable {
    func nextInt(in range: ClosedRange<Int>) async -> Int
}

protocol ClockClient: Sendable {
    func now() async -> Date
}

enum HapticEvent: Sendable { case adjustment, statusChange, result, warning }
protocol HapticsClient: Sendable { func play(_ event: HapticEvent) async }

enum SoundEvent: Sendable { case diceResult, coinFlip, lethalWarning }
protocol SoundClient: Sendable { func play(_ event: SoundEvent) async }
```

`AppEnvironment.live()` composes the JSON repository, system clock, system random source, and Phase 1 no-op feedback clients. UIKit and audio behavior are not implemented in this phase.

- [ ] **Step 4: Run dependency tests and verify GREEN**

Expected: all dependency tests pass deterministically.

- [ ] **Step 5: Commit dependency boundaries**

```bash
git add LifeGrid/App/AppEnvironment.swift LifeGrid/Shared LifeGridTests/Support LifeGridTests/App/AppEnvironmentTests.swift
git diff --cached --check
git commit -m "feat: add injectable Life Grid services"
```

### Task 6: Observable application-state store

**Requirement IDs:** PST-003, PST-005, TEST-004

**Files:**
- Create: `LifeGrid/App/AppStateStore.swift`
- Create: `LifeGridTests/App/AppStateStoreTests.swift`
- Modify: `LifeGrid/App/LifeGridApp.swift`

**Interfaces:**
- Consumes: `AppEnvironment`, `AppStateRepository`, and `PersistedAppState`.
- Produces: main-actor observable `state`, `load()`, test-only foundation mutation intent, and persistence diagnostic state.

- [ ] **Step 1: Write failing store tests**

```swift
@MainActor @Test func loadPublishesPersistedState() async
@MainActor @Test func missingStateLoadsDefaults() async
@MainActor @Test func meaningfulMutationSavesImmediately() async
@MainActor @Test func saveFailureRetainsMutatedInMemoryState() async
@MainActor @Test func nextMutationRetriesAfterSaveFailure() async
```

Use a scripted repository actor that can return a state, throw on a specified save call, and record all saved snapshots.

- [ ] **Step 2: Run store tests and verify RED**

Expected: compile failure because `AppStateStore` does not exist.

- [ ] **Step 3: Implement the minimal store**

```swift
import Foundation
import Observation

@MainActor
@Observable
final class AppStateStore {
    private(set) var state: PersistedAppState
    private(set) var persistenceErrorDescription: String?
    private let environment: AppEnvironment

    init(environment: AppEnvironment, initialState: PersistedAppState = .default) {
        self.environment = environment
        self.state = initialState
    }

    func load() async {
        do {
            state = try await environment.repository.load()
            persistenceErrorDescription = nil
        } catch {
            persistenceErrorDescription = String(describing: error)
        }
    }

    func applyFoundationMutation(_ mutation: (inout PersistedAppState) -> Void) async {
        mutation(&state)
        await persistCurrentState()
    }

    private func persistCurrentState() async {
        do {
            try await environment.repository.save(state)
            persistenceErrorDescription = nil
        } catch {
            persistenceErrorDescription = String(describing: error)
        }
    }
}
```

Keep `applyFoundationMutation` internal so the app target's future views cannot bypass feature-specific intent methods. The next mutation naturally retries the complete current snapshot.

- [ ] **Step 4: Compose and load the store at app launch**

`LifeGridApp` owns one `@State` store created from `AppEnvironment.live()` and invokes `await store.load()` once from `.task` on the compile-only root.

- [ ] **Step 5: Run store tests and verify GREEN**

Expected: all store tests pass and no Swift concurrency warnings appear.

- [ ] **Step 6: Commit the store**

```bash
git add LifeGrid/App LifeGridTests/App/AppStateStoreTests.swift
git diff --cached --check
git commit -m "feat: add observable persisted app store"
```

### Task 7: Responsive, appearance, scale, and accessibility foundations

**Requirement IDs:** VIS-001, VIS-002, VIS-003, A11Y-001, A11Y-002

**Files:**
- Create: `LifeGrid/Shared/Layout/GameLayoutMode.swift`
- Create: `LifeGrid/Shared/Theme/AppearanceTokens.swift`
- Create: `LifeGrid/Shared/Theme/AppScaleTokens.swift`
- Create: `LifeGrid/Shared/Accessibility/AccessibilityValues.swift`
- Create: `LifeGridTests/Shared/LayoutFoundationTests.swift`

**Interfaces:**
- Produces: pure layout-mode resolution, semantic scale metrics, and accessibility value helpers for feature screens.

- [ ] **Step 1: Write failing foundation tests**

```swift
@Test func portraitPhoneUsesSingleColumn()
@Test func landscapePhoneUsesTwoColumns()
@Test func regularWidthUsesTwoColumns()
@Test(arguments: AppScale.allCases) func everyScaleKeepsMinimumTouchTarget(_ scale: AppScale)
@Test func appScaleDoesNotEncodeDynamicType()
```

Use explicit contexts: `390x844 compact`, `844x390 compact`, and `1024x1366 regular`. Every scale must return a minimum touch target of at least 44.

- [ ] **Step 2: Run and verify RED**

Expected: compile failure because the layout resolver and tokens do not exist.

- [ ] **Step 3: Implement pure layout and scale APIs**

```swift
enum GameLayoutMode: Equatable, Sendable { case singleColumn, twoColumn }

struct GameLayoutContext: Equatable, Sendable {
    var width: Double
    var height: Double
    var horizontalSizeClassIsRegular: Bool
}

extension GameLayoutMode {
    static func resolve(_ context: GameLayoutContext) -> Self {
        context.horizontalSizeClassIsRegular || context.width > context.height
            ? .twoColumn
            : .singleColumn
    }
}

struct AppScaleMetrics: Equatable, Sendable {
    let spacingMultiplier: Double
    let minimumTouchTarget: Double
}
```

Map Compact, Balanced, and Large to spacing multipliers `0.85`, `1.0`, and `1.15`, with `minimumTouchTarget` fixed at `44` for every case. Theme tokens use semantic names for background, surface, primary accent, lethal, destructive, primary text, and secondary text; feature views do not hard-code color meaning.

- [ ] **Step 4: Run and verify GREEN**

Expected: all layout foundation tests pass.

- [ ] **Step 5: Commit layout and accessibility foundations**

```bash
git add LifeGrid/Shared LifeGridTests/Shared
git diff --cached --check
git commit -m "feat: add responsive and accessible design foundations"
```

### Task 8: Approved artifacts and complete traceability manifests

**Requirement IDs:** all approved requirement IDs; no requirement becomes `verified` in this task.

**Files:**
- Create: `docs/approved/Life_Grid_Product_Spec.md`
- Create: `docs/approved/Life_Grid_Codex_Implementation_Prompt.md`
- Create: `docs/approved/Life_Grid_Approved_Designs.pdf`
- Create: `docs/approved/00_Approved_Designs_Overview.png`
- Create: `docs/approved/Life_Grid_Selected_Icon_Reference.png`
- Create: `docs/approved/Life_Grid_Icon_Concept_Sheet.png`
- Create: `docs/approved/SOURCE_INTEGRITY.md`
- Create: `protocol/requirements.json`
- Create: `protocol/visual-references.json`

**Interfaces:**
- Produces: immutable source copies and stable IDs consumed by all validators, tasks, tests, reviews, and approval records.

- [ ] **Step 1: Copy supplied artifacts without transformation**

Extract the ZIP to a temporary directory and copy the two Markdown authorities and two icon PNGs. Copy the separately supplied PDF and overview PNG. Do not resize, recompress, normalize, or edit any artifact.

- [ ] **Step 2: Verify source identity**

Use `cmp -s` for every copied artifact. Record these supplied SHA-256 values in `SOURCE_INTEGRITY.md`:

```text
Life_Grid_Codex_Design_Control_Protocol.md 8fdf63c8a22622c13cc7fce7870bd815aec03ae6c005e14310757322809b1983
Life_Grid_Approved_Designs.pdf             4c605dceafeb795e85febed34c25606f0ac65c72bc982ea87413abd7cb54d8fb
Life_Grid_Codex_Package.zip                5f9d7fa54cfe2ffa36ce4930c24dd4f37c2cd83ed90cb21803cc9c7466c7b6f2
00_Approved_Designs_Overview.png           106e2f20b2d0e9b2589849f404dc19aa6a619128dd9ef864fad76f2f45855c15
```

Also record fresh SHA-256 values for each extracted package member.

- [ ] **Step 3: Populate the complete requirement manifest**

Assign stable IDs by specification section using these exact families:

```text
APP-001...APP-004  product identity, local-only behavior, platform, excluded capabilities
NAV-001...NAV-002  four-tab navigation and active-game resume routing
NEW-001...NEW-008  section 8 and New Game acceptance criteria
LIFE-001...LIFE-007 section 10.1-10.3 life behavior and undo
CMD-001...CMD-011 section 10.4 and section 11 commander behavior
OPP-001...OPP-013 sections 9, 12, and 13 opponent behavior
STS-001...STS-007 section 14 statuses
CTR-001...CTR-014 section 15 built-ins, values, Day/Night, and pins
CST-001...CST-007 section 16 custom counters
WARN-001...WARN-008 section 17 warnings
DICE-001...DICE-016 section 18 dice and randomizers
SET-001...SET-012 sections 3, 19, and 20 preferences
RST-001...RST-009 section 21 reset and preservation
PST-001...PST-008 sections 5 and 22 persistence
VIS-001...VIS-009 sections 3 and 4 visual identity and responsive behavior
A11Y-001...A11Y-010 section 23 accessibility
TEST-001...TEST-020 section 28 mandatory automated tests
```

Every entry contains `id`, `title`, `spec_section`, `visual_references`, `implementation_files`, `test_files`, `evidence_files`, `status`, `architecture_relevant`, `planned_implementation`, `planned_tests`, `approved_variance`, and `change_request`. Phase 1 foundation entries may be `implemented` after code exists but cannot be `verified` until their evidence is saved. Product-feature entries remain `not_started` or `deferred_by_approval`.

- [ ] **Step 4: Register all approved visual references**

Create entries for:

```text
new-game
game-iphone
counters
dice
settings
status-player-sheets
quick-restart
game-ipad
approved-icon
```

Each entry names its PDF page, required device classes/orientations, Dark/System/Light, Compact/Balanced/Large, related IDs, review directory, and `current_approval_status: not_started`. The approved icon entry points to the exact selected reference PNG and forbids redesign.

- [ ] **Step 5: Validate manifests and source integrity**

Run validator unit tests, JSON parsing through `python3 -m json.tool`, and every `cmp -s` comparison. Expected: all pass.

- [ ] **Step 6: Commit approved sources and manifests**

```bash
git add docs/approved protocol/requirements.json protocol/visual-references.json
git diff --cached --check
git commit -m "docs: register approved Life Grid requirements"
```

### Task 9: Gate 1 architecture evidence

**Requirement IDs:** APP-001...APP-004, PST-001...PST-005, VIS-002, VIS-003, A11Y-001, A11Y-002, TEST-001...TEST-004

**Files:**
- Create: `reviews/architecture/architecture-summary.md`
- Create: `reviews/architecture/state-model.md`
- Create: `reviews/architecture/dependency-map.md`
- Create: `reviews/architecture/persistence-plan.md`
- Create: `reviews/architecture/test-strategy.md`
- Create: `reviews/architecture/risk-register.md`

**Interfaces:**
- Consumes: the actual implemented foundation and approved design.
- Produces: the complete evidence set required by Architecture Gate 1.

- [ ] **Step 1: Write evidence from implemented code**

Every document names the exact implementation files and relevant requirement IDs. The dependency map must show:

```text
LifeGridApp -> AppEnvironment -> AppStateStore
AppStateStore -> AppStateRepository -> JSONAppStateRepository -> Application Support JSON
AppEnvironment -> RandomSource | ClockClient | HapticsClient | SoundClient
SwiftUI feature boundary -> feature intent -> AppStateStore -> persisted snapshot
```

The risk register includes severity, likelihood, mitigation, evidence, and gate status for: JSON corruption, unsupported future schema, save failure, Swift concurrency isolation, manual Xcode project drift, Dynamic Type pressure in two columns, missing reusable protocol template, and icon asset production deferred from Phase 1.

- [ ] **Step 2: Cross-check evidence against code**

Use `rg` to verify every cited file and type exists. No evidence document may claim feature behavior, visual completion, forced-relaunch success, or Gate 1 approval.

- [ ] **Step 3: Commit architecture evidence**

```bash
git add reviews/architecture
git diff --cached --check
git commit -m "docs: add Life Grid architecture evidence"
```

### Task 10: Full Phase 1 verification and reviewed commit

**Requirement IDs:** all Phase 1 architecture-relevant IDs

**Files:**
- Create: `reports/test-results/phase1-unit-tests.xcresult`
- Create: `reports/test-results/phase1-ui-smoke.xcresult`
- Create: `reports/test-results/phase1-iphone-build.xcresult`
- Create: `reports/test-results/phase1-ipad-build.xcresult`
- Create: `reports/test-results/phase1-verification.md`
- Modify: `protocol/requirements.json` statuses and evidence paths

**Interfaces:**
- Produces: the reviewed foundation commit and pre-approval validator evidence.

- [ ] **Step 1: Run all Python tests**

```bash
python3 -m unittest discover -s protocol/tests -v
```

Expected: all tests pass.

- [ ] **Step 2: Run all Swift unit tests**

```bash
env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project LifeGrid.xcodeproj -scheme LifeGrid -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' -resultBundlePath reports/test-results/phase1-unit-tests.xcresult test
```

Expected: `** TEST SUCCEEDED **` with zero failures and no concurrency warnings.

- [ ] **Step 3: Run UI launch smoke test**

Run the same command with `-only-testing:LifeGridUITests/LifeGridUITests/testFoundationAppLaunches` and `-resultBundlePath reports/test-results/phase1-ui-smoke.xcresult`.

Expected: one UI test passes.

- [ ] **Step 4: Build iPhone and iPad variants**

Run `xcodebuild build` for the approved iPhone and iPad destinations with separate result-bundle paths. Expected: both succeed.

- [ ] **Step 5: Run protocol and repository integrity checks**

Run:

```bash
python3 -m json.tool protocol/requirements.json
python3 -m json.tool protocol/visual-references.json
cmp -s '/Users/ashcraft/Library/Mobile Documents/com~apple~CloudDocs/Projects/Mtg life counter/Life_Grid_Codex_Design_Control_Protocol.md' PROTOCOL.md
git diff --check
```

Expected: all commands exit 0.

- [ ] **Step 6: Save the verification summary**

`phase1-verification.md` records command, date, current commit, Xcode/Swift versions, destination, result bundle, pass/fail counts, warnings, and limitations. Update Phase 1 manifest entries to `verified` only when their implementation, test, and evidence paths all exist.

- [ ] **Step 7: Create the reviewed commit**

```bash
git add reports/test-results protocol/requirements.json
git diff --cached --check
git commit -m "test: verify Life Grid Phase 1 foundation"
```

- [ ] **Step 8: Run the pre-approval architecture gate**

```bash
python3 protocol/validate.py gate architecture
```

Expected: exit 1 with exactly `FAIL: architecture approval is pending`. Any additional failure blocks the milestone and must be reported immediately.

- [ ] **Step 9: Present Gate 1 review and stop**

Report the reviewed commit, architecture evidence, test and build results, risk register, exact validator output, remaining limitations, and explicit request for Architecture Gate 1 approval. Do not create or populate the approval record before the user approves this reviewed commit.

### Task 11: Record explicit Architecture Gate 1 approval

**Requirement IDs:** Gate control only

**Files:**
- Modify: `approvals/01-architecture-approved.md`
- Create: `reports/test-results/phase1-architecture-validator.txt`

**Interfaces:**
- Consumes: explicit user approval of the exact reviewed commit from Task 10.
- Produces: immutable approval record and a passing Architecture Gate 1 validator.

- [ ] **Step 1: Confirm approval targets the reviewed commit**

The approval must explicitly name or unambiguously respond to the Gate 1 review for the current reviewed commit. If the user requests changes, return to the affected task and generate a new reviewed commit instead of recording approval.

- [ ] **Step 2: Write the immutable approval record**

Populate every protocol-required field. Use:

```text
- Validator result: Pre-approval validation blocked only by pending explicit approval
- Explicit approval statement: APPROVED
```

Record the exact reviewed commit, evidence paths, reviewer, date, accepted variances, rejected variances, and follow-up requirements. Do not edit this record after acceptance.

- [ ] **Step 3: Commit the approval record**

```bash
git add approvals/01-architecture-approved.md
git diff --cached --check
git commit -m "docs: record Life Grid architecture approval"
```

- [ ] **Step 4: Run Architecture Gate 1 validator**

```bash
python3 protocol/validate.py gate architecture
```

Expected: exit 0 and `PASS`.

- [ ] **Step 5: Save and commit validator evidence**

Save the exact command, date, approval-record commit, and `PASS` output in `reports/test-results/phase1-architecture-validator.txt`, then commit it without altering the immutable approval record.

- [ ] **Step 6: Report Phase 1 completion evidence**

Use the protocol Completion Evidence template. State that Architecture Gate 1 passed, list all files and commands, identify the missing reusable protocol template as an unresolved handoff limitation, and state that Phase 2 has not started.
