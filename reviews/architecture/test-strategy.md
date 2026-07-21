# Life Grid Phase 1 Test Strategy

## Approach

Executable Swift and Python behavior is developed red-green-refactor. Tests are responsibility-oriented and run against deterministic dependencies. Static Xcode configuration and byte-identical approved artifacts are verified structurally.

## Current automated coverage

- `PersistedAppStateTests`: approved defaults, full schema-1 round trip, stable player identity, negative life, complete roll results, and absence of opponent life.
- `JSONAppStateRepositoryTests`: default load, atomic save/reload, unsupported schema preservation, and corrupt JSON preservation.
- `AppEnvironmentTests`: scripted random order, fixed time, and recording feedback events.
- `AppStateStoreTests`: load publication, default state, immediate save, save-failure retention, diagnostic clearing, and retry.
- `LayoutFoundationTests`: portrait/landscape/regular-width resolution, exact scale multipliers, and 44-point target floors.
- `FoundationSmokeTests`: unit target imports the app module.
- `LifeGridUITests`: compile-only app launch.
- `protocol/tests/test_validate.py`: hard-gate, approval, duplicate-ID, and evidence behavior.

## Gate verification plan

Before requesting Gate 1 approval, save fresh results for all Python tests, the full Swift unit target, the UI launch smoke, iPhone build, and iPad build. Record toolchain, simulator destinations, commands, pass counts, warnings, limitations, and current commit in `reports/test-results/phase1-verification.md`.

Gate 1 evidence must not be treated as manual approval. The architecture validator must remain blocked only by the pending approval record after all other evidence and manifest paths are present.

## Later-phase coverage

The remaining TEST-005 through TEST-020 entries stay `not_started`. Each approved feature will add unit tests for its intent/domain rules and UI or accessibility tests where behavior cannot be proved below the view layer. Visual similarity requires the protocol’s separate screenshot comparison and approval workflow; unit tests do not approve visuals.
