import Foundation
import Testing
@testable import LifeGrid

struct PersistedAppStateTests {
    @Test func approvedDefaultsAreStable() {
        let state = PersistedAppState.default

        #expect(state.schemaVersion == 1)
        #expect(state.preferences.playerName == "")
        #expect(state.preferences.commanderEnabled)
        #expect(!state.preferences.ownPartnerCommanderEnabled)
        #expect(state.preferences.commanderDamageChangesLife)
        #expect(state.preferences.keepScreenAwakeDuringGames)
        #expect(state.preferences.hapticsEnabled)
        #expect(!state.preferences.soundEffectsEnabled)
        #expect(state.preferences.appearance == .dark)
        #expect(state.preferences.appScale == .balanced)
        #expect(state.lastSetup == GameSetup(totalPlayers: 4, startingLife: 40, opponentNames: []))
        #expect(state.activeGame == nil)
        #expect(state.customCounters.isEmpty)
        #expect(state.savedDice.isEmpty)
        #expect(state.diceHistory.isEmpty)
    }

    @Test func completeStateRoundTripsThroughJSON() throws {
        let original = PersistedAppState.completeFixture

        let data = try JSONEncoder.lifeGrid.encode(original)
        let restored = try JSONDecoder.lifeGrid.decode(PersistedAppState.self, from: data)

        #expect(restored == original)
        #expect(restored.activeGame?.currentLife == -5)
        #expect(restored.diceHistory.count == 5)
        #expect(restored.diceHistory.last?.individualResults == [4, 1, 3])
    }

    @Test func playerIdentityDoesNotDependOnName() {
        let opponentID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!

        #expect(PlayerID.opponent(opponentID) == PlayerID.opponent(opponentID))
        #expect(PlayerID.local != PlayerID.opponent(opponentID))
    }

    @Test func opponentEncodingContainsNoLifeTotal() throws {
        let opponent = PersistedAppState.completeFixture.activeGame!.opponents[0]
        let data = try JSONEncoder.lifeGrid.encode(opponent)
        let json = String(decoding: data, as: UTF8.self)

        #expect(!json.localizedCaseInsensitiveContains("life"))
    }
}

private extension PersistedAppState {
    static var completeFixture: PersistedAppState {
        let visibleID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let hiddenID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let customCounterID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
        let savedDieID = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let customCounter = CustomCounterDefinition(id: customCounterID, name: "Bargain", createdAt: start)
        let rolls = (0..<5).map { index in
            DiceRollEntry(
                id: UUID(uuidString: "55555555-5555-5555-5555-55555555555\(index)")!,
                timestamp: start.addingTimeInterval(Double(index)),
                sides: 6,
                diceCount: 3,
                individualResults: [4, 1, 3],
                total: 8
            )
        }

        return PersistedAppState(
            schemaVersion: 1,
            preferences: .default,
            lastSetup: GameSetup(totalPlayers: 3, startingLife: 40, opponentNames: ["Amanda", "Chris"]),
            activeGame: ActiveGame(
                id: UUID(uuidString: "66666666-6666-6666-6666-666666666666")!,
                startedAt: start,
                startingLife: 40,
                currentLife: -5,
                opponents: [
                    OpponentState(
                        id: visibleID,
                        displayName: "Amanda",
                        isVisible: true,
                        primaryCommanderName: "Atraxa",
                        primaryCommanderDamage: 21,
                        partner: PartnerCommanderState(name: "Tymna", damage: 3),
                        hasCitysBlessing: true
                    ),
                    OpponentState(
                        id: hiddenID,
                        displayName: "Chris",
                        isVisible: false,
                        primaryCommanderName: nil,
                        primaryCommanderDamage: 4,
                        partner: nil,
                        hasCitysBlessing: false
                    )
                ],
                ownCommanderAName: "A",
                ownCommanderBName: "B",
                ownCommanderTaxA: 2,
                ownCommanderTaxB: 4,
                currentMonarchPlayerID: .opponent(visibleID),
                playerHasCitysBlessing: true,
                counterValues: [.builtIn(.poison): 3, .custom(customCounterID): 7],
                dayNightState: .night,
                pinnedCounterIDs: [.builtIn(.poison), .builtIn(.dayNight), .custom(customCounterID)],
                keepAwakeOverride: false
            ),
            customCounters: [customCounter],
            savedDice: [SavedDieDefinition(id: savedDieID, sides: 37)],
            diceHistory: rolls
        )
    }
}
