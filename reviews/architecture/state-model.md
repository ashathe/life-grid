# Life Grid State Model

## Persisted root

`LifeGrid/Models/PersistedAppState.swift` defines schema version 1 with these complete roots:

- `AppPreferences`
- last `GameSetup`
- optional `ActiveGame`
- custom-counter definitions
- saved custom dice
- dice-roll history

Approved first-launch values are centralized in `PersistedAppState.default` and `AppPreferences.default`. Tests in `LifeGridTests/Models/PersistedAppStateTests.swift` lock those values and prove a complete JSON round trip, including negative life, custom and built-in counter identifiers, hidden opponents, partner commander state, status ownership, and complete dice results.

## Identity

`PlayerID` is tagged as either `.local` or `.opponent(UUID)`, so player identity does not depend on a mutable name or card position. `CounterID` similarly distinguishes stable built-in identifiers from custom UUIDs. `OpponentState` deliberately has no life field, preserving the approved local-player-only life boundary (APP-002, APP-004, PST-001).

## Active game

`ActiveGame` carries local starting/current life, opponents, commander names and tax, Monarch ownership, City’s Blessing, counter values, Day/Night, pinned counters, and a keep-awake override. Transient sheets, animations, banners, form drafts, and validation messages are excluded from persisted state (PST-001).

## Mutation ownership

`LifeGrid/App/AppStateStore.swift` owns the in-memory snapshot on `@MainActor`. Its internal Phase 1 mutation path changes value state and immediately asks the repository to save the complete snapshot. SwiftUI has no direct binding that can write persisted state. Later features must add named intent methods rather than exposing writable state.

## Versioning boundary

The root carries `schemaVersion`. `LifeGrid/Persistence/StateMigration.swift` first decodes a minimal version envelope, accepts version 1, and rejects unsupported versions with `StateMigrationError.unsupportedSchema`. Future migrations can be inserted there without changing views or the repository contract (PST-005).
