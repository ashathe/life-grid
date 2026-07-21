import Foundation

enum PlayerID: Codable, Equatable, Hashable, Sendable {
    case local
    case opponent(UUID)
}

struct OpponentState: Codable, Identifiable, Equatable, Sendable {
    var id: UUID
    var displayName: String
    var isVisible: Bool
    var primaryCommanderName: String?
    var primaryCommanderDamage: Int
    var partner: PartnerCommanderState?
    var hasCitysBlessing: Bool
}

struct PartnerCommanderState: Codable, Equatable, Sendable {
    var name: String?
    var damage: Int
}

extension OpponentState {
    static let maximumCount = 5

    static func nextDefaultDisplayName(in opponents: [OpponentState]) -> String {
        let occupied = Set(opponents.compactMap { opponent -> Int? in
            let prefix = "Opponent "
            guard opponent.displayName.hasPrefix(prefix),
                  let number = Int(opponent.displayName.dropFirst(prefix.count)),
                  number > 0 else { return nil }
            return number
        })
        var candidate = 1
        while occupied.contains(candidate) {
            candidate += 1
        }
        return "Opponent \(candidate)"
    }

    static func newDefault(displayName: String) -> OpponentState {
        OpponentState(
            id: UUID(),
            displayName: displayName,
            isVisible: true,
            primaryCommanderName: nil,
            primaryCommanderDamage: 0,
            partner: nil,
            hasCitysBlessing: false
        )
    }
}
