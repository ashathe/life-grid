import SwiftUI

enum CoinFlipFace: String {
    case heads, tails
    var label: String { rawValue.capitalized }
    var symbol: String { self == .heads ? "H" : "T" }
}

struct CoinFlipView: View {
    @Bindable var store: AppStateStore
    @State private var result: CoinFlipFace?
    @State private var isFlipping = false

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Coin Flip")
                    .font(.subheadline.bold())
                if let result {
                    Text(result.label)
                        .font(.title3.bold())
                        .foregroundStyle(
                            result == .heads
                                ? Color(red: 0.95, green: 0.75, blue: 0.25)
                                : Color(red: 0.75, green: 0.75, blue: 0.80)
                        )
                }
            }

            Spacer()

            ZStack {
                Circle()
                    .fill(LifeGridPalette.field)
                    .frame(width: 64, height: 64)
                    .overlay {
                        Circle().stroke(LifeGridPalette.border, lineWidth: 2)
                    }

                if let result {
                    Text(result.symbol)
                        .font(.title.bold())
                        .foregroundStyle(
                            result == .heads
                                ? Color(red: 0.95, green: 0.75, blue: 0.25)
                                : Color(red: 0.75, green: 0.75, blue: 0.80)
                        )
                } else {
                    Text("?")
                        .font(.title.bold())
                        .foregroundStyle(LifeGridPalette.secondaryText)
                }
            }

            Button("Flip") {
                Task { await flip() }
            }
            .buttonStyle(.borderedProminent)
            .tint(LifeGridPalette.accent)
            .disabled(isFlipping)
        }
        .padding(16)
        .background(
            LifeGridPalette.surface,
            in: RoundedRectangle(cornerRadius: 12)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(LifeGridPalette.border, lineWidth: 1)
        }
    }

    private func flip() async {
        isFlipping = true
        result = nil
        try? await Task.sleep(for: .milliseconds(400))
        result = await store.flipCoin()
        await store.playHaptic(.adjustment)
        isFlipping = false
    }
}
