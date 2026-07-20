# Life Grid Phase 1 Foundation Design

**Status:** User-approved design
**Approval date:** 2026-07-20
**Scope:** Phase 1 - Project foundation and Gate 1 architecture evidence

## Authority

This design implements the first phase defined by `Life_Grid_Codex_Implementation_Prompt.md` under the controls in the Life Grid Design-Control Protocol. Product behavior remains governed by `Life_Grid_Product_Spec.md`; approved visual references govern later screen implementation. This document does not authorize a feature, layout, icon, or behavior that is absent from those sources.

The approved source order is:

1. Later explicit user corrections and approved change requests.
2. `Life_Grid_Product_Spec.md`.
3. Approved visual layouts and `Life_Grid_Approved_Designs.pdf`.
4. `Life_Grid_Codex_Implementation_Prompt.md`.
5. Native SwiftUI conventions where the approved materials are silent.

## Phase 1 Outcome

Phase 1 creates a compiling universal SwiftUI project, the domain and persistence foundation, deterministic dependency boundaries, initial automated tests, the protocol control structure, and all Gate 1 architecture evidence. It does not implement or visually approve a product screen.

Full feature implementation remains blocked until the architecture gate has evidence, a reviewed commit, explicit user approval, an immutable approval record, and a passing architecture validator.

## Approved Technical Approach

Use one native Xcode project with:

- A universal `LifeGrid` iPhone and iPad application target.
- A `LifeGridTests` unit-test target.
- A `LifeGridUITests` UI-test target for later phases.
- iOS and iPadOS 17.0 as the minimum deployment target.
- Swift 6 source and SwiftUI.
- Provisional bundle identifier `com.ashathe.lifegrid`.
- No third-party runtime or project-generation dependency.

The repository follows the product specification's responsibility-based source organization. The app target remains thin: SwiftUI views observe state and send intents, while domain rules and persistence stay outside view bodies.

## Repository Boundaries

The application source is organized under `LifeGrid/`:

- `App/` owns app startup, the observable store, dependency composition, and the compile-only root view.
- `Models/` owns value-type persisted and domain state.
- `Persistence/` owns repository interfaces, JSON storage, and migrations.
- `Features/` is reserved for the approved New Game, Game, Counters, Dice, and Settings features in later phases.
- `Shared/` owns semantic theme tokens, reusable components, accessibility support, feedback clients, and utilities.

Tests mirror the responsibilities they verify rather than view hierarchy. Protocol files, gate evidence, reviews, reports, approvals, changes, and backlog records remain outside the application source tree.

## State Model

`PersistedAppState` begins at schema version 1 and contains:

- `AppPreferences`.
- The last `GameSetup`.
- An optional `ActiveGame`.
- Saved custom-counter definitions.
- Saved custom dice.
- At most five complete dice-roll history entries.

The foundation defines the complete conceptual model approved in the product specification so later phases do not need to reinterpret persistence boundaries.

Identity rules are explicit:

- `PlayerID` is a tagged value representing either the local player or an opponent UUID.
- Opponent identity never depends on display name or card order.
- `CounterID` distinguishes stable built-in counter identifiers from custom-counter UUIDs.
- Mutable names are display data only.

Transient presentation state, including open sheets, banners, animations, form drafts, and temporary validation messages, is not persisted.

## Persistence and Migrations

`AppStateRepository` defines load and save operations. `JSONAppStateRepository` stores one versioned JSON snapshot in Application Support.

Persistence behavior is:

1. No file returns the approved default application state.
2. A valid schema-version-1 file decodes to the complete state.
3. Older supported schemas pass through an ordered migration pipeline before decoding as current state.
4. An unsupported, corrupt, or unwritable snapshot produces an error without crashing the app.
5. Saves use atomic replacement so a partial write cannot become the active snapshot.

Every meaningful store mutation requests a save immediately. Phase 1 does not add a debounce; a later performance need may add a minimal debounce only if it preserves every meaningful change.

## Observable Store and Dependency Flow

`AppStateStore` is `@MainActor` and observable. It loads once during app startup and owns the current in-memory `PersistedAppState`.

The store exposes feature-specific intent methods as approved behaviors are implemented. A private mutation path applies a value-state change and then requests persistence. SwiftUI views never write persisted state directly.

`AppEnvironment` injects:

- State repository.
- Random-number source.
- Clock.
- Haptics client.
- Sound client.

Production composition supplies live implementations. Tests supply deterministic in-memory or recording implementations. Phase 1 proves the boundaries and load/save flow without implementing future game behaviors.

## Error Handling

Persistence errors do not terminate the app or erase current in-memory state. The store records the latest persistence diagnostic for debug logging and retries saving on the next meaningful mutation or lifecycle save.

No user-facing recovery workflow is introduced in Phase 1 because the approved specification does not define one. Later user-visible error behavior must follow the ambiguity and change-control rules before implementation.

Validation belongs at domain or intent boundaries. Future exact-value, player-count, die-count, custom-die, and counter-name validation must use the approved ranges and fallback wording from the product specification.

## Responsive Layout Strategy

Layout decisions use available geometry instead of device-name checks.

- iPhone portrait uses the approved single-column hierarchy.
- Landscape and regular-width environments use a true two-column Game composition.
- The left column contains local life and pinned counters.
- The right column contains opponent cards and out-of-game access.
- Each column can scroll when content requires it.
- Wide layouts do not stretch the portrait layout.

Phase 1 defines and tests layout-mode resolution and semantic layout tokens only. It does not claim any screen as visually implemented.

## Appearance and App Scale

Theme values use semantic roles rather than hard-coded meaning in feature views.

- Dark is the default appearance.
- System and Light preserve the same semantic hierarchy.
- Purple is the primary accent.
- Red is reserved for destructive actions and lethal warnings.

Compact, Balanced, and Large are semantic spacing and component-scale token sets. Balanced is the default. App scale never reduces an interactive target below 44 by 44 points and remains independent of Dynamic Type.

## Accessibility Strategy

Accessibility is part of shared component contracts from the start:

- Adjustment controls accept semantic action labels and current values.
- Meaningful value changes can post accessibility announcements.
- Player and commander names expose full accessible text even when visual space is constrained.
- Status and lethal state use text in addition to color.
- Dynamic Type may expand components vertically instead of truncating meaningful content.
- Reduce Motion replaces later coin and shuffle motion with immediate or crossfade results.
- Keyboard and pointer behavior use native SwiftUI support on iPad where available.

## Test Strategy

All executable Swift and Python behavior is developed test-first. Static Xcode configuration, copied approved artifacts, JSON schemas, and documentation are created directly and then verified structurally.

Phase 1 automated tests cover:

- Approved first-launch defaults.
- Complete schema-version-1 encode/decode round trips.
- Stable player and counter identity encoding.
- Missing-file default loading.
- Atomic repository save and reload.
- Supported and unsupported schema-version handling.
- Store load and save behavior.
- Retention of in-memory state after a save failure.
- Retry on the next mutation.
- Deterministic dependency doubles.
- Layout-mode decisions for portrait, landscape, and regular-width contexts.
- App-scale touch-target floors.

The project must build for an available iPhone simulator and an available iPad simulator using Xcode 26.6 with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`.

Swift Testing is used for unit-level model, persistence, and store behavior. XCTest remains available for UI tests in later phases.

## Protocol Control Plane

Phase 1 creates the protocol-required workspace structure:

- Root `AGENTS.md` and `PROTOCOL.md`.
- Structured requirement and visual-reference manifests.
- JSON schemas.
- A Python gate validator.
- Approval and change-request templates.
- Architecture review evidence.
- Visual-review, backlog, and test-result locations.
- Compliance-report template.

The requirement manifest assigns stable IDs across the complete approved product. Phase 1 architecture requirements receive planned implementation and test evidence; later feature requirements remain `not_started` or `deferred_by_approval` as appropriate.

The visual-reference manifest registers every approved screen and the selected icon without claiming implementation evidence.

## Gate 1 Workflow

1. Implement the compile-only foundation and tests.
2. Create the six required architecture evidence documents.
3. Save test and build evidence under `reports/test-results/`.
4. Commit the foundation as the reviewed commit.
5. Run the architecture validator. Before user approval, it may be blocked only by the missing explicit approval record.
6. Present the reviewed commit, evidence, tests, risks, and validator result to the user.
7. After explicit Gate 1 approval, create the immutable `approvals/01-architecture-approved.md` record referencing the reviewed commit.
8. Commit the approval record and rerun the architecture validator.
9. Do not begin full feature implementation unless the validator passes.

The approval record truthfully records the pre-approval validator result as blocked only by pending explicit approval. It is not edited retroactively after acceptance.

## Approved Exclusions

Phase 1 does not implement:

- New Game behavior.
- Final navigation or feature screens.
- Life controls or undo.
- Commander rules.
- Opponent management or statuses.
- Counters, pins, or custom counters.
- Dice, coin, history, or random-player tools.
- Settings behavior.
- Haptic or sound effects beyond injectable interfaces and deterministic test doubles.
- Final visual comparisons or app-icon asset production.

It also does not add opponent life totals, Initiative, networking, iCloud, CloudKit, accounts, analytics, additional tabs, or unapproved counters.

## Known Handoff Gap

The supplied Design-Control Protocol says the final handoff must include `Reusable_Codex_Design_Control_Protocol.md`, but that file was not present in the supplied directory or ZIP. It is a non-authoritative reusable template and does not block Phase 1 architecture work. The repository must record the gap and must not invent or reconstruct the missing template.

## Approved Decisions

The user explicitly approved:

- iOS and iPadOS 17.0 as the minimum supported versions.
- The single native Xcode-project approach.
- The state, persistence, store, and dependency design.
- The responsive-layout and accessibility strategy.
- The verification and Gate 1 strategy.
