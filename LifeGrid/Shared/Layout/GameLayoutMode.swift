enum GameLayoutMode: Equatable, Sendable {
    case singleColumn
    case twoColumn
}

struct GameLayoutContext: Equatable, Sendable {
    var width: Double
    var height: Double
    var horizontalSizeClassIsRegular: Bool
}

extension GameLayoutMode {
    static func resolve(_ context: GameLayoutContext) -> GameLayoutMode {
        context.horizontalSizeClassIsRegular || context.width > context.height
            ? .twoColumn
            : .singleColumn
    }
}
