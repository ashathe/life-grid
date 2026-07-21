# Codex Implementation Prompt — Life Grid

Build a production-quality native SwiftUI application named **Life Grid** for iPhone and iPad.

The authoritative requirements are in `Life_Grid_Product_Spec.md`. Read that entire file before writing code. Do not substitute generic life-counter behavior for the approved rules.

## Non-negotiable constraints

- Track only the local user’s life.
- Never display or track opponent life totals.
- Support one local user plus up to five opponents.
- Local storage only; no network, iCloud, CloudKit, login, or analytics.
- SwiftUI native app.
- Dark default appearance with System and Light choices.
- App scale choices: Compact, Balanced, Large; Balanced default.
- Four tabs: Game, Counters, Dice, Settings.
- Auto-resume the exact active game after termination.
- Use the approved D20 Counter Ring icon reference without redesign.
- Initiative is not part of the app.

## Technical direction

1. Use a versioned Codable root application-state snapshot.
2. Persist atomically to Application Support after every meaningful change.
3. Keep domain rules outside SwiftUI view bodies.
4. Inject persistence, randomness, haptics, sound, and time for testing.
5. Use a central observable app-state store with intent methods.
6. Build accessibility in from the first implementation.
7. Preserve at least 44×44-point controls in every app-scale mode.
8. Respect Dynamic Type and Reduce Motion.
9. Add automated tests before claiming a feature complete.

## Required implementation order

### Phase 1 — Project foundation

- Create the Xcode project and folder structure.
- Add domain models and enums from the specification.
- Add the versioned persistence layer.
- Add a central observable store.
- Add deterministic test doubles.
- Add initial unit tests for persistence round trips and default state.

### Phase 2 — New Game and auto-resume

- Build the compact New Game screen.
- Support 2–6 total players.
- Add approved life presets and custom life.
- Support optional opponent names.
- Remember last setup.
- Resume active game directly on launch.
- Test replacement confirmation and relaunch restoration.

### Phase 3 — Game screen

- Build local player life card.
- Implement tap, hold-repeat, exact entry, negative life, haptics, and grouped temporary Undo.
- Add commander tax.
- Add opponent cards with primary and partner commander rows.
- Add opponent menus, rename, partner add/remove, hide, and Out of Game restore.
- Add Player Statuses with exclusive Monarch and independent City’s Blessing.
- Add linked commander-damage-to-life behavior.
- Add nonblocking red lethal warnings.

### Phase 4 — Counters

- Add all ten approved built-ins.
- Implement numeric and Day/Night behavior.
- Add maximum-four pinning.
- Add bottom-sheet pin picker.
- Add Edit Pins.
- Add persistent custom counters.
- Add swipe Rename/Delete and required confirmations.

### Phase 5 — Dice

- Add coin flip and built-in dice.
- Add saved custom dice from d2–d999.
- Add dice quantity 1–100.
- Show total plus individual results.
- Collapse after 20 with Show All.
- Persist the last five complete dice rolls.
- Add Random Starting Player and Random Opponent with brief shuffle animation and Reduce Motion handling.

### Phase 6 — Settings and responsive UI

- Add player-name settings.
- Add Commander, Own Partner Commander, damage-link, Keep Awake, haptics, and sound settings.
- Add Dark/System/Light.
- Add Compact/Balanced/Large with Balanced default.
- Add iPhone portrait and adaptive iPhone landscape/iPad layout.
- Add Reset Game and Quick Restart confirmation flows.

### Phase 7 — verification

- Run all unit and UI tests.
- Test forced termination and restoration.
- Test every appearance and scale combination.
- Test with 2 and 6 total players.
- Test VoiceOver labels and Reduce Motion.
- Compare every implemented behavior against the acceptance checklist in the product specification.
- Do not claim completion until verification succeeds.

## Output expectations

When implementation is complete, provide:

- A concise architecture summary.
- The file tree.
- A list of implemented features mapped to the specification.
- Test commands and test results.
- Any remaining limitations.
- Screenshots or previews of:
  - New Game.
  - Game with partner commander and statuses.
  - Counters and pin editing.
  - Dice with a multi-die custom roll.
  - Settings with appearance and app scale.
  - iPad adaptive layout.

Do not add features that were not approved merely because other life-counter apps include them.
