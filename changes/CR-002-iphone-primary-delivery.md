# CR-002 - iPhone-primary delivery with deferred iPad verification

- Status: approved
- Requested by: User
- Request date: 2026-07-21
- Approval date: 2026-07-21
- Approved by: User
- Implementation commit: Pending Phase 3 plan update

## Requested change

Keep Life Grid's current universal target and adaptive iPad fallback intact, but make iPhone the only active delivery target. Do not spend implementation, visual-review, screenshot, UI-test, or build-verification effort on iPad until the user explicitly restores that scope.

## Reason

Life Grid is intended for the user and close friends, who are expected to use the iPhone app. The user does not expect to use the iPad app and wants development attention concentrated on iPhone.

## Affected requirement IDs

- APP-004
- VIS-003
- TEST-004

## Affected specification sections

- Product Spec: Platform and responsive layout statements
- Implementation Prompt: Phase 6 responsive UI statements

## Affected approved layouts

- All iPad adaptive layouts and iPad visual-reference variants

## Before evidence

The app target supports iPhone and iPad. Phase 1 and Phase 2 plans required iPad builds and evidence, and `reports/test-results/phase2-new-game-ipad.png` captures the current adaptive fallback.

## Proposed after state

- Keep `TARGETED_DEVICE_FAMILY = "1,2"`; iPad installation is not removed.
- Design, implement, test, build, and visually review new work for iPhone only.
- Do not add iPad-specific layouts, screenshots, accessibility checks, UI tests, or build gates.
- Treat the existing iPad rendering as an unverified best-effort fallback, not a regression guarantee.
- Retain existing iPad artifacts as historical evidence only.

## Risks and side effects

- Future iPhone-focused SwiftUI changes can degrade the iPad fallback without being detected.
- The app remains installable on iPad but does not promise iPad-specific fidelity, testing, or support.
- Reintroducing iPad delivery requirements requires a later explicit change approval.

## Test impact

- Future phase acceptance commands run on an approved iPhone simulator only.
- Existing iPad evidence is not regenerated or used as a gate.

## Documentation updates

- Add this record to the authority stack for pending work.
- State the iPhone-only delivery boundary in the Phase 3 design and implementation plan.
- Keep prior approved source copies unchanged; this record supersedes their iPad-delivery scope only for future work.

## Explicit approval statement

APPROVED by the user on 2026-07-21 during Phase 3 scope review.

## Completion evidence

Pending Phase 3 design and plan update.
