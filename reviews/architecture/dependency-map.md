# Life Grid Dependency Map

## Runtime flow

```text
LifeGridApp -> AppEnvironment.live() -> AppStateStore
AppStateStore -> AppStateRepository -> JSONAppStateRepository -> Application Support JSON
AppEnvironment -> RandomSource | ClockClient | HapticsClient | SoundClient
SwiftUI feature boundary -> named feature intent -> AppStateStore -> persisted snapshot
```

`LifeGrid/App/LifeGridApp.swift` creates one store and triggers its load from the compile-only root task. `LifeGrid/App/AppEnvironment.swift` is the production composition root. Runtime dependencies point inward to protocols or value models; models do not import SwiftUI, persistence, or app composition.

## Isolation

- `AppStateStore`: `@MainActor`, observable, owns published application state.
- `JSONAppStateRepository`: actor, serializes file access.
- Repository and service protocols: `Sendable`.
- Persisted models and pure layout tokens: value types conforming to `Sendable`.
- Test recording/scripted dependencies: actors where mutation is recorded.

## Test substitution

`LifeGridTests/Support/TestDoubles.swift` supplies a scripted repository, scripted random source, fixed clock, and recording feedback clients. Store tests therefore exercise load, save, failure retention, and retry without disk or hardware. Repository tests independently use unique temporary directories to exercise real JSON I/O.

## Deferred feature boundary

The `Features/` responsibility is planned but intentionally absent before Gate 1 approval. Future views will observe `AppStateStore` and send named intents. They must not call the repository, random source, clock, or feedback clients directly.
