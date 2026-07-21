import SwiftUI

struct LifeGridCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                LifeGridPalette.surface,
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(LifeGridPalette.border, lineWidth: 1)
            }
    }
}

extension View {
    func lifeGridCard() -> some View {
        modifier(LifeGridCard())
    }
}
