import Foundation

struct SavedDieDefinition: Codable, Identifiable, Equatable, Sendable {
    var id: UUID
    var sides: Int
}

struct DiceRollEntry: Codable, Identifiable, Equatable, Sendable {
    var id: UUID
    var timestamp: Date
    var sides: Int
    var diceCount: Int
    var individualResults: [Int]
    var total: Int
}
