import Foundation

enum OpponentMutationResult<Value: Equatable & Sendable>: Equatable, Sendable {
    case persisted(Value)
    case retainedInMemory(Value)
    case rejected

    var mutation: Value? {
        switch self {
        case .persisted(let value), .retainedInMemory(let value):
            value
        case .rejected:
            nil
        }
    }

    var persistedValue: Value? {
        guard case .persisted(let value) = self else { return nil }
        return value
    }
}

struct CommanderDamageChange: Equatable, Sendable {
    let previousDamage: Int
    let currentDamage: Int
    let previousLife: Int
    let currentLife: Int
}
