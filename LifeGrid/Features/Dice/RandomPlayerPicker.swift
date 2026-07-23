import SwiftUI

struct RandomPlayerPicker: View {
    @Bindable var store: AppStateStore

    @State private var selectedPlayer: String?
    @State private var isPicking = false

    var body: some View {
        VStack(spacing: 8) {
            Text("Random Player")
                .font(.subheadline.bold())
                .foregroundStyle(LifeGridPalette.secondaryText)

            if let selectedPlayer {
                Text(selectedPlayer)
                    .font(.title3.bold())
                    .foregroundStyle(LifeGridPalette.accent)
            } else {
                Text("—")
                    .font(.title3)
                    .foregroundStyle(LifeGridPalette.secondaryText)
            }

            HStack(spacing: 8) {
                Button("Starting") {
                    Task { await pick(.starting) }
                }
                .buttonStyle(.borderedProminent)
                .tint(LifeGridPalette.accent)
                .disabled(isPicking)

                Button("Opponent") {
                    Task { await pick(.opponent) }
                }
                .buttonStyle(.borderedProminent)
                .tint(LifeGridPalette.accent)
                .disabled(isPicking)
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

    private enum PickMode { case starting, opponent }

    private func pick(_ mode: PickMode) async {
        isPicking = true
        selectedPlayer = nil
        try? await Task.sleep(for: .milliseconds(300))
        switch mode {
        case .starting:
            selectedPlayer = await store.pickRandomStartingPlayer()
        case .opponent:
            selectedPlayer = await store.pickRandomOpponent()
        }
        await store.playHaptic(.adjustment)
        isPicking = false
    }
}
