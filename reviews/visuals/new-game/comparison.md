# Phase 2 New Game Visual Comparison

- Approved source: `docs/approved/Life_Grid_Approved_Designs.pdf`, page 2
- Implementation evidence: `reports/test-results/phase2-new-game-iphone.png`
- Behavior evidence: `reports/test-results/phase2-invalid-custom-life-iphone.png` and `reports/test-results/phase2-replacement-confirmation-iphone.png`
- Device: iPhone 17 Pro
- Orientation: Portrait
- Appearance: Dark
- App scale: Balanced
- Capture: iPhone 17 Pro, iOS 26.5 Simulator, portrait, 1206 x 2622 pixels (402 x 874 points)
- Review status: in review; Visual Gate 2 is not approved

## Alignment with the approved reference

| Area | Result | Evidence |
| --- | --- | --- |
| Information hierarchy | Matches | New Game header, total players, starting life, opponent names, remembered setup, and primary Start Game action appear in the approved order. |
| Cards and color roles | Matches closely | Near-black background, elevated purple-black cards, subtle purple borders, bright purple selection/CTA, white primary text, and muted secondary text are preserved. |
| Starting-life selected state | Matches | The 40 preset is visibly selected in purple; all six approved choices are present in a 3 x 2 grid. |
| Player-count controls | Matches functionally | Minus, count, and plus appear at the trailing edge and use minimum 44-point hit targets. |
| Opponent fields | Matches structure | Three fields appear for the four-player default; the evidence uses empty optional fields rather than the reference's sample names. |
| Remember toggle and CTA | Matches | The toggle is on by default and the full-width Start Game button follows it. |

## Measurable variances

The PDF page is a presentation layout containing an embedded mockup, not a device-pixel baseline. Exact pixel deltas against the PDF would be misleading. The implementation capture itself measures 402 x 874 points and the following visible variances are reproducible:

| Variance | Classification | Disposition |
| --- | --- | --- |
| The implementation uses the native iOS 26 icon tab bar; the approved mockup uses a slim, text-only four-segment bar. | Visual approval blocker | Requires an explicit design decision or later custom-shell implementation before Visual Gate 2 can pass. |
| The approved D20 badge at the upper-right of the content header is absent. | Visual approval blocker | Not required for Phase 2 behavior; retain as an open visual decision. |
| Typography, card padding, fields, and controls are materially larger than the embedded mockup. | Review variance | The implementation enforces 44-point controls and remains fully visible without scrolling on the captured device. Manual design approval is required. |
| The implementation includes the real iOS status area and safe-area spacing; the embedded mockup does not show equivalent native chrome. | Non-blocking platform variance | No action unless a custom full-screen shell is approved. |
| Dark/balanced portrait is the only reviewed New Game variant. Required light, system, compact, and large variants have not been captured. | Visual approval blocker | Do not infer or fabricate approval for missing variants. |

## Behavior-only states

- Invalid Custom life retains the entered `0`, shows `Enter a positive whole number.`, and leaves Start Game disabled.
- Starting a New Game while one is active presents the destructive replacement confirmation before mutation.
- These states are specification evidence; page 2 does not provide separate approved visual baselines for them.

## Gate conclusion

Phase 2 New Game behavior is implemented and verified, and the principal card hierarchy is faithful to page 2. Visual approval remains pending because the tab treatment, missing D20 badge, scale variance, and required uncaptured variants need manual review.
