# Phase 3B Final Fixes Report

- Date: 2026-07-21 (America/New_York)
- Branch: `codex/phase3b-primary-opponents`
- Base: `a096b4058f8badae1690880552e0d473c0f5ed74`
- Scope: One correctness/evidence fix wave for the final Phase 3B review
- Product boundary: No partner, opponent-life, rename, hide/restore, status, counter, Quick Restart, Settings-toggle, warning-banner, landscape, or iPad feature was added
- Approval state: Phase 3B manual approval and Functional Build Gate 3 remain pending

## Root-cause evidence

1. `AppStateStore.mutateAndPersist(onlyIf:)` returned `true` after any accepted in-memory mutation. It awaited `persistCurrentState()`, but that method returned no outcome. `addOpponent()` and primary-damage intents therefore converted “mutation happened” into an apparent success even when `repository.save` threw.
2. The exact-entry sheet used one constant accessibility identifier, `opponent-damage-exact-entry`, for every opponent. The rejection branch also mapped every failed store result to `Opponent is no longer in this game.`, even when the opponent still existed and arithmetic or persistence was the actual issue.
3. Opponent repeat mutation and haptic gating were private closures inside `OpponentCard`. Existing tests proved `RepeatActionDriver` timing and store mutations separately, but did not execute the production opponent repeat-to-store-to-haptic path.
4. The add UI test asserted `Opponent 4` before termination but not after relaunch. The store test checked count/name but did not compare the persisted snapshot’s complete opponent ID order or appended value.

## TDD RED

Tests were changed before production code. The focused RED command was:

```text
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -quiet \
  -project LifeGrid.xcodeproj -scheme LifeGrid \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -only-testing:LifeGridTests/AppStateStoreTests \
  -only-testing:LifeGridTests/CommanderDamageChangeTests \
  -only-testing:LifeGridTests/OpponentDamageInteractionTests \
  -resultBundlePath /tmp/phase3b-final-red.9UYJ4u/result.xcresult
```

Expected RED output:

```text
Cannot find 'OpponentMutationResult' in scope
Type 'OpponentCard' has no member 'exactDamageEntryIdentifier'
Type 'OpponentCard' has no member 'exactDamageRejectionMessage'
Cannot find 'OpponentDamageInteractionController' in scope
** TEST FAILED **
```

This demonstrated the requested contracts and production interaction path were absent. An initial test-only compile typo (missing `Foundation` for UUID/Date) was corrected and the RED command rerun before production edits; the recorded RED above contains only missing intended production APIs.

## Minimal implementation

- Added `OpponentMutationResult<Value>` with `persisted`, `retainedInMemory`, and `rejected` cases.
- Made the private persistence pipeline return the actual save outcome. Existing boolean mutation callers continue to treat retained in-memory mutations as mutations, preserving Phase 3A local-life behavior.
- Updated only opponent add/damage intents to expose the persistence-aware result.
- Added a production-owned `OpponentDamageInteractionController` that uses the existing `RepeatActionDriver`, serializes real store intents, and plays one adjustment haptic only after an actual repeated mutation.
- Kept the opponent control appearance and accessibility labels unchanged through a private production button adapter.
- Made the exact-entry identifier `opponent-damage-exact-entry-<opponent UUID>`.
- Kept the genuine missing-opponent message. Arithmetic/no-op rejection now uses `Commander damage could not be updated.`; a save failure that retained the change uses `The change is kept for this session but could not be saved.`
- Extended add persistence evidence through the store snapshot and post-relaunch UI assertions.

## GREEN evidence

### Focused unit suites

The selected GREEN result bundle at `/tmp/phase3b-final-green.ilZQg3/result.xcresult` reports:

```text
Result: Passed
Passed: 44
Failed: 0
Skipped: 0
```

The production-path repeat tests prove:

- initial delay is 350 ms and interval is 120 ms;
- the initial mutation does not haptic;
- one actual repeat mutation records exactly one `.adjustment` haptic;
- repeated decrement at zero records no haptic and no persistence write;
- gesture cancellation prevents the pending repeat and a later hold can begin.

### UI diagnostic and recovery

The first selected UI attempt executed no tests because the simulator rejected the test runner as:

```text
Busy ("Application failed preflight checks")
```

Evidence showed the exact selected UDID was `Shutdown`, while the focused unit result already passed. No application code was changed. Recovery explicitly booted `F2492AA8-2640-4FD9-B9F3-D856A407F2F8`; `bootstatus -b` reached terminal `Finished`, and device listing reported `Booted`.

The existing `testFourTabsRemainAvailable` smoke test then passed 1/1. Only afterward, the selected affected UI tests passed 2/2:

- `testOpponentCardsAddDamageAndPersist`
- `testPrimaryDamageExactEntryLethalAndInvalidInput`

The first now proves `Opponent 4` exists after relaunch. The second retains the exact-entry sheet proof through the text field and `Set Commander Damage` navigation title while allowing the sheet identifier itself to be UUID-specific.

Full diagnostic detail is preserved in `reports/test-results/phase3b-final-fixes-focused-tests.md`.

## Final verification

### Complete suite

```text
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -quiet \
  -project LifeGrid.xcodeproj -scheme LifeGrid \
  -destination 'platform=iOS Simulator,id=F2492AA8-2640-4FD9-B9F3-D856A407F2F8' \
  -resultBundlePath reports/test-results/phase3b-tests.xcresult
```

Result: exit 0; 106 logical tests passed, 0 failed, 0 skipped; 120 device executions passed.

### iPhone build

```text
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild build -quiet \
  -project LifeGrid.xcodeproj -scheme LifeGrid \
  -destination 'platform=iOS Simulator,id=F2492AA8-2640-4FD9-B9F3-D856A407F2F8' \
  -resultBundlePath reports/test-results/phase3b-iphone-build.xcresult
```

Result: exit 0; status `succeeded`; 0 errors; 0 warnings.

### Protocol and integrity

```text
python3 protocol/validate.py gate architecture
```

Result: `PASS`, exit 0.

`jq empty protocol/requirements.json` and `git diff --check` passed. Approved-source SHA-256 values still match `docs/approved/SOURCE_INTEGRITY.md` for `PROTOCOL.md`, the product spec, approved PDF, and approved overview image.

## Files changed

- `LifeGrid/App/AppStateStore.swift`
- `LifeGrid/Features/Game/CommanderDamageChange.swift`
- `LifeGrid/Features/Game/OpponentCard.swift`
- `LifeGridTests/App/AppStateStoreTests.swift`
- `LifeGridTests/Features/Game/CommanderDamageChangeTests.swift`
- `LifeGridUITests/LifeGridUITests.swift`
- `protocol/requirements.json`
- `reports/test-results/phase3b-final-fixes-focused-tests.md`
- `reports/test-results/phase3b-tests.xcresult`
- `reports/test-results/phase3b-iphone-build.xcresult`
- `reports/test-results/phase3b-verification.md`
- `.superpowers/sdd/final-fixes-report.md`

No approval file, change request, approved layout, approved icon, or screenshot was modified. The existing screenshot SHA-256 remains `4723510e4926391bee9b4646c162f3b60ba1bfef2499189b979149b0392e19b1`; it was retained because successful-state appearance did not change.

## Evidence refreshes

- Replaced the final full-suite and iPhone-build result bundles.
- Added a durable RED/GREEN and simulator-recovery report.
- Updated `phase3b-verification.md` with the 106-test result, production-path repeat proof, save-failure contract, stable exact-sheet identity, snapshot order, and Opponent 4 relaunch proof.
- Updated affected `CMD-008`, `CMD-011`, `OPP-002`, `OPP-003`, `OPP-005`, `PST-002`, `PST-003`, `TEST-004`, `TEST-010`, and `TEST-012` requirement records.
- Retained the existing visual comparison and screenshot because no captured UI appearance changed.

## Self-review

- The persistence result is based on the specific repository save operation, not the presence of a snapshot attempt or absence of a global error.
- A failed save still retains the complete in-memory game, matching Section 24, and the next mutation/lifecycle save can retry the current state.
- Phase 3A local-life, Undo, tax, and their existing return contracts were not changed.
- Haptics are mutation feedback: a retained-in-memory repeat mutation still haptics once because the visible value changed; rejected/no-op repeats do not haptic.
- Add Opponent has no success toast or persisted-success wording; a rejected add causes no state change. Exact entry explicitly distinguishes persisted, retained-in-memory, and rejected outcomes.
- UUID-based exact-sheet identity is independent of mutable name and card order.
- No deferred product area or iPad claim was introduced.

## Concerns and remaining gates

- The simulator produced one recoverable preflight `Busy` failure and recurring nonblocking LLDB debugger-version diagnostics. Recovery and passing reruns are documented; no app defect was attributed to them.
- The save-failure message is exercised through production message selection and store failure tests; there is no UI-testing-only repository failure launch argument.
- Manual VoiceOver navigation remains unperformed, consistent with the preexisting Phase 3B limitation.
- iPad remains deferred under CR-002, `TARGETED_DEVICE_FAMILY` remains `1,2`, Phase 3B still requires explicit manual approval, and Functional Build Gate 3 remains pending.
