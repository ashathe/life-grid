# Life Grid Persistence Plan

## Storage contract

`AppStateRepository` exposes async `load()` and `save(_:)` operations returning or accepting the complete `PersistedAppState`. The live `JSONAppStateRepository` stores `life-grid-state.json` inside an app-specific `Life Grid` Application Support directory.

## Load sequence

1. Resolve the snapshot URL.
2. If no file exists, return approved defaults.
3. Read the existing bytes without modifying them.
4. Decode the schema-version envelope.
5. Reject unsupported schemas without replacing or deleting the file.
6. Decode schema version 1 as the complete persisted state.

Corrupt JSON throws its decoding error and remains on disk. `AppStateStore.load()` retains its current in-memory state and records a diagnostic string rather than terminating the app (PST-002, PST-005).

## Save sequence

1. Reject a snapshot whose version is not current.
2. Create the Application Support directory on demand.
3. Encode with ISO-8601 dates and stable sorted JSON keys.
4. Write with `Data.WritingOptions.atomic`, so the active path is replaced only after a complete temporary write.

Every meaningful store mutation requests a save immediately. A failure does not roll back in-memory state; the next mutation saves the new complete snapshot and naturally retries persistence.

## Migration strategy

`StateMigration` is the only schema interpretation boundary. Version 1 is current and no older schema exists. When a future schema is introduced, ordered transformations must be added and tested here before the current model decoder runs. Unsupported future versions continue to fail closed without data replacement.

## Evidence

`LifeGridTests/Persistence/JSONAppStateRepositoryTests.swift` covers missing-file defaults, atomic save/reload, no leftover sibling temporary file, unsupported future schema preservation, and corrupt-file preservation. `LifeGridTests/App/AppStateStoreTests.swift` covers load publication, immediate saving, in-memory retention on failure, diagnostics, and next-mutation retry.
