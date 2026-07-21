#if os(iOS)
import UIKit
#endif

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

struct UIKitHapticsClient: HapticsClient {
    func play(_ event: HapticEvent) async {
        switch event {
        case .adjustment:
            #if os(iOS)
            await MainActor.run {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            #endif
        case .statusChange, .result, .warning:
            break
        }
    }
}
