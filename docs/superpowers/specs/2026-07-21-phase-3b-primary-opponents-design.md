# Life Grid Phase 3B — Primary Opponent Cards Design

**Status:** User-approved design

**Scope:** The first end-to-end opponent gameplay slice for iPhone portrait: visible opponent cards, in-game Add Opponent, primary commander-damage controls, and the persisted commander-damage-to-life rule.

## Decision

Phase 3B uses the focused primary-opponent approach. It creates a usable Commander game loop before expanding into the independent partner, rename, hide/restore, status, counter, and warning systems.

The implementation will present existing visible opponents as cards directly below the existing local life card. It will permit adding opponents during an active game up to the five-opponent limit. Each card will control exactly that opponent's primary commander-damage total. Mutations persist through `AppStateStore`; when the saved `commanderDamageChangesLife` preference is enabled, the identical delta changes local life in the opposite direction as part of the same persisted game mutation.

## Authority and boundaries

This design implements the first coherent subset of Sections 9, 11.1, 11.3, and 12.1 of `docs/approved/Life_Grid_Product_Spec.md`, plus the iPhone Game reference. It follows `changes/CR-002-iphone-primary-delivery.md`: iPhone portrait is the only implementation, test, build, screenshot, and visual-review target. `TARGETED_DEVICE_FAMILY` remains `1,2`; no iPad-specific code, test, evidence, or support claim is added.

This slice does not add opponent life. The app never displays or stores opponent life totals.

## Included requirements

| Requirement | Phase 3B behavior |
| --- | --- |
| CMD-003 | Respect the stored commander-enabled preference: opponent commander UI is shown only while enabled, and disabling it does not delete opponent state. The Settings control remains deferred. |
| CMD-007 | Honor the stored default-on commander-damage-life-link preference for future damage mutations; no user-facing Settings toggle is added yet. |
| CMD-008 | Persist and control each visible opponent's primary commander damage independently. |
| CMD-010 | Treat a primary commander damage total of 21 or higher as commander lethal through red value styling. |
| CMD-011 | Support tap, hold-repeat, exact entry, minimum zero, and correct linked-life delta behavior for primary damage. |
| OPP-001 | Render the visible-opponent card list in the approved Game-screen order. |
| OPP-002 | Add a default visible opponent from the Game screen until five total opponents exist. |
| OPP-003 | Preserve each opponent's existing UUID and card ordering across mutations and relaunch. |
| OPP-004 | Display the saved/default opponent name; editing it is deferred. |
| OPP-005 | Render the primary commander row with direct controls and exact entry. |

## Explicitly deferred

- Opponent rename UI and primary-commander naming (CMD-004, OPP-008).
- Opponent partner add/remove, partner row, partner damage, and independent partner lethal behavior (CMD-006, CMD-009, OPP-006, OPP-009).
- Functional overflow-menu actions. A compact visual affordance may be omitted rather than present dead controls.
- Hide Player, Out of Game, restoring, Monarch transfer, and City’s Blessing behavior (OPP-010 through OPP-013).
- Status badges, warning banners beyond the 21+ damage value treatment, counters, Quick Restart setup updates, random-player tools, initiative, dice, and sound effects.
- User-facing Commander and commander-damage-link Settings controls.
- Landscape and all iPad-specific design, validation, or evidence.

## Game-screen composition

On iPhone portrait, the active Game scroll view is ordered as follows:

1. Existing local player life card.
2. A compact `Opponents` header.
3. An accented `Add Opponent` control when fewer than five opponents exist.
4. One card per visible opponent, in stored array order.

The section is rendered only when `preferences.commanderEnabled` is true. Opponent state remains persisted and untouched when it is false. Pinned counters and the Out of Game tray remain absent until their approved slices are implemented.

## Opponent identity and Add Opponent contract

1. The maximum is five total persisted opponents, not merely five visible cards. The Add control is absent at the limit.
2. Adding creates one `OpponentState` with a new UUID, `isVisible == true`, primary damage `0`, no primary commander name, no partner, and no City’s Blessing.
3. Its name is the first unused stable default in the `Opponent N` sequence. Existing custom names do not reserve a number; existing default labels do. This prevents a later addition from duplicating an existing default label after users add opponents mid-game.
4. The new value is appended to `ActiveGame.opponents`, preserving existing IDs and display order. It persists through the existing serialized persistence path and relaunch.
5. This slice changes only the active game. Quick Restart configuration is deliberately deferred until Quick Restart itself is implemented; no inactive setup representation is silently invented.

## Primary commander-damage contract

Each visible opponent card contains:

- the saved display name, falling back to a safe `Opponent` label only if a corrupted blank persisted value is encountered;
- the label `Commander Damage`;
- full-size − and + controls;
- a centered, tappable damage total; and
- no opponent life, partner, status, or inactive menu action.

Interaction matches the approved life-control mechanics where appropriate:

1. A tap changes primary commander damage by one.
2. A press applies the first change immediately. After 0.35 seconds, it repeats every 0.12 seconds until release. Repeat ticks use the existing haptic preference and light adjustment feedback; an initial tap does not haptic.
3. Damage is clamped at zero. A decrement at zero does not persist a no-op, does not modify life, and does not haptic.
4. Tapping the total opens a `Set Commander Damage` sheet seeded from the selected opponent's current total. It accepts a non-negative, representable whole number only. Empty, signed-negative, nonnumeric, and overflowing values retain the sheet and show accessible inline validation text.
5. A total of 21 or more uses the existing destructive/red color treatment while retaining a semantic accessibility value such as `21, commander lethal`.
6. Commander-damage interactions create no local-life Undo. They also do not overwrite, dismiss, or create a pending Phase 3A manual-life Undo.

## Linked-life persistence contract

`AppStateStore` remains the sole writer of `PersistedAppState`.

1. A primary-damage intent identifies one opponent UUID and receives a target value or delta.
2. The store locates that opponent in the active game, computes a valid non-negative target and signed `damageDelta`, then writes the updated damage into the same local `ActiveGame` value.
3. If `preferences.commanderDamageChangesLife` is true, local life changes by `-damageDelta` within the same mutation closure. Increasing damage therefore decreases life; decreasing damage restores life. With linking off, life is unchanged.
4. The store uses reporting-overflow checks for both damage and life arithmetic. An overflow produces no state or persistence write.
5. Exact entry uses the difference between target and old damage, so it follows precisely the same linked-life rule as repeated taps.
6. Changing the saved link preference later affects only subsequent intents; it never recalculates historical life. This slice honors that behavior but does not expose the Settings control.
7. Store intents return enough result information for the card to distinguish a persisted change from a floor/invalid/no-active-game no-op without exposing mutable state.

## Accessibility and appearance

- All direct controls retain at least 44 by 44 point targets and work with Dynamic Type through wrapping/vertical growth.
- Controls identify the opponent: for example, `Add one commander damage from Amanda`, `Remove one commander damage from Amanda`, and `Set Amanda's commander damage`.
- The exact-entry sheet has a unique accessibility identifier that includes the selected opponent ID or stable card identifier, avoiding ambiguity when several cards appear.
- The cards reuse the dark palette, rounded card hierarchy, border, monospaced numeric values, and accent language established by the approved Game screen. The first UI review will compare only the implemented local/opponent region against the iPhone reference and explicitly call all deferred regions incomplete.

## Validation and evidence

The implementation plan must add test-first coverage for:

- add-until-five behavior, stable IDs/order, deterministic default names, and relaunch persistence;
- primary damage ±1, zero floor, reporting-overflow safety, and exact non-negative entry;
- linked life increases/decreases and exact deltas, plus link-off behavior without retrospective rewriting;
- one opponent's primary damage never modifying another opponent;
- 21+ lethal display state and commander-disabled hiding with retained persisted data;
- repeat timing/cancellation and haptics only on actual repeat mutations;
- iPhone UI flows for add, primary damage, exact entry, lethal styling/accessibility, and persistence.

Final Phase 3B evidence will run the complete test suite and an iPhone simulator build, capture one iPhone Game screenshot, update only the evidenced requirement records, and state the CR-002 iPad deferral. The result is subject to the same visual review and manual user approval gate as Phase 3A before any later Phase 3 slice begins.
