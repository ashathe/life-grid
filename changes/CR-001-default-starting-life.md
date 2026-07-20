# CR-001 - Default Starting Life in Settings

- Status: approved
- Requested by: User
- Request date: 2026-07-20
- Approval date: 2026-07-20
- Approved by: User
- Implementation commit: Pending Phase 2 implementation

## Requested change

Settings owns Default Starting Life. The control uses 20, 25, 30, 40, 60, and Custom. Changing it updates only the remembered setup's starting-life field and never mutates an active game.

## Reason

The user explicitly corrected the supplied Settings reference during Phase 2 design review and approved this behavior and its precedence over remembered setup data.

## Affected requirement IDs

- SET-001
- NEW-002
- NEW-005

## Affected specification sections

- Section 7 - Default settings
- Section 8 - New Game

## Affected approved layouts

- Settings, approved PDF page 6
- New Game, approved PDF page 2

## Before evidence

The supplied Settings page does not visibly contain a starting-life control. The product specification identifies 40 as the initial starting-life default but does not define this Settings placement.

## Proposed after state

Phase 2 adds one Default Starting Life card to Settings using the New Game choices and validation. All other Settings work remains deferred to Phase 6.

## Risks and side effects

- The Settings implementation will visibly differ from the supplied page until the complete Settings phase is implemented.
- Incorrect precedence could mutate an active game or discard remembered names and player count.

## Test impact

- Test the 40-life default and all approved choices.
- Test custom positive-whole-number validation.
- Test that changing the default updates only remembered starting life.
- Test that an active game remains exactly unchanged.

## Documentation updates

- Phase 2 design and implementation plan record the correction.
- Phase 2 Settings visual evidence must cite this change record.

## Explicit approval statement

APPROVED by the user on 2026-07-20 during Phase 2 design review.

## Completion evidence

Pending Phase 2 implementation.
