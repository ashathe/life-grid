import Foundation

struct GameSetup: Codable, Equatable, Sendable {
    var totalPlayers: Int
    var startingLife: Int
    var opponentNames: [String]
}
