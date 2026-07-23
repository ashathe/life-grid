import Foundation
import Testing
@testable import LifeGrid

@Suite(.serialized) struct ActiveGameFactoryTests {
    @Test func createsCompleteApprovedInitialState() {
        let gameID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let opponentIDs = [
            UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
        ]
        let startedAt = Date(timeIntervalSince1970: 1_700_000_000)
        let setup = GameSetup(
            totalPlayers: 3,
            startingLife: 25,
            opponentNames: ["Amanda", "Chris"]
        )

        let game = ActiveGameFactory.make(
            setup: setup,
            id: gameID,
            opponentIDs: opponentIDs,
            startedAt: startedAt
        )

        #expect(game.id == gameID)
        #expect(game.startedAt == startedAt)
        #expect(game.startingLife == 25)
        #expect(game.currentLife == 25)
        #expect(game.opponents.map(\.id) == opponentIDs)
        #expect(game.opponents.map(\.displayName) == ["Amanda", "Chris"])
        #expect(game.opponents.allSatisfy { $0.isVisible })
        #expect(game.opponents.allSatisfy { $0.primaryCommanderDamage == 0 })
        #expect(game.opponents.allSatisfy { $0.partner == nil })
        #expect(game.opponents.allSatisfy { !$0.hasCitysBlessing })
        #expect(game.ownCommanderAName == nil)
        #expect(game.ownCommanderBName == nil)
        #expect(game.ownCommanderTaxA == 0)
        #expect(game.ownCommanderTaxB == 0)
        #expect(game.currentMonarchPlayerID == nil)
        #expect(!game.playerHasCitysBlessing)
        #expect(game.dayNightState == .notSet)
        #expect(game.pinnedCounterIDs.isEmpty)
        #expect(game.keepAwakeOverride == nil)

        let expectedCounters = Set(
            BuiltInCounterID.allCases
                .filter { $0 != .dayNight }
                .map { CounterID.builtIn($0) }
        )
        #expect(Set(game.counterValues.keys) == expectedCounters)
        #expect(game.counterValues.values.allSatisfy { $0 == 0 })
    }
}
