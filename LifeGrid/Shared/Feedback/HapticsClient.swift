enum HapticEvent: Equatable, Sendable {
    case adjustment
    case statusChange
    case result
    case warning
}

protocol HapticsClient: Sendable {
    func play(_ event: HapticEvent) async
}

struct NoOpHapticsClient: HapticsClient {
    func play(_ event: HapticEvent) async {}
}
