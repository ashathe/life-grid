enum StartingLifeChoice: Equatable, Sendable {
    case preset(Int)
    case custom
}

struct StartingLifeInput: Equatable, Sendable {
    static let presets = [20, 25, 30, 40, 60]

    var choice: StartingLifeChoice
    var customText: String

    init(value: Int) {
        if Self.presets.contains(value) {
            choice = .preset(value)
            customText = ""
        } else {
            choice = .custom
            customText = String(value)
        }
    }

    var value: Int? {
        switch choice {
        case .preset(let value):
            return value
        case .custom:
            guard
                !customText.isEmpty,
                customText.allSatisfy(\.isNumber),
                let value = Int(customText),
                value > 0
            else {
                return nil
            }
            return value
        }
    }

    var validationMessage: String? {
        choice == .custom && value == nil
            ? "Enter a positive whole number."
            : nil
    }
}
