# Life Grid
## Approved Product and Interaction Specification

**Status:** Final design approved  
**Platform:** Native iPhone and iPad app using SwiftUI  
**Storage:** Local device only  
**Working and final app name:** **Life Grid**  
**Approved icon:** **D20 Counter Ring — Option B** from the supplied concept sheet. Do not redesign or add new symbols.

---

## 1. Product definition

Life Grid is a personal Magic: The Gathering life and game-state tracker designed for one local user and up to five opponents.

The app tracks:

- The local user’s life total.
- Commander damage each opponent’s commander has dealt to the local user.
- The local user’s commander tax.
- Numeric counters and the Day/Night mechanic.
- Monarch and City’s Blessing player statuses.
- Dice, coin flips, and random-player selection.

The app **does not track opponents’ life totals**. Opponent cards exist only for commander damage, partner configuration, names, statuses, and in-game visibility.

The app must also work as a general MTG life counter when Commander mode is disabled.

---

## 2. Core navigation

Use a four-tab bottom navigation structure:

1. **Game**
2. **Counters**
3. **Dice**
4. **Settings**

The active game resumes exactly where it was left after app termination, relaunch, or a crash.

---

## 3. Visual direction

### 3.1 General style

- Polished, dark control-panel aesthetic.
- Purple is the primary accent.
- Rounded cards and surfaces.
- High contrast at all times.
- Avoid tiny text and low-contrast status labels.
- Red is reserved for:
  - Lethal warnings.
  - Destructive actions.
- Active status badges such as Monarch and City’s Blessing use:
  - A solid accent background.
  - High-contrast accent text.
  - No dark-on-dark combinations.

### 3.2 Appearance options

Settings → Appearance:

- **Dark** — default.
- **System**
- **Light**

Changing appearance must never affect game state.

### 3.3 App scale

Settings → Appearance → App Scale:

- **Compact**
- **Balanced** — default.
- **Large**

The selected scale persists locally.

Scale changes apply to the Game, Counters, and Dice interfaces. Preserve accessible touch targets even in Compact mode. Dynamic Type and VoiceOver must remain usable independently of the app-scale choice.

### 3.4 Responsive layout

- iPhone portrait: approved single-column vertical layout.
- iPhone landscape and iPad: adaptive two-column Game layout.
  - Left: local player life card and pinned counters.
  - Right: opponent commander-damage cards.
- Do not merely stretch the phone layout across a wide screen.

---

## 4. App icon

Use the supplied **Life_Grid_Selected_Icon_Reference.png** as the approved visual reference.

The selected concept is:

- D20 in the center.
- `20` displayed on the die.
- Segmented circular counter ring.
- Purple-to-warm-orange illuminated ring.
- Small heart at the bottom.
- Dark rounded-square background.

Do not add a heartbeat, plus/minus split, new wording, or another symbol. The concept is approved as-is.

For production, recreate it cleanly as an app-icon asset rather than shipping the entire concept sheet.

---

## 5. Persistence architecture

The app is local-only:

- No iCloud.
- No CloudKit.
- No account.
- No network dependency.
- No analytics requirement.

Recommended implementation:

- A single versioned `Codable` application-state snapshot.
- Persist atomically to the app’s Application Support directory.
- Autosave after every meaningful mutation.
- Use a schema-version field to support future migrations.
- Keep transient presentation state out of the persisted snapshot.

The persisted snapshot includes:

- Preferences.
- Last New Game setup.
- Current active game.
- Opponent configuration and visibility.
- Life and counter values.
- Commander damage and tax.
- Statuses.
- Pin choices.
- Custom counter definitions.
- Saved custom dice.
- Last five dice-roll entries.
- Current Day/Night state.
- Temporary per-game screen-awake override.

---

## 6. State model

The following types are the required conceptual model. Exact filenames may differ, but behavior must match.

```swift
struct PersistedAppState: Codable {
    var schemaVersion: Int
    var preferences: AppPreferences
    var lastSetup: GameSetup
    var activeGame: ActiveGame?
    var customCounters: [CustomCounterDefinition]
    var savedDice: [SavedDieDefinition]
    var diceHistory: [DiceRollEntry]
}

struct AppPreferences: Codable {
    var playerName: String
    var commanderEnabled: Bool
    var ownPartnerCommanderEnabled: Bool
    var commanderDamageChangesLife: Bool
    var keepScreenAwakeDuringGames: Bool
    var hapticsEnabled: Bool
    var soundEffectsEnabled: Bool
    var appearance: AppearanceMode
    var appScale: AppScale
}

enum AppearanceMode: String, Codable {
    case dark
    case system
    case light
}

enum AppScale: String, Codable {
    case compact
    case balanced
    case large
}

struct GameSetup: Codable {
    var totalPlayers: Int
    var startingLife: Int
    var opponentNames: [String]
}

struct ActiveGame: Codable {
    var id: UUID
    var startedAt: Date
    var startingLife: Int
    var currentLife: Int

    var opponents: [OpponentState]

    var ownCommanderAName: String?
    var ownCommanderBName: String?
    var ownCommanderTaxA: Int
    var ownCommanderTaxB: Int

    var currentMonarchPlayerID: PlayerID?
    var playerHasCitysBlessing: Bool

    var counterValues: [CounterID: Int]
    var dayNightState: DayNightState
    var pinnedCounterIDs: [CounterID]

    var keepAwakeOverride: Bool?
}

struct OpponentState: Codable, Identifiable {
    var id: UUID
    var displayName: String
    var isVisible: Bool

    var primaryCommanderName: String?
    var primaryCommanderDamage: Int

    var partner: PartnerCommanderState?

    var hasCitysBlessing: Bool
}

struct PartnerCommanderState: Codable {
    var name: String?
    var damage: Int
}

enum DayNightState: String, Codable {
    case notSet
    case day
    case night
}

struct CustomCounterDefinition: Codable, Identifiable {
    var id: UUID
    var name: String
    var createdAt: Date
}

struct SavedDieDefinition: Codable, Identifiable {
    var id: UUID
    var sides: Int
}

struct DiceRollEntry: Codable, Identifiable {
    var id: UUID
    var timestamp: Date
    var sides: Int
    var diceCount: Int
    var individualResults: [Int]
    var total: Int
}
```

`PlayerID` should represent either the local player or one opponent without relying on a fragile display-name lookup.

---

## 7. Default settings

First launch defaults:

- Player name: blank, displayed as **You** until changed.
- Commander: enabled.
- Own Partner Commander: disabled.
- Commander damage changes life: enabled.
- Keep screen awake during games: enabled.
- Haptics: enabled.
- Sound effects: disabled.
- Appearance: Dark.
- App scale: Balanced.
- Starting life: 40.
- Total players: 4 unless the implementation needs a safer neutral first-launch default.
- Day/Night: Not Set.
- All numeric counters: 0.
- Commander tax: 0.
- No Monarch.
- No City’s Blessing.

---

## 8. New Game

Use one compact New Game screen.

### 8.1 Inputs

- Total players: 2–6.
- Starting life presets:
  - 20
  - 25
  - 30
  - 40
  - 60
  - Custom
- Optional opponent names.
- Remember last setup.

### 8.2 Player creation

Total players includes the local user.

Examples:

- 2 players = user + 1 opponent.
- 6 players = user + 5 opponents.

Unnamed opponents use:

- Opponent 1
- Opponent 2
- Opponent 3
- Opponent 4
- Opponent 5

### 8.3 Starting a new game while one exists

Show a confirmation before replacing the current active game.

Autosaved state means there is no separate save step.

---

## 9. Game screen

Order on iPhone portrait:

1. Local player life card.
2. Pinned counters.
3. Opponents header with **Add Opponent**.
4. Visible opponent cards.
5. Out of Game tray, when nonempty.

**Add Opponent remains on the Game screen.** A previous idea to move it into Settings was explicitly retracted.

### 9.1 Add Opponent

- Available until five opponents exist.
- Adds one visible opponent with:
  - Default name `Opponent N`.
  - Primary commander damage 0.
  - No partner.
  - No statuses.
- Hide the button at the five-opponent maximum.
- Adding an opponent updates the active setup used by Quick Restart.

---

## 10. Local player card

### 10.1 Name

The local player name is editable from:

- Settings.
- The local player-card menu.

The saved name persists between games.

Blank name displays **You**.

### 10.2 Life controls

Use split controls:

- Entire left half: −1.
- Entire right half: +1.
- Large centered life total.

Interaction:

- Tap left/right: change by one.
- Hold left/right: repeatedly change one point at a time.
- Light haptic tick for each repeated increment when haptics are enabled.
- Tap the life value: open exact-value entry.
- Life may go below zero.

Clean helper text:

**Tap ±1 · Hold to repeat · Tap life total to set**

Do not use a long explanatory paragraph.

### 10.3 Life undo

Provide a temporary one-level Undo for direct manual life changes.

Rules:

- A held adjustment is grouped as one undoable change.
- Exact value entry is one undoable change.
- A new manual life operation replaces the previous pending undo.
- The Undo affordance disappears after a short period, recommended four seconds.
- Commander-damage-linked life changes do not create a special life Undo.

### 10.4 Commander tax

Commander tax is attached directly to the local player card.

It is never a general pinnable counter.

Without own Partner Commander enabled:

- Show one Commander Tax row.
- Controls are −2 and +2.
- Minimum 0.

With own Partner Commander enabled:

- Show A/B selection.
- Optional independent name for each commander.
- Independent tax for A and B.
- Controls remain −2 and +2.
- Minimum 0.

Turning Partner Commander off hides B without deleting its saved name or tax.

---

## 11. Commander settings

Settings → Gameplay:

### 11.1 Commander

Default: enabled.

When enabled:

- Show local commander-tax controls.
- Show opponent commander-damage cards.
- Reveal Own Partner Commander setting.
- Reveal Commander Damage Changes Life setting.

When disabled:

- Hide all commander-related UI.
- Preserve names, partner configuration, damage values, and taxes.
- Continue functioning as a general MTG life counter.

### 11.2 Own Partner Commander

Default: disabled.

This setting affects only the local player’s own A/B commander-tax section.

It does **not** globally disable opponent partner rows.

Each opponent may independently add or remove a partner from that opponent’s menu.

### 11.3 Commander damage changes life

Default: enabled.

This toggle affects only future changes.

Never rewrite prior history when the toggle changes.

When enabled:

- Increasing an opponent commander-damage total by `N` decreases local life by `N`.
- Decreasing commander damage by `N` restores local life by `N`.
- Exact entry adjusts local life by the difference between old and new damage.
- Primary and partner commander damage behave independently.

When disabled:

- Commander damage changes do not affect life.

---

## 12. Opponent cards

Only visible opponents are shown in the main list.

Every card shows:

- Editable opponent name.
- Primary commander row.
- Primary commander damage total.
- Direct − and + controls.
- Tap damage value for exact entry.
- Optional partner row.
- Active status badges.
- Overflow menu.

Do not display or track opponent life.

### 12.1 Commander damage controls

Interaction:

- Tap ±1.
- Hold to repeat.
- Tap value to set exact value.
- Minimum 0.

Helper behavior is the same as numeric counters, but avoid repeating instructional copy on every card.

### 12.2 Partner row

Opponent menu contains Add Partner or Remove Partner.

When present:

- Show a second compact commander-damage row.
- Default blank label displays **Partner**.
- Optional partner name.
- Independent commander-damage total.
- Independent lethal threshold.

Removing a partner:

- If the partner has a nonblank name or nonzero damage, confirm.
- Confirmed removal clears the partner name and damage.
- If both are empty/zero, remove without an unnecessary warning.

### 12.3 Opponent menu

Required actions:

- Player Statuses
- Rename Player
- Add Partner / Remove Partner
- Hide Player

---

## 13. Hide Player and Out of Game

Hiding a player normally means that player is dead or out of the game.

### 13.1 On hide

- Remove the card from the visible opponent list.
- Preserve:
  - Player identity.
  - Name.
  - Commander names.
  - Partner configuration.
  - Commander damage.
- Clear City’s Blessing.
- Exclude the player from all random-player tools.

### 13.2 Hiding the current Monarch

Before hiding the current Monarch, show a transfer sheet containing:

- Every other visible player, including the local player when applicable.
- Remove Monarch.
- Cancel.

The user must transfer or remove Monarch before the hide completes.

### 13.3 Out of Game tray

When hidden opponents exist, show a compact tray such as:

**Out of Game · 2 players**

Opening it lists hidden players and provides Restore.

Restoring:

- Makes the player visible again.
- Preserves commander damage and configuration.
- Does not restore statuses cleared at hide time.

### 13.4 Restart behavior

New Game and Quick Restart restore all configured players to visible.

---

## 14. Player statuses

Every player card, including the local user, has a Player Statuses submenu.

Only active statuses appear as small badges on the closed card.

Required statuses:

- Monarch
- City’s Blessing

Initiative is explicitly excluded.

### 14.1 Monarch

- Exactly zero or one player may be Monarch.
- Assigning Monarch automatically removes it from the previous player.
- Turning Monarch off for the current holder leaves no Monarch.
- Badge must be high contrast.

### 14.2 City’s Blessing

- Multiple players may hold it independently.
- It persists until game reset while the player remains visible/in-game.
- Hiding a player clears that player’s City’s Blessing.

---

## 15. Counters

### 15.1 Built-in counter library

Required built-ins:

1. Poison
2. Energy
3. Experience
4. Treasure
5. Radiation
6. Storm
7. Charge
8. Doom
9. Tickets
10. Day/Night

Do not add Commander Tax, Monarch, City’s Blessing, Initiative, or Knockout to this library.

### 15.2 Numeric counter behavior

For all numeric counters:

- Tap ±1.
- Hold to repeat.
- Tap the value for exact entry.
- Minimum 0.
- Reset Game sets the current value to 0.
- Haptic ticks follow the Feedback setting.

### 15.3 Day/Night

Day/Night is the actual MTG mechanic.

State sequence:

- Initial state: Not Set.
- First tap from Not Set: Day.
- Later taps toggle Day ↔ Night.
- New Game and Quick Restart reset it to Not Set.

It may be pinned and consumes one pin slot.

### 15.4 Pinning

- Maximum four pinned counters.
- Any built-in or custom counter may be pinned.
- Poison is not fixed.
- Day/Night counts toward the four.
- At four pinned counters, hide the **+ Pin Counter** control.
- Unpinning immediately reveals it again.
- Pin picker is a bottom sheet.
- No search field is required.

### 15.5 Unpinning

Use **Edit Pins**.

While editing:

- Show removal controls on every pinned item.
- Unpinning removes it from the Game screen.
- The value remains in the Counters tab.

---

## 16. Custom counters

Custom counters are saved permanently and reusable across games.

### 16.1 Creation

- Create from the Counters tab or pin picker.
- Require a nonblank trimmed name.
- Prevent confusing case-insensitive duplicate names.
- Initial value is 0.

### 16.2 Management

Use swipe actions on saved custom counters:

- Rename.
- Delete.

Do not use a dedicated Settings management list.

### 16.3 Deletion

If the counter is pinned or has a nonzero value:

- Show a confirmation describing both consequences.

Confirmed deletion:

- Removes the pin.
- Deletes the saved definition.
- Deletes its active-game value.

Unpinning alone never deletes the custom counter.

---

## 17. Lethal warnings

Warnings are informative only.

Never lock the interface or automatically declare a player dead.

### 17.1 Thresholds

- Commander damage: 21 from one commander.
- Poison: 10.

Primary and partner commander damage are evaluated separately.

### 17.2 Presentation

Use approved option:

- Temporary nonblocking banner.
- Persistent badge.
- Persistent highlighted border or row treatment.

Use red with high-contrast white text.

### 17.3 Trigger rules

- Trigger the banner only when crossing from below threshold to at/above threshold.
- Keep the badge while still at/above threshold.
- Dropping below removes the persistent warning state.
- Crossing again triggers another banner.

---

## 18. Dice tab

Required tools:

- Coin flip.
- d4.
- d6.
- d8.
- d10.
- d12.
- d20.
- Saved custom dice.
- Random Starting Player.
- Random Opponent.

### 18.1 Saved custom dice

The user selected saved custom dice.

A saved die stores:

- Number of sides.
- Auto-generated display label `dN`.

Rules:

- Sides: 2–999.
- Avoid duplicate saved dice with the same number of sides.
- Allow deletion from the Dice tab.
- A custom die uses the same result and history behavior as built-in dice.

### 18.2 Number of dice

For every numeric die:

- Allow 1–100 dice per roll.
- Persist the last selected quantity for convenience.
- Default may be 1.

### 18.3 Result display

Approved display:

- Large total.
- Individual results below.
- For more than 20 dice:
  - Initially show the first 20 results.
  - Show **Show All**.
  - Show All reveals every result.

### 18.4 History

Keep the last five complete dice-roll entries across built-in and custom dice.

Each entry stores and displays:

- Dice notation, such as `3d37`.
- Total.
- Every individual die result.

History must retain all individual results even when the current result is collapsed to the first 20.

### 18.5 Coin flip

- Heads or Tails.
- Brief flip animation.
- Clear large result.
- Haptic and sound behavior follows settings.

### 18.6 Random Starting Player

Eligible:

- Local player.
- Every visible opponent.

Hidden/out-of-game opponents are excluded.

Display:

- Brief shuffle animation.
- One large selected name.
- Pick Again button.

### 18.7 Random Opponent

Eligible:

- Visible opponents only.
- Never the local player.
- Hidden/out-of-game opponents excluded.

If no eligible opponent exists:

- Disable the action.
- Explain that no visible opponent is available.

---

## 19. Feedback

Settings → Feedback:

### 19.1 Haptics

Default: on.

Use light haptics for:

- Life changes.
- Numeric counters.
- Commander damage.
- Commander tax.
- Dice and coin results.
- Status changes.
- Hold-repeat ticks.

Use a stronger warning haptic when a lethal threshold is crossed.

### 19.2 Sound

Default: off.

Separate toggle from haptics.

Optional subtle sounds:

- Dice result.
- Coin flip.
- Lethal warning.

Do not make sound required for understanding state.

---

## 20. Keep screen awake

Settings toggle:

**Keep screen awake during games**

Default: on.

Also provide a temporary override from the Game screen.

Rules:

- Apply only while an active game is open and the app is foregrounded.
- Restore normal idle-timer behavior outside an active game or when backgrounded.
- Persist the saved setting.
- Persist the temporary override only as part of the active game.

---

## 21. Reset and restart

Use the label **Reset Game**.

### 21.1 Quick Restart

Quick Restart uses the last active setup.

Show confirmation with:

- Cancel.
- Restart.
- Clear explanation of what resets and what remains.

### 21.2 Reset to defaults for the game

Reset:

- Local life to selected starting life.
- All numeric counter values to 0.
- Primary commander damage to 0.
- Partner commander damage to 0.
- Own commander tax A and B to 0.
- Day/Night to Not Set.
- Monarch to none.
- Every City’s Blessing to off.
- Every configured opponent to visible.

### 21.3 Preserve

Preserve:

- Local player name.
- Opponent names.
- Active player count and setup.
- Commander names.
- Partner configurations and names.
- Enabled/pinned counters.
- Custom counter definitions.
- Saved custom dice.
- App settings.
- Appearance and scale.
- Feedback preferences.

Do not delete preserved configuration when resetting.

### 21.4 Access

Recommended:

- Game toolbar overflow:
  - Quick Restart.
  - New Game.
  - Temporary Keep Awake override.
- Settings:
  - Reset Game.

Both restart actions use the approved confirmation language.

---

## 22. Auto-resume

After every meaningful change, persist state.

On launch:

- If an active game exists, open directly to that game.
- Restore:
  - Life.
  - Counters.
  - Day/Night.
  - Opponents.
  - Hidden players.
  - Names.
  - Partner rows.
  - Commander damage.
  - Commander tax.
  - Monarch.
  - City’s Blessing.
  - Pins.
  - Current tab if practical.
  - Last five dice rolls.
  - Per-game screen-awake override.

If no active game exists, show New Game.

---

## 23. Accessibility requirements

These are mandatory, not optional polish.

- VoiceOver labels for every adjustment button and value.
- Announce updated values.
- Do not communicate lethal status by color alone.
- Active badges use text plus color.
- Maintain at least 44×44-point interactive targets.
- Support Dynamic Type.
- Avoid truncating player names without an accessible full label.
- Respect Reduce Motion:
  - Replace shuffle and coin animations with immediate or crossfade results.
- Respect system contrast settings where possible.
- Use semantic button labels such as:
  - “Add one life.”
  - “Remove one poison counter.”
  - “Set Amanda’s Atraxa commander damage.”
- Keyboard and pointer support on iPad where SwiftUI provides it naturally.

---

## 24. Error and validation behavior

- Exact-value sheets reject empty/non-numeric input.
- Life accepts negative whole numbers.
- Counters, damage, and tax clamp at 0.
- Custom die sides clamp or validate to 2–999.
- Dice count validates to 1–100.
- Player count validates to 2–6.
- Custom counter names must be nonblank.
- Empty player and commander names fall back to contextual labels.
- Persistence errors should not crash the app:
  - Keep in-memory state.
  - Log in debug builds.
  - Retry on the next mutation or lifecycle save.

---

## 25. Suggested code organization

```text
LifeGrid/
  App/
    LifeGridApp.swift
    AppStateStore.swift
    AppEnvironment.swift

  Models/
    PersistedAppState.swift
    AppPreferences.swift
    GameSetup.swift
    ActiveGame.swift
    OpponentState.swift
    CounterModels.swift
    DiceModels.swift

  Persistence/
    AppStateRepository.swift
    JSONAppStateRepository.swift
    StateMigration.swift

  Features/
    NewGame/
    Game/
      GameScreen.swift
      PlayerLifeCard.swift
      OpponentCard.swift
      CommanderDamageRow.swift
      PinnedCountersGrid.swift
      PlayerStatusesSheet.swift
      OutOfGameSheet.swift
    Counters/
      CountersScreen.swift
      CounterCard.swift
      PinCounterSheet.swift
      CustomCounterEditor.swift
    Dice/
      DiceScreen.swift
      DiceRoller.swift
      DiceHistoryView.swift
      RandomPlayerPicker.swift
    Settings/
      SettingsScreen.swift
      AppearanceSettings.swift
      GameplaySettings.swift
      FeedbackSettings.swift

  Shared/
    Theme/
    Components/
    Haptics/
    Sound/
    Accessibility/
    Utilities/

  Tests/
    ModelTests/
    ReducerOrStoreTests/
    PersistenceTests/
    UITests/
```

Use dependency injection for randomness, persistence, haptics, sound, and time so behavior is testable.

---

## 26. Implementation rules

- Use SwiftUI.
- Prefer value types for domain state.
- Keep game rules outside views.
- Views should send intents to a central observable store or feature models.
- Use deterministic injectable random-number generation in tests.
- Use atomic file replacement for saves.
- Debounce only enough to avoid excessive disk churn; do not risk losing meaningful changes.
- Never infer player identity from a mutable name.
- Never tie UI behavior to card order.
- Do not introduce opponent life totals.
- Do not add Initiative.
- Do not add networking or iCloud.
- Do not redesign the approved icon.

---

## 27. Acceptance criteria

### Launch and persistence

- [ ] First launch shows New Game.
- [ ] An active game reopens exactly after force quit.
- [ ] Every meaningful mutation is persisted.
- [ ] No network or cloud entitlement is required.

### New Game

- [ ] Supports 2–6 total players.
- [ ] Supports all approved life presets and Custom.
- [ ] Remembers last setup.
- [ ] Optional names persist into restart.
- [ ] Unnamed opponents use stable default names.

### Life

- [ ] Entire left/right halves adjust −1/+1.
- [ ] Hold repeats.
- [ ] Tap total opens exact entry.
- [ ] Negative life is allowed.
- [ ] Manual life changes provide grouped temporary Undo.

### Commander

- [ ] Commander defaults on.
- [ ] Disabling it hides but does not delete data.
- [ ] Own partner setting affects only local tax UI.
- [ ] Opponent partners remain independent.
- [ ] Commander damage link applies only to future changes.
- [ ] Exact damage entry updates life by delta when linking is on.

### Opponents

- [ ] Up to five opponents.
- [ ] Add Opponent is on Game.
- [ ] Opponent life is never displayed.
- [ ] Primary and partner damage are independent.
- [ ] Partner removal confirms when data would be lost.
- [ ] Hidden players move to Out of Game and can be restored.
- [ ] Hidden players are excluded from random pickers.

### Statuses

- [ ] Monarch is exclusive.
- [ ] Monarch can be removed entirely.
- [ ] Hiding the Monarch requires transfer or removal.
- [ ] City’s Blessing may be held by multiple players.
- [ ] City’s Blessing clears when a player is hidden.
- [ ] Active badges are readable in every appearance.

### Counters

- [ ] All ten approved built-ins exist.
- [ ] Maximum four pins.
- [ ] Pin button hides at four.
- [ ] Edit Pins removes pins without deleting values.
- [ ] Day/Night starts Not Set and follows approved transitions.
- [ ] Custom counters persist between games.
- [ ] Swipe actions rename/delete custom counters.
- [ ] Deletion confirmation appears when needed.

### Warnings

- [ ] 21 damage from one commander triggers red warning.
- [ ] 10 poison triggers red warning.
- [ ] Banner is nonblocking.
- [ ] Persistent text badge remains while lethal.
- [ ] Dropping below clears persistent state.
- [ ] Recrossing triggers a new banner.

### Dice

- [ ] Built-in d4, d6, d8, d10, d12, d20 exist.
- [ ] Coin flip exists.
- [ ] Custom dice can be saved from d2 to d999.
- [ ] Roll quantity supports 1–100.
- [ ] Total and individual results are shown.
- [ ] More than 20 initially collapses individual results.
- [ ] Show All reveals every die.
- [ ] Last five entries include custom dice and every individual result.
- [ ] Starting Player includes user plus visible opponents.
- [ ] Random Opponent excludes user and hidden players.
- [ ] Brief shuffle animation respects Reduce Motion.

### Settings

- [ ] Player name editable in Settings and local card menu.
- [ ] Dark default with System and Light choices.
- [ ] Compact, Balanced, and Large scales exist.
- [ ] Balanced is default.
- [ ] Haptics default on.
- [ ] Sound defaults off.
- [ ] Keep Awake defaults on during active games.
- [ ] Reset Game uses approved reset/preserve rules.

### Accessibility

- [ ] All controls have meaningful accessibility labels.
- [ ] Touch targets remain usable in Compact mode.
- [ ] Lethal state is not color-only.
- [ ] Dynamic Type and Reduce Motion are supported.

---

## 28. Test cases that must exist

At minimum, create automated tests for:

1. Commander damage increase changes life by the same delta.
2. Commander damage decrease restores life.
3. Toggling link off does not rewrite prior life.
4. Exact commander damage entry applies correct delta.
5. Separate partner damage reaches lethal independently.
6. Monarch assignment transfers exclusively.
7. Hiding the Monarch requires a transfer decision.
8. Hiding clears City’s Blessing.
9. Restore preserves damage but not cleared statuses.
10. Quick Restart resets required values and preserves required configuration.
11. Counter pin maximum is four.
12. Custom-counter deletion removes an active pin only after confirmation path.
13. Day/Night transitions Not Set → Day → Night → Day.
14. Negative life persists through relaunch.
15. Numeric counters never become negative.
16. Saved state survives encode/decode round trip.
17. Last five dice entries trim correctly.
18. A 100-die roll stores every result.
19. Hidden players are excluded from random selection.
20. Random Opponent is unavailable when no visible opponent exists.

---

## 29. Definition of done

The build is complete only when:

- All acceptance criteria pass.
- Unit tests pass.
- UI tests cover the primary New Game, life, commander damage, pinning, dice, and restart flows.
- The app restores state after forced termination.
- The layout works on iPhone portrait, iPhone landscape, and iPad.
- Dark, Light, and System appearances remain readable.
- Compact, Balanced, and Large scales remain usable.
- The selected D20 Counter Ring icon is used without redesign.
