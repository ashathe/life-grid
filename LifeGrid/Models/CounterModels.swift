import Foundation

enum BuiltInCounterID: String, Codable, CaseIterable, Equatable, Hashable, Sendable {
    case poison
    case energy
    case experience
    case treasure
    case radiation
    case storm
    case charge
    case doom
    case tickets
    case dayNight
}

enum CounterID: Codable, Equatable, Hashable, Sendable {
    case builtIn(BuiltInCounterID)
    case custom(UUID)
}

enum DayNightState: String, Codable, Equatable, Sendable {
    case notSet
    case day
    case night
}

struct CustomCounterDefinition: Codable, Identifiable, Equatable, Sendable {
    var id: UUID
    var name: String
    var createdAt: Date
}

// MARK: - Display Helpers

extension BuiltInCounterID {
    var displayName: String {
        switch self {
        case .poison: return "Poison"
        case .energy: return "Energy"
        case .experience: return "Experience"
        case .treasure: return "Treasure"
        case .radiation: return "Radiation"
        case .storm: return "Storm"
        case .charge: return "Charge"
        case .doom: return "Doom"
        case .tickets: return "Tickets"
        case .dayNight: return "Day / Night"
        }
    }

    var isDayNight: Bool { self == .dayNight }
}

extension CustomCounterDefinition {
    func hasNameCollision(with other: String) -> Bool {
        name.caseInsensitiveCompare(other.trimmingCharacters(in: .whitespaces)) == .orderedSame
    }
}
