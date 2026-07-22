# Life Grid Phase 3B Verification

- Verification date: 2026-07-21 (America/New_York)
- Reviewed working tree: final-fix wave based on `a096b4058f8badae1690880552e0d473c0f5ed74`
- Xcode: 26.6 (17F113)
- Swift: 6.3.3
- Host: macOS 26.5.2 (25F84)
- Active delivery scope: iPhone portrait only under `changes/CR-002-iphone-primary-delivery.md`
- Manual approval: Required before any later Phase 3 subsystem

## Simulator discovery

The prescribed unprefixed command:

```text
xcrun simctl list devices available | rg -n 'iPhone'
```

could not locate `simctl` because the host's global developer directory is `/Library/Developer/CommandLineTools`. Repeating discovery with the same explicit Xcode selection used by the verification commands succeeded:

```text
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun simctl list devices available | rg -n 'iPhone'
```

Selected destination:

- Device: iPhone 17 Pro Simulator
- OS: iOS 26.5 (23F77)
- UDID: `F2492AA8-2640-4FD9-B9F3-D856A407F2F8`
- Destination: `platform=iOS Simulator,id=F2492AA8-2640-4FD9-B9F3-D856A407F2F8`
- Orientation: Portrait

No iPad test, build, launch, or screenshot command was run.

## Full-suite and build results

### Complete unit and UI suite

```text
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test \
  -project LifeGrid.xcodeproj -scheme LifeGrid \
  -destination 'platform=iOS Simulator,id=F2492AA8-2640-4FD9-B9F3-D856A407F2F8' \
  -resultBundlePath reports/test-results/phase3b-tests.xcresult
```

Outcome: `** TEST SUCCEEDED **`, exit status 0.

`xcresulttool get test-results summary` reports 106 logical tests passed, 0 failed, 0 skipped, and 0 expected failures. The console split is 91 Swift Testing tests plus 15 XCTest UI tests. The device summary records 120 passed executions because four parameterized tests expand into 18 runs.

### iPhone build

```text
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild build \
  -project LifeGrid.xcodeproj -scheme LifeGrid \
  -destination 'platform=iOS Simulator,id=F2492AA8-2640-4FD9-B9F3-D856A407F2F8' \
  -resultBundlePath reports/test-results/phase3b-iphone-build.xcresult
```

Outcome: `** BUILD SUCCEEDED **`, exit status 0.

`xcresulttool get build-results` reports status `succeeded`, error count 0, warning count 0, and the selected iPhone 17 Pro / iOS 26.5 destination.

The UI runner emitted the external simulator/tooling diagnostic that the LLDB debugger-version snapshot was unavailable. It did not correspond to an app test failure; every test completed and the aggregate command exited 0.

### Focused UI runner recovery

One pre-verification selected UI attempt was rejected before test execution because the simulator reported `Busy ("Application failed preflight checks")`. The exact UDID was then explicitly booted, `simctl bootstatus -b` reached terminal `Finished`, and `simctl list devices` confirmed `Booted`. The known existing `testFourTabsRemainAvailable` smoke test passed 1/1 before the two affected UI tests were rerun and passed 2/2. No app code changed for the simulator issue. The exact RED/GREEN and recovery record is `reports/test-results/phase3b-final-fixes-focused-tests.md`.

## Result-bundle integrity

The following commands read both completed result bundles successfully:

```text
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun xcresulttool get test-results summary --path reports/test-results/phase3b-tests.xcresult
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun xcresulttool get build-results --path reports/test-results/phase3b-iphone-build.xcresult
plutil -p reports/test-results/phase3b-tests.xcresult/Info.plist
plutil -p reports/test-results/phase3b-iphone-build.xcresult/Info.plist
```

Each `Info.plist` parses, declares `fileBacked2` storage, has a nonempty root hash, and records result-bundle version 3.58. The test summary result is `Passed`; the build summary status is `succeeded`. Neither bundle is treated as passing merely because its directory exists.

## Focused behavior and persistence evidence

| Area | Evidence | Result |
| --- | --- | --- |
| Fresh default game and list order | `testOpponentCardsAddDamageAndPersist`, `ActiveGameFactoryTests`, and the screenshot | Default Commander mode shows the local card first, then Opponents, with three stable default opponents in setup order and no opponent life. |
| Add through five | `addOpponentAppendsDefaultAndStopsAtFive`, `addOpponentReportsRetainedInMemoryWhenRepositorySaveFails`, and the UI flow | Add Opponent appends one visible zero-damage opponent with a stable UUID/default name, preserves prior IDs/order in the saved snapshot, reports durable save versus retained-in-memory failure, and stops mutating at five. |
| Tap, hold, exact value, and floor | `OpponentDamageInteractionTests`, `repeatStyleDamageChangesAtThresholdAndZeroOnlyPersistRealMutations`, `testOpponentCardsAddDamageAndPersist`, and `testPrimaryDamageExactEntryLethalAndInvalidInput` | The production repeat path mutates one point at a time on the approved schedule; exact whole-number entry works; decrement at zero and same-value exact entry are rejected no-ops; negative and overflowing inputs do not mutate. |
| Atomic linked life | `primaryDamageAtomicallyLinksLifeInBothDirections` and `exactPrimaryDamageEntryAppliesLinkedLifeDelta` | Damage and local life change in one persisted snapshot by the same opposite delta in both directions, including exact entry. |
| Link off | `primaryDamageDoesNotChangeLifeWhenLinkIsOff` | The stored disabled preference affects future damage only and does not rewrite prior life. No production Settings toggle is claimed. |
| Overflow safety | `primaryDamageOverflowDoesNotMutateOrPersist` and `linkedLifeOverflowDoesNotMutateOrPersist` | Damage arithmetic and linked-life arithmetic reject overflow without partial mutation or persistence. |
| Save-failure contract | `addOpponentReportsRetainedInMemoryWhenRepositorySaveFails` and `primaryDamageReportsRetainedInMemoryWhenRepositorySaveFails` | Failed opponent saves retain complete in-memory mutations and surface `retainedInMemory`; durable saves surface `persisted`; arithmetic, floor, missing-identity, and no-op rejection surface `rejected`. Phase 3A local-life result behavior is unchanged. |
| Opponent independence | `primaryDamageKeepsOpponentsIndependent` and stable-identity tests | Updates target a stable opponent UUID, preserve list order, and do not change another opponent. |
| Haptics and no Phase 3A Undo | `productionRepeatMutatesAndHapticsExactlyOnceAfterApprovedDelay`, `productionZeroFloorRepeatDoesNotHapticOrPersist`, and `productionGestureCancellationStopsRepeatAndAllowsNextHold` | The production opponent interaction controller uses `RepeatActionDriver`; an actual repeat mutation records one haptic, a zero-floor repeat records none, and cancellation remains tied to the approved timing path. Tap/hold damage changes do not create the direct-manual-life Undo path. |
| Persistence and relaunch | `testOpponentCardsAddDamageAndPersist`, repository tests, and state round trips | After Opponent 1 damage becomes 1 and linked life becomes 39, termination and relaunch restore both values and explicitly restore the added `Opponent 4`. |
| Exact-entry identity and feedback | `exactDamageIdentifiersAreStableAndUniquePerOpponent`, `exactDamageFeedbackSeparatesMissingOpponentFromOtherRejections`, and `testPrimaryDamageExactEntryLethalAndInvalidInput` | Each exact sheet identifier includes the stable opponent UUID. Invalid input retains the actual sheet through its text field/title; missing-opponent feedback remains specific, while arithmetic rejection and retained-in-memory save failure use accurate neutral feedback. |
| Commander disabled | `testCommanderDisabledFixtureHidesOpponentCardsWithoutBreakingLife` | The stored disabled test fixture hides the Opponents header, Add Opponent, and primary rows while keeping local life available; stored opponent state is not deleted. |
| Lethal primary damage | `testPrimaryDamageExactEntryLethalAndInvalidInput` and `CommanderDamageChangeTests` | Exact 21 displays `21, commander lethal`, uses the destructive color role, and updates linked life; the UI remains interactive. A later warning banner is not claimed. |

## Accessibility evidence

- Primary damage decrement, exact-value, and increment regions are 72 points high, exceeding the 44 x 44-point minimum.
- Buttons expose opponent-specific semantic labels and hints; the exact-value control exposes the current damage as an accessibility value.
- Exact-value sheet identifiers include the stable opponent UUID, preventing collisions between retained sheets for different cards.
- At 21+, the value becomes `21, commander lethal`, so lethal state is not communicated by red color alone.
- Opponent names permit two lines and retain their full semantic label. Native text styles and vertical card growth support Dynamic Type without a fixed card height.
- The retained default-Dynamic-Type screenshot shows no clipped text in the fully visible cards.
- No manual VoiceOver navigation session was performed; this report relies on source-level semantics and passing UI automation accessibility queries/values.

## Screenshot and visual review

- Screenshot: `reports/test-results/phase3b-game-iphone.png`
- Size: 1206 x 2622 pixels (402 x 874 points)
- Source attachment: `37DFA1CD-355F-4B29-B622-6FF240A88712.png` from `LifeGridUITests/testOpponentCardsAddDamageAndPersist()`
- Source device: iPhone 17 Pro, UDID `F2492AA8-2640-4FD9-B9F3-D856A407F2F8`
- SHA-256: `4723510e4926391bee9b4646c162f3b60ba1bfef2499189b979149b0392e19b1`
- Integrity: byte-for-byte `cmp -s` against the exported attachment passed
- Stable state: Opponent 1 primary damage `1`, linked local life `39`, and visible Add Opponent/list content
- Comparison: `reviews/visuals/game/phase3b-primary-opponents-comparison.md`
- Final-fix visual disposition: screenshot retained because successful-state appearance did not change; SHA-256 reverified.

Scoped visual result: PASS with V1 manual-review variances. The hierarchy, dark palette, card rhythm, contrast, 44-point-plus controls, and absence of opponent life are present. Native accessible typography, 72-point damage rows, and spacing make cards taller than the compact reference, while the existing native toolbar/tab shell still differs from the approved mockup. No visual parity is claimed for deferred regions.

## Requirement mapping

| Requirement | Verified Phase 3B scope |
| --- | --- |
| `CMD-003` | Existing verified default-on state is retained; the injected disabled preference also hides opponent commander UI without deleting state. The production Settings toggle remains deferred. |
| `CMD-007` | Stored default-on and injected link-off behavior apply only to future primary-damage changes. No Settings toggle is implemented. |
| `CMD-008` | Stable per-opponent primary damage supports independent tap/hold/exact updates, floor zero, atomic optional life linking, and a persistence-aware result that distinguishes durable save, retained-in-memory mutation, and rejection. |
| `CMD-010` | Primary 21+ state uses destructive color plus the semantic `commander lethal` value. Warning banners remain deferred. |
| `CMD-011` | Primary damage acceptance behavior covers delta linking, link-off, exact entry, no-op/floor, overflow rejection, save-failure retention, production-path repeat timing/cancellation, mutation-only repeat haptics, and no Phase 3A life Undo. |
| `OPP-001` | Commander-only visible opponent cards appear below the local card in stable setup order and contain no opponent life. |
| `OPP-002` | Add Opponent remains on Game, appends through five, uses a visible zeroed default, distinguishes durable save from retained-in-memory failure, restores `Opponent 4` after relaunch, and hides at maximum. Quick Restart synchronization remains deferred. |
| `OPP-003` | Opponents use UUID identity independent of mutable display names; primary damage and exact-sheet identifiers target stable identity, and saved snapshots preserve prior IDs/order before the appended opponent. Rename/hide/status/random consumers remain deferred. |
| `OPP-004` | Persisted New Game names and stable `Opponent N` defaults display with an accessible blank fallback. Rename UI is not implemented. |
| `OPP-005` | One primary commander row exposes direct tap/hold/exact controls, floor zero, linked life, lethal semantic/color treatment, persistence-aware results, and accurate missing/rejection/unsaved feedback. Partner/menu/status content is not implemented. |

`CMD-004` through `CMD-006`, `CMD-009`, and `OPP-006` through `OPP-013` remain unverified. Partners, primary commander naming, rename/menu actions, hide/restore, statuses, counters, Quick Restart integration, Settings toggles, opponent life, landscape, and iPad behavior were not added by Phase 3B.

iPad implementation and verification are deferred under `changes/CR-002-iphone-primary-delivery.md`; `TARGETED_DEVICE_FAMILY` remains `1,2`.

## Protocol and approval gate

The applicable incremental validator is:

```text
python3 protocol/validate.py gate architecture
```

Outcome: `PASS`, exit status 0.

The final app-wide `python3 protocol/validate.py gate build` is intentionally not used as the Phase 3B pass criterion. It remains pending because later requirements and the final build approval evidence are deliberately incomplete.

This Phase 3B evidence requires explicit manual approval. It does not authorize partners, statuses, counters, Quick Restart, Settings toggles, hide/restore, landscape, iPad, or any later Phase 3 subsystem.
