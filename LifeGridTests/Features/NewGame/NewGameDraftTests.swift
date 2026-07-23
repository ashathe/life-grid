import Testing
@testable import LifeGrid

@Suite(.serialized) struct NewGameDraftTests {
    @Test func rememberedSetupSeedsEveryField() {
        var state = PersistedAppState.default
        state.lastSetup = GameSetup(
            totalPlayers: 3,
            startingLife: 25,
            opponentNames: ["Amanda", "Chris"]
        )

        let draft = NewGameDraft(state: state)

        #expect(draft.totalPlayers == 3)
        #expect(draft.startingLife.value == 25)
        #expect(draft.opponentNames == ["Amanda", "Chris"])
        #expect(draft.rememberLastSetup)
    }

    @Test func disabledRememberingUsesApprovedNeutralDefaults() {
        var state = PersistedAppState.default
        state.preferences.rememberLastSetup = false
        state.preferences.defaultStartingLife = 60
        state.lastSetup = GameSetup(
            totalPlayers: 2,
            startingLife: 20,
            opponentNames: ["Remembered"]
        )

        let draft = NewGameDraft(state: state)

        #expect(draft.totalPlayers == 4)
        #expect(draft.startingLife.value == 60)
        #expect(draft.opponentNames == ["", "", ""])
        #expect(!draft.rememberLastSetup)
    }

    @Test func reducingPlayersDiscardsNamesAndReaddingCreatesBlanks() {
        var state = PersistedAppState.default
        state.lastSetup = GameSetup(
            totalPlayers: 4,
            startingLife: 40,
            opponentNames: ["Amanda", "Chris", "Jordan"]
        )
        var draft = NewGameDraft(state: state)

        draft.setTotalPlayers(2)
        draft.setTotalPlayers(4)

        #expect(draft.opponentNames == ["Amanda", "", ""])
    }

    @Test func validatedSetupTrimsNamesAndSuppliesFallbacks() {
        var draft = NewGameDraft(state: .default)
        draft.opponentNames = ["  Amanda  ", "  ", "Chris\n"]

        let setup = draft.validatedSetup

        #expect(setup == GameSetup(
            totalPlayers: 4,
            startingLife: 40,
            opponentNames: ["Amanda", "Opponent 2", "Chris"]
        ))
    }

    @Test func duplicateNamesRemainAllowed() {
        var state = PersistedAppState.default
        state.lastSetup = GameSetup(
            totalPlayers: 3,
            startingLife: 40,
            opponentNames: ["Alex", "Alex"]
        )

        let draft = NewGameDraft(state: state)

        #expect(draft.validatedSetup?.opponentNames == ["Alex", "Alex"])
    }

    @Test func invalidCustomLifePreventsSetupAndKeepsDraft() {
        var draft = NewGameDraft(state: .default)
        draft.startingLife.choice = .custom
        draft.startingLife.customText = "-1"

        #expect(draft.validatedSetup == nil)
        #expect(draft.startingLife.customText == "-1")
    }
}
