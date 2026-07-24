import SwiftUI

struct DiceHistoryView: View {
    @Bindable var store: AppStateStore

    private var history: [DiceRollEntry] {
        store.state.diceHistory.reversed()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("History")
                .font(.subheadline.bold())
                .foregroundStyle(LifeGridPalette.secondaryText)

            if history.isEmpty {
                Text("No rolls yet")
                    .font(.caption)
                    .foregroundStyle(LifeGridPalette.secondaryText)
            } else {
                ForEach(history) { entry in
                    HStack(spacing: 8) {
                        Text("\(entry.diceCount)d\(entry.sides)")
                            .font(.subheadline.monospacedDigit().bold())
                            .foregroundStyle(LifeGridPalette.accent)
                            .frame(width: 44, alignment: .leading)
                            .accessibilityLabel("\(entry.diceCount) d\(entry.sides)")

                        Text("= \(entry.total)")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(LifeGridPalette.primaryText)
                            .frame(width: 56, alignment: .leading)
                            .accessibilityLabel("Total: \(entry.total)")

                        Text(entry.individualResults.map(String.init).joined(separator: " "))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(LifeGridPalette.secondaryText)
                            .lineLimit(1)
                            .accessibilityLabel("Rolls: \(entry.individualResults.map(String.init).joined(separator: ", "))")
                    }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(
            LifeGridPalette.field,
            in: RoundedRectangle(cornerRadius: 10)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(LifeGridPalette.border)
        }
    }
}
