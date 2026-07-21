struct ManualLifeChange: Equatable, Sendable {
    let previousValue: Int
    let currentValue: Int
}

enum LocalCommanderTaxSlot: Equatable, Sendable {
    case primary
    case partner
}
