import Foundation

struct CommanderDamageChange: Equatable, Sendable {
    let previousDamage: Int
    let currentDamage: Int
    let previousLife: Int
    let currentLife: Int
}
