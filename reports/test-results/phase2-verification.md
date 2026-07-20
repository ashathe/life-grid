# Life Grid Phase 2 Verification

- Verification date: 2026-07-20
- Reviewed implementation tip: `b4efd5d` (`fix: retry persistence recovery before mutations`)
- UI-flow checkpoint: `37f91aa` (`test: verify New Game relaunch flows`)
- Xcode: 26.6 (17F113)
- Swift: 6.3.3
- Phase 2 manual approval: Pending

## Final Xcode evidence

All named bundles were regenerated after commit `b4efd5d`.

| Gate | Destination | Result | Evidence |
| --- | --- | --- | --- |
| Complete unit and UI tests | iPhone 17 Pro, iOS 26.5 Simulator | Passed | `phase2-tests.xcresult` |
| iPhone build | iPhone 17 Pro, iOS 26.5 Simulator | Passed | `phase2-iphone-build.xcresult` |
| iPad build | iPad Pro 13-inch (M5), iOS 26.5 Simulator | Passed | `phase2-ipad-build.xcresult` |

`xcresulttool get test-results summary` reports 54 logical test cases passed, 0 failed, and 0 skipped. This comprises 47 unit test cases and 7 UI test cases. Parameterized runs produce 68 device-level test executions.

## Commands

```text
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -quiet -project LifeGrid.xcodeproj -scheme LifeGrid -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' -derivedDataPath /tmp/life-grid-phase2-final-tests-b4efd5d -resultBundlePath reports/test-results/phase2-tests.xcresult

DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild build -quiet -project LifeGrid.xcodeproj -scheme LifeGrid -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' -derivedDataPath /tmp/life-grid-phase2-final-iphone-b4efd5d -resultBundlePath reports/test-results/phase2-iphone-build.xcresult

DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild build -quiet -project LifeGrid.xcodeproj -scheme LifeGrid -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5),OS=26.5' -derivedDataPath /tmp/life-grid-phase2-final-ipad-b4efd5d -resultBundlePath reports/test-results/phase2-ipad-build.xcresult

python3 -m unittest discover -s protocol/tests -v
python3 protocol/validate.py gate architecture
python3 -m json.tool protocol/requirements.json
python3 -m json.tool protocol/visual-references.json
git diff --check
```

The protocol suite passed 7 tests and the architecture gate returned `PASS` before evidence authoring. JSON parsing and whitespace validation also passed. Final post-authoring validation is recorded by the evidence commit's verification run.

## Acceptance evidence

- First launch creates a 3-player, 25-life game with Amanda and Chris, then an argument-free terminate/relaunch restores 25, 3, Amanda, and Chris.
- The exact UI-test reset argument deletes only `Application Support/Life Grid/life-grid-state.json`; the restoration launch has no reset argument.
- Invalid Custom life retains the draft, shows inline validation, and disables Start Game.
- Replacement Cancel preserves the active game and the pending draft; replacement confirmation creates the new game only after destructive confirmation.
- Changing Settings Default Starting Life to 25 leaves an active 40-life game unchanged and seeds the next New Game with 25.
- Version-1 JSON migrates to schema version 2 without losing state; unsupported or corrupt snapshots are not silently replaced.
- A failed initial load blocks lifecycle and mutation writes so unreadable or future-version state is not replaced with defaults.
- The next explicit mutation retries a transient failed load; it changes state only after recovery succeeds, then persists normally.
- Overlapping state mutations persist through a FIFO save chain, preventing an older snapshot from finishing after a newer intent.
- Four Game, Counters, Dice, and Settings tabs remain available on the Phase 2 shell.

## Screenshot evidence

- `phase2-new-game-iphone.png`
- `phase2-invalid-custom-life-iphone.png`
- `phase2-replacement-confirmation-iphone.png`
- `phase2-settings-default-life-iphone.png`
- `phase2-active-game-iphone.png`
- `phase2-new-game-ipad.png`

All iPhone screenshots are retained attachments from the final test bundle. The iPad screenshot was captured from the final iPad build.

## Open risks and deliberate limits

- Visual Gate 2 is not approved. The native icon tab bar, missing D20 header badge, larger accessible scale, and uncaptured appearance/app-scale variants remain open in `reviews/visuals/new-game/phase2-comparison.md`.
- On regular-width iPad, native SwiftUI `TabView` presents the four tabs at the top; the approved later iPad game reference shows a bottom shell. This needs a later explicit shell decision.
- `SET-001` is `in_progress`: only the user-approved Default Starting Life variance is implemented. The complete page-6 Settings screen remains Phase 6 work.
- Counters and Dice are neutral placeholders. Phase 3 gameplay controls have not started.
- Build Gate 3 and Phase 2 manual approval remain pending.
