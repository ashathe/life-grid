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
