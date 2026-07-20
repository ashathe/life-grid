# Phase 2 Settings Default-Life Variance

- Approved source: `docs/approved/Life_Grid_Approved_Designs.pdf`, page 6
- Approved change: `changes/CR-001-default-starting-life.md`
- Implementation evidence: `reports/test-results/phase2-settings-default-life-iphone.png`
- Review status: partial implementation; the full Settings visual reference remains `not_started`

## Approved Phase 2 addition

The user approved Settings as the owner of Default Starting Life. Phase 2 therefore adds one card with 20, 25, 30, 40, 60, and Custom choices. The selected value becomes the default for the next New Game and updates only the remembered setup's starting-life field. It never mutates an active game.

This control is an approved product variance because page 6 does not visibly contain a starting-life control. CR-001 records the correction and its precedence rules.

## Page 6 comparison

| Page 6 area | Phase 2 state |
| --- | --- |
| Player name | Not implemented; deferred to Phase 6. |
| Commander, Partner Commander, commander-damage life link, screen awake | Not implemented; deferred to Phase 6. |
| Appearance mode and app scale | Not implemented; deferred to Phase 6. |
| Haptics and sound | Not implemented; deferred to Phase 6. |
| Reset Game | Not implemented; deferred to Phase 6. |
| Default Starting Life | Implemented as the user-approved CR-001 addition. |

The implementation shares page 6's dark background, elevated card, purple selected state, and primary/secondary typography roles. It also inherits the native iOS 26 icon tab bar rather than the approved slim text-only bar.

## Traceability disposition

- `SET-001` remains `in_progress`; the approved defaults beyond starting life are not yet exposed by the Settings UI.
- The `settings` visual reference remains `not_started`; this variance report is not a substitute for the complete page-6 implementation or its device/appearance/scale review matrix.
- Visual Gate 2 and Phase 2 manual approval remain pending.
