# Life Grid Phase 1 Architecture Summary

## Scope and status

This evidence covers the Phase 1 foundation for APP-001 through APP-004, PST-001 through PST-005, VIS-002, VIS-003, A11Y-001, A11Y-002, and TEST-001 through TEST-004. The application is a native universal SwiftUI target with iPhone and iPad support, local JSON persistence, deterministic dependency boundaries, and pure layout/accessibility foundations.

Architecture Gate 1 is pending explicit approval. No product screen is claimed visually implemented or approved. Forced-relaunch behavior has not yet been recorded as build-gate evidence.

## Implemented boundaries

- `LifeGrid/App/` owns startup, dependency composition, the observable store, and a compile-only root view.
- `LifeGrid/Models/` owns value-type domain and persisted state.
- `LifeGrid/Persistence/` owns the repository contract, atomic JSON storage, and schema migration boundary.
- `LifeGrid/Shared/` owns randomness, time, feedback, layout, theme, and accessibility contracts.
- `LifeGridTests/` mirrors those responsibilities with deterministic unit coverage.
- `LifeGridUITests/` contains only the foundation launch smoke test.

The app target has no third-party runtime dependency and no network, account, opponent-life, Initiative, or analytics capability. The provisional bundle identifier is `com.ashathe.lifegrid`; deployment targets are iOS/iPadOS 17.0 and later.

## Decision summary

`PersistedAppState` is the single versioned value-state snapshot. `AppStateStore` is main-actor isolated and is the only foundation mutation/persistence coordinator. `AppEnvironment` injects every nondeterministic or side-effecting dependency. `JSONAppStateRepository` is an actor that serializes access to a single Application Support snapshot. Responsive behavior is resolved from geometry and size class, not device names.

## Current limitations

- Feature-specific intents and approved screens begin only after Gate 1 approval.
- Phase 1 haptic and sound clients are no-ops; hardware behavior is deferred.
- Only schema version 1 exists, so the ordered migration boundary currently rejects every other version.
- Visual review directories remain `not_started` in `protocol/visual-references.json`.
- The approved icon is registered as an immutable reference but is not yet packaged as an app asset.
