import Foundation

struct ActiveGame: Codable, Identifiable, Equatable, Sendable {
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
