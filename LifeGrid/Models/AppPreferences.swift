import Foundation

enum AppearanceMode: String, Codable, CaseIterable, Equatable, Sendable {
    case dark
    case system
    case light
}

enum AppScale: String, Codable, CaseIterable, Equatable, Sendable {
    case compact
    case balanced
    case large
}

struct AppPreferences: Codable, Equatable, Sendable {
    var playerName: String
    var commanderEnabled: Bool
    var ownPartnerCommanderEnabled: Bool
    var commanderDamageChangesLife: Bool
    var keepScreenAwakeDuringGames: Bool
    var hapticsEnabled: Bool
    var soundEffectsEnabled: Bool
    var appearance: AppearanceMode
    var appScale: AppScale
    var defaultStartingLife: Int
    var rememberLastSetup: Bool

    static let `default` = AppPreferences(
        playerName: "",
        commanderEnabled: true,
        ownPartnerCommanderEnabled: false,
        commanderDamageChangesLife: true,
        keepScreenAwakeDuringGames: true,
        hapticsEnabled: true,
        soundEffectsEnabled: false,
        appearance: .dark,
        appScale: .balanced,
        defaultStartingLife: 40,
        rememberLastSetup: true
    )
}
