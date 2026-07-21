enum SoundEvent: Equatable, Sendable {
    case diceResult
    case coinFlip
    case lethalWarning
}

protocol SoundClient: Sendable {
    func play(_ event: SoundEvent) async
}

struct NoOpSoundClient: SoundClient {
    func play(_ event: SoundEvent) async {}
}
