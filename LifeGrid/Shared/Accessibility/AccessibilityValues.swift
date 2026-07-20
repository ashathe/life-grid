enum AccessibilityValues {
    static func namedValue(label: String, value: String) -> String {
        "\(label), \(value)"
    }

    static func adjustmentHint(increment: String, decrement: String) -> String {
        "Swipe up to \(increment). Swipe down to \(decrement)."
    }
}
