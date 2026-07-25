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

struct SystemSoundClient: SoundClient {
    func play(_ event: SoundEvent) async {
        let soundID: SystemSoundID = switch event {
        case .diceResult:    1104
        case .coinFlip:      1057
        case .lethalWarning: 1006
        }
        await MainActor.run {
            AudioServicesPlaySystemSound(soundID)
        }
    }
}

import AudioToolbox
