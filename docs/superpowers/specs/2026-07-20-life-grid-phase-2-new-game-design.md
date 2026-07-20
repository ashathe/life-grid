# Life Grid Phase 2 New Game and Auto-Resume Design

**Status:** User-approved design

**Approval date:** 2026-07-20

**Scope:** Phase 2 - New Game, default starting life, replacement confirmation, and active-game restoration

## Authority

This design implements Phase 2 from `Life_Grid_Codex_Implementation_Prompt.md` under the Life Grid Design-Control Protocol. The product specification and approved visual references remain authoritative, with later explicit user corrections taking precedence.

During design review, the user explicitly clarified that Settings owns the default starting life. The supplied Settings reference does not visibly contain that control, so this approved correction authorizes a narrowly scoped **Default Starting Life** section in Phase 2. It does not authorize the other Phase 6 Settings features.

The authority order is:

1. Later explicit user corrections and approved change requests.
2. `Life_Grid_Product_Spec.md`.
3. Approved visual layouts and `Life_Grid_Approved_Designs.pdf`.
4. `Life_Grid_Codex_Implementation_Prompt.md`.
5. Native SwiftUI conventions where approved materials are silent.

## Phase 2 Outcome

Phase 2 replaces the compile-only root with the four-tab application shell and implements the compact New Game flow. A first launch with no active game shows New Game. Starting a game saves a complete `ActiveGame`, and relaunch routes directly to a deliberately neutral active-game screen that proves restoration without implementing Phase 3 gameplay controls.

The phase also implements the approved replacement confirmation, the remembered-setup behavior, and the user-directed default-starting-life control in Settings.

Phase 2 stops at its manual approval boundary. Passing automated tests, builds, or visual checks does not constitute user approval.

## Approved Screen Boundary

The root contains exactly four tabs in this order:

1. Game.
2. Counters.
3. Dice.
4. Settings.

Their Phase 2 behavior is:

- **Game:** shows New Game when no active game exists. With an active game, it shows a neutral restoration screen and exposes New Game from the toolbar.
- **Counters:** neutral labeled placeholder; no counter behavior is implemented.
- **Dice:** neutral labeled placeholder; no dice behavior is implemented.
- **Settings:** contains only Default Starting Life. Other approved Settings content remains deferred.

The neutral active-game screen displays the saved starting life, total player count, and player names so restoration can be verified. It does not include life adjustment, commander, status, opponent-management, pinned-counter, restart, or other Phase 3 and later controls.

## Technical Approach

The existing `AppStateStore` remains the sole owner of persisted application state. SwiftUI screens observe it and send feature intents; they do not mutate the persisted state directly.

Phase 2 adds focused feature units:

- A tab-shell view that selects the approved feature destinations.
- A New Game draft model that owns transient form editing and validation.
- A New Game screen that renders the approved compact layout.
- A neutral active-game screen for launch restoration and New Game access.
- A replacement-confirmation presentation that does not mutate state until confirmation.
- A narrow Settings starting-life section that writes through the store.

The draft is transient. Opening, editing, or canceling New Game never changes the active game. Only a successful, confirmed start submits a validated setup to the store.

## New Game Inputs

### Total players

- The range is 2 through 6 total players.
- The total includes the local player.
- The form shows one opponent-name field for each non-local player.
- Reducing the count discards opponent drafts beyond the new count.
- Increasing the count creates blank fields; discarded names do not reappear.

### Starting life

The selector contains:

- 20.
- 25.
- 30.
- 40.
- 60.
- Custom.

Custom starting life accepts only a positive whole number representable by Swift's `Int`. Empty, nonnumeric, zero, negative, decimal, and overflow input is invalid. Invalid text remains in the field, an inline explanation appears, and Start Game is disabled. Selecting a preset preserves the typed custom draft for the current form session, but only the selected preset is submitted.

The Settings Default Starting Life control reuses this same selector and validation behavior.

### Opponent names

Opponent names are optional. Submission trims leading and trailing whitespace. A blank result becomes `Opponent 1`, `Opponent 2`, and so on, in visible order. Duplicate display names are allowed because opponent identity uses UUIDs rather than names.

### Remember last setup

Remember last setup defaults to on and is persisted independently of the active game.

- When on, successfully starting a game records the complete validated setup: total player count, starting life, and opponent names.
- When off, the game is still saved and auto-resumed, but the previously remembered setup is not changed.
- Changing the toggle alone does not erase the remembered setup.

## Form Initialization and Default-Life Precedence

When New Game opens:

1. If Remember last setup is on, use the persisted last setup.
2. Otherwise use four total players, blank opponent names, and the Settings default starting life.

Settings is the owner of the persistent default starting life. Changing it:

- Does not change an active game or any active player's life.
- Updates `AppPreferences.defaultStartingLife`.
- Updates only the persisted last setup's starting-life field while preserving its player count and opponent names.
- Causes the next New Game form to use the newly selected default life.

After that, a later successful game start with Remember last setup on may record a different starting life as part of the complete remembered setup.

## Starting and Replacing a Game

Start Game validates the entire draft before constructing a replacement.

With no active game:

1. Convert the valid draft into a `GameSetup`.
2. Construct the complete `ActiveGame` using stable player identities and approved initial values.
3. Update the remembered setup only when the toggle is on.
4. Persist the new state.
5. Route Game to the neutral active-game screen.

With an active game:

1. Keep the active game intact while the user edits the New Game draft.
2. On Start Game, present the approved replacement-confirmation pattern.
3. Cancel dismisses the confirmation and preserves both the active game and the edited draft.
4. Confirm validates and constructs the replacement before changing store state.
5. Replace the active game and apply remembered-setup behavior in one store mutation, then persist.

No partially constructed or invalid replacement becomes the active game.

## Persistence and Migration

Phase 2 advances the persisted snapshot to schema version 2. `AppPreferences` gains:

- `defaultStartingLife`, initially 40.
- `rememberLastSetup`, initially true.

The ordered version-1 to version-2 migration preserves the complete existing snapshot, including any active game and last setup, and adds the two defaults above. A migrated last setup remains intact. Unsupported future schema versions remain rejected rather than guessed at.

Every successful game creation, confirmed replacement, Settings default change, and Remember last setup preference change requests an immediate atomic save through the existing repository boundary.

On relaunch, a successfully loaded active game routes directly to the neutral active-game screen. Restoration tests compare the complete persisted domain state, not only the summary values visible on screen.

## Error Handling

- Draft validation is local and non-destructive. Invalid values retain the user's input and prevent submission.
- Replacement validation and construction complete before store mutation.
- A failed persistence write keeps the in-memory state available, records the persistence error through the existing store diagnostic, and shows a concise non-destructive save-error message. The next meaningful mutation or lifecycle save retries persistence.
- A failed or corrupt load uses the foundation's safe default in-memory state and records the load diagnostic; the app does not crash or silently pretend an active game was restored.
- Canceling New Game or replacement confirmation never changes persisted game state.

The save-error presentation is informational and accessible. It does not introduce a new settings workflow, destructive recovery action, or unapproved navigation destination.

## Visual and Accessibility Requirements

The New Game screen follows the approved New Game reference for hierarchy, dark-first semantic colors, card treatment, typography, compact spacing, controls, and bottom tab shell. The new Settings section follows the established Settings visual language while limiting its content to the approved Phase 2 slice.

The tab shell and placeholder screens must look intentional but neutral. The active-game restoration screen must not resemble a completed or approved Phase 3 Game screen.

All interactive controls retain at least 44-by-44-point targets. Controls use semantic accessibility labels, hints, traits, and values. Inline validation is exposed to assistive technology, and Dynamic Type may increase component height rather than truncate meaningful text. Keyboard type and submit behavior should support whole-number entry without making validation depend on the keyboard.

## Test Strategy

Executable behavior is implemented test-first. Automated coverage includes:

### Draft and validation

- Default initialization and remembered-setup initialization.
- Total-player boundaries and opponent-field resizing.
- All five numeric presets and Custom.
- Empty, nonnumeric, zero, negative, decimal, and overflow custom input.
- Preservation of an invalid or inactive custom draft during the form session.
- Name trimming, fallback names, and duplicate display names.

### Preferences and precedence

- Remember last setup defaults on.
- Successful start with remembering on updates the complete remembered setup.
- Successful start with remembering off preserves the previous remembered setup.
- Auto-save and resume remain active regardless of the Remember toggle.
- A Settings default change updates the preference and only the remembered setup's starting life.
- A Settings default change never mutates the active game.

### Game lifecycle

- First launch routes to New Game.
- Valid submission creates the complete approved initial game state.
- Canceling replacement preserves the active game and draft.
- Confirming replacement atomically creates the new game.
- Save/reload preserves exact domain equality and routes to the active-game screen.
- A failed save preserves usable in-memory state and exposes the diagnostic.

### Migration and integration

- Version-1 snapshots migrate to version 2 with complete active-game and last-setup preservation.
- Version-2 round trips are exact.
- Unsupported future versions are rejected.
- The app builds and launches on an available iPhone simulator and iPad simulator.
- UI tests cover first launch, valid New Game creation, invalid Custom input, replacement cancellation and confirmation, Settings default precedence, and relaunch restoration.

## Verification and Manual Approval

Before requesting Phase 2 approval:

1. Run focused unit and UI tests.
2. Run the complete test suite.
3. Build for available iPhone and iPad simulators.
4. Capture New Game and the narrow Settings slice on representative iPhone and iPad configurations.
5. Compare the implemented New Game screen to its approved visual reference and record evidence.
6. Verify the neutral active-game screen does not claim Phase 3 visual approval.
7. Record test, build, migration, and restoration evidence under the protocol report structure.
8. Present the reviewed commit and evidence to the user.
9. Stop for explicit manual approval.

## Approved Exclusions

Phase 2 does not implement:

- Life adjustment controls, gestures, undo, or event history.
- Commander damage, commander tax, partner commander, or lethal warnings.
- Opponent add/hide/restore, player menus, monarch, City's Blessing, or out-of-game behavior.
- Built-in or custom counters and pin editing.
- Dice, coin, history, or random-player tools.
- Quick Restart or Reset Game behavior.
- Settings other than Default Starting Life.
- Appearance, app scale, player name, gameplay, keep-awake, haptic, or sound settings.
- Final Phase 3 Game layouts for iPhone, landscape, or iPad.
- Networking, cloud storage, accounts, analytics, opponent life totals, Initiative, or any additional tab.

## Approved Decisions

The user explicitly approved:

- A neutral active-game screen for Phase 2 rather than a partial Phase 3 Game screen.
- The four-tab shell in Phase 2.
- Remember last setup defaulting on while auto-save remains unconditional.
- Positive-whole-number Custom life without an application-level gameplay cap beyond safe integer parsing.
- Optional names with stable fallback labels.
- Replacement confirmation before an active game is replaced.
- Settings as the owner of Default Starting Life.
- The 20, 25, 30, 40, 60, and Custom choices in both New Game and Settings.
- Updating only remembered starting life when the Settings default changes.
- Schema-version-2 migration, non-destructive error behavior, restoration testing, visual fidelity, and the Phase 2 manual approval boundary.
