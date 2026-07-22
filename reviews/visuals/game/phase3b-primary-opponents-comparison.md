# Phase 3B Primary Opponents — iPhone Visual Comparison

## Reference and scope

- Reference: `docs/approved/00_Approved_Designs_Overview.png`, Game iPhone panel.
- Target: iPhone 17 Pro Simulator, iOS 26.5 (23F77), portrait, 402 x 874 points.
- Implementation evidence: `reports/test-results/phase3b-game-iphone.png`.
- Behavior evidence: `reports/test-results/phase3b-tests.xcresult`.
- Reviewed implementation tip: `e6d862528652f31f9dd3bf02035613ec9c587146`.
- Appearance: Dark app preference; simulator default Dynamic Type and no appearance override.
- Deferred: partners, rename/menu actions, statuses, Out of Game, counters, warning banners other than 21+ damage color, landscape, and iPad.

## Comparison

| Area | Approved Game iPhone reference | Phase 3B evidence | Assessment |
| --- | --- | --- | --- |
| Local-card-to-Opponents hierarchy | Local life/tax card appears first, followed by pinned counters and the Opponents header/list. | The local life/tax card appears first and the Opponents header/list follows it. Pinned counters are not implemented, so no empty region is inserted. | Matches the implemented Phase 3B ordering while counters remain explicitly deferred. |
| Opponents header and Add Opponent | A compact Opponents header places Add Opponent at the trailing edge. | The header uses the same relationship and a prominent purple trailing Add Opponent button. | Preserves placement and emphasis. |
| Opponent card rhythm | Compact stacked cards separate opponent identity, commander label, value, and controls. | Rounded cards repeat at 12-point section spacing with a name, muted `Commander Damage` label, and a single split control row. | The rhythm and information hierarchy match, but native typography and accessible control sizing make each card materially taller than the embedded mockup. |
| Dark palette | Near-black background, purple-black surfaces, subtle borders, white primary text, and muted secondary text. | The capture uses the same color roles, with a purple action and restrained purple borders. | Matches the approved palette intent with native SwiftUI rendering. |
| Typography and contrast | Opponent names and damage totals are dominant; labels and controls are subordinate but readable. | Names are high-contrast headlines, damage totals are large bold monospaced digits, and the commander label is muted without becoming illegible. | Preserves hierarchy and contrast at default Dynamic Type. |
| Touch targets | Direct damage controls must remain usable and accessible. | Each decrement, exact-value, and increment region is 72 points high and exceeds the 44 x 44-point minimum. | Passes the scoped touch-target review. |
| Lethal treatment | A commander value at 21+ uses the approved red lethal role. | The screenshot intentionally records a stable value of `1`; the passing exact-entry UI flow separately verifies `21, commander lethal`, and source applies the destructive red value at 21+. | Behavior and semantic treatment pass; no banner or deferred warning UI is claimed. |
| No opposing-player life total | Cards for opposing players must not show or track life. | Cards expose only opponent name and primary commander damage. The UI test explicitly queries for and rejects `Opponent 1 life`. | Matches the approved product boundary. |

The retained screenshot came from the passing `testOpponentCardsAddDamageAndPersist` flow after a fresh default Commander game, one primary-damage increment for Opponent 1, linked local life moving from 40 to 39, and one Add Opponent action. The same flow then terminated and relaunched the app and verified that the primary damage and linked life were restored.

The approved embedded mockup fits more gameplay content in one viewport. The implementation deliberately retains native text styles, readable labels, and 72-point interaction rows, so only Opponent 1 and Opponent 2 are fully visible in this capture and lower cards require scrolling. This is a V1 accessibility/density variance for manual review, not a claim of pixel parity.

Existing native-shell differences also remain visible: the app uses the native icon tab bar and `New Game` toolbar action rather than the compact mockup header/D20 badge. Phase 3B does not redesign or approve that shell.

## Result

**PASS for the scoped Phase 3B iPhone portrait primary-opponents slice, with V1 density and existing shell variances requiring manual review.** The screenshot is `reports/test-results/phase3b-game-iphone.png`. It demonstrates the implemented hierarchy, card rhythm, palette, contrast, accessible controls, and absence of opponent life. It does not claim visual parity for partners, rename/menu actions, statuses, Out of Game, counters, banners, landscape, iPad, or any later subsystem.
