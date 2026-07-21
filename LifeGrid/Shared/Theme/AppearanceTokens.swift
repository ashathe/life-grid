import SwiftUI

enum AppearanceToken: CaseIterable, Equatable, Sendable {
    case background
    case surface
    case primaryAccent
    case lethal
    case destructive
    case primaryText
    case secondaryText
}

enum LifeGridPalette {
    static let background = Color(red: 0.035, green: 0.03, blue: 0.05)
    static let surface = Color(red: 0.105, green: 0.09, blue: 0.135)
    static let field = Color(red: 0.055, green: 0.045, blue: 0.075)
    static let control = Color(red: 0.145, green: 0.12, blue: 0.18)
    static let border = Color(red: 0.22, green: 0.18, blue: 0.28)
    static let accent = Color(red: 0.54, green: 0.29, blue: 0.96)
    static let destructive = Color(red: 0.78, green: 0.13, blue: 0.19)
    static let primaryText = Color(red: 0.97, green: 0.96, blue: 0.99)
    static let secondaryText = Color(red: 0.63, green: 0.60, blue: 0.69)
}
