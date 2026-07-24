# Phase 3A Local Life Visual Comparison

- Screen: Game - local-life slice
- Requirement IDs: `LIFE-001` through `LIFE-007`, `CMD-001`, `CMD-002`, and `CMD-003`
- Approved reference: `docs/approved/Life_Grid_Approved_Designs.pdf`, page 3 (`Game iPhone`)
- Implementation evidence: `reports/test-results/phase3a-game-iphone.png`
- Behavior evidence: `reports/test-results/phase3a-tests.xcresult`
- Implementation commit: `713c7001f099d437b58b7c0bc602e3f7f16051f5`
- Device: iPhone 17 Pro, iOS 26.5 Simulator
- Orientation: Portrait
- Capture: 1206 x 2622 pixels (402 x 874 points)
- Appearance: Dark app preference; the simulator system appearance was Light
- App scale: Balanced
- Dynamic Type setting: Simulator default; no override was set
- Reduce Motion setting: Off (`ReduceMotionEnabled = 0`)
- Review status: Phase 3A local-life slice ready for manual review; Visual Gate 2 is not claimed complete

## Direct iPhone portrait comparison

| Area | Approved Game iPhone reference | Phase 3A evidence | Assessment |
| --- | --- | --- | --- |
| Primary hierarchy | Local player card is the first Game content block. | The local player card is the only gameplay content block and appears first beneath the toolbar. | Matches the Phase 3A slice hierarchy. |
| Life controls | Full-width split decrement and increment regions surround a large centered total. | Full-width left and right regions surround a bold, monospaced `39` total. | Matches the approved interaction hierarchy with native SwiftUI sizing. |
| Helper text | A compact instruction line sits directly below the life row. | The card shows exactly `Tap ±1 · Hold to repeat · Tap life total to set`. | Placement and emphasis match; the implementation uses accessible default text sizing. |
| Commander tax | An attached divider and local tax row use `-2`, a centered value, and `+2`. | The same attached row appears with 44 x 44-point controls and value `0`. | Matches the approved local single-commander tax structure. |
| Card treatment | Rounded purple-black surface with subtle border over a near-black background. | Rounded elevated surface, restrained purple border, near-black field, white primary text, and muted secondary text. | Color roles and control-panel character are preserved. |
| Navigation chrome | Slim approved tab treatment and compact Game header/D20 badge. | Native iOS icon tab bar and a native `New Game` toolbar action; no D20 header badge. | Existing shell variance, still open for the visual gate and not reclassified by Phase 3A. |
| Later Game regions | Pinned counters, opponents, statuses, lethal treatment, and Out of Game are shown in the complete reference. | None are rendered in this slice. | Explicitly deferred; absence is not a claim that these regions are visually complete. |

## Exact helper text

The implementation source and rendered card use this exact product copy once:

`Tap ±1 · Hold to repeat · Tap life total to set`

## Card hierarchy and visual quality

- The saved local name or `You` fallback is the first card label, followed by the life control row, the helper line, a divider, and Commander Tax.
- The total is the dominant typographic element. The player name and Commander Tax label form the second level, while helper copy and control glyphs remain subordinate.
- The capture uses the approved dark palette even though the simulator system appearance is Light, confirming the default Dark preference is applied independently of system appearance.
- The 72-point-tall life row materially exceeds the 44-point minimum. The centered life-value button has an 88 x 72-point minimum, tax controls are 44 x 44 points, and the transient Undo button uses a 44-point minimum.
- Primary text remains high contrast against the card and field surfaces. Muted helper text is readable at the captured default Dynamic Type size without truncation.
- Native text styles, a two-line player-name allowance, vertical card growth, semantic accessibility labels/hints/values, and a nonanimated local-life interaction preserve Dynamic Type and Reduce Motion compatibility for this slice.

## Behavior-only states reviewed in the final result bundle

- Normal decrement and increment update the displayed and persisted value by one.
- Signed exact entry accepts `-7`; invalid `--` remains in the sheet with `Enter a whole-number life total.` and does not change life.
- The temporary Undo affordance appears after a direct manual operation and restores the preceding total.
- Commander Tax remains at zero when decremented, advances to two when incremented, does not change life, and does not create life Undo.
- The commander-disabled test fixture hides tax while leaving the three life controls available, proving the card respects the stored default preference boundary used by Phase 3A.

The single retained screenshot records the stable post-Undo state (`39`) from the passing relaunch flow. The negative-entry, transient-Undo, and tax-interaction states are behavioral evidence inside `phase3a-tests.xcresult`; no additional screenshots are claimed.

## Visible differences and classification

| Difference | Classification | Resolution |
| --- | --- | --- |
| Native status area, safe-area spacing, icon tab bar, and toolbar geometry differ from the embedded mockup. | V1 existing shell variance | Retain for manual visual-gate review; Phase 3A does not redesign the approved shell. |
| The approved D20 header badge and compact Game title/subtitle are absent. | V1 existing shell variance | Remains open for a later approved visual-shell slice. |
| Typography and controls are larger than the embedded presentation mockup. | V1 accessibility-driven variance | Retain minimum touch targets and native text styles; manual review is required. |
| The local card has no Monarch badge or overflow menu. | Deferred product scope | Player statuses and local-card menu behavior are outside Phase 3A. |
| Pinned counters, Add Opponent, opponent cards, lethal state, and Out of Game are absent. | Deferred product scope | Counters, opponents, statuses, warnings, and out-of-game behavior remain deferred and are not visually claimed complete. |
| No iPad or landscape comparison is included. | Approved delivery variance | iPad implementation and verification are deferred under `changes/CR-002-iphone-primary-delivery.md`; the historical `game-ipad` reference remains registered. |

## Reviewer decision

Automated behavior and iPhone build evidence pass for the Phase 3A local-life slice. Manual user approval of this evidence is required before any later Phase 3 slice. This report does not approve Visual Gate 2, the native shell variances, or any deferred Game region.
