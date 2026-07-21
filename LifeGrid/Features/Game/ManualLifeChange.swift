import Foundation

struct ManualLifeChange: Equatable, Sendable {
    let previousValue: Int
    let currentValue: Int
}

struct LocalLifeUndoState: Equatable, Sendable {
    let restoreValue: Int
    let operationID: UUID
}

enum LocalCommanderTaxSlot: Equatable, Sendable {
    case primary
    case partner
}
