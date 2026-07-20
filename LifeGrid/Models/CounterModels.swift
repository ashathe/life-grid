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
