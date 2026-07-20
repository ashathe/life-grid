import Foundation

enum ActiveGameFactory {
    static func make(
        setup: GameSetup,
        id: UUID = UUID(),
        opponentIDs: [UUID]? = nil,
        startedAt: Date
    ) -> ActiveGame {
        precondition((2...6).contains(setup.totalPlayers))
        precondition(setup.startingLife > 0)
        precondition(setup.opponentNames.count == setup.totalPlayers - 1)

        let ids = opponentIDs ?? setup.opponentNames.map { _ in UUID() }
        precondition(ids.count == setup.opponentNames.count)

        let opponents = zip(ids, setup.opponentNames).map { id, name in
            OpponentState(
                id: id,
                displayName: name,
                isVisible: true,
                primaryCommanderName: nil,
                primaryCommanderDamage: 0,
                partner: nil,
                hasCitysBlessing: false
            )
        }
        let counters = Dictionary(uniqueKeysWithValues:
            BuiltInCounterID.allCases
                .filter { $0 != .dayNight }
                .map { (CounterID.builtIn($0), 0) }
        )

        return ActiveGame(
            id: id,
            startedAt: startedAt,
            startingLife: setup.startingLife,
            currentLife: setup.startingLife,
            opponents: opponents,
            ownCommanderAName: nil,
            ownCommanderBName: nil,
            ownCommanderTaxA: 0,
            ownCommanderTaxB: 0,
            currentMonarchPlayerID: nil,
            playerHasCitysBlessing: false,
            counterValues: counters,
            dayNightState: .notSet,
            pinnedCounterIDs: [],
            keepAwakeOverride: nil
        )
    }
}
