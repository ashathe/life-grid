import SwiftUI

struct DiceRoller: View {
    let sides: Int
    let label: String
    @Bindable var store: AppStateStore

    @State private var diceCount: Int
    @State private var lastResult: DiceRollEntry?
    @State private var showAllResults = false

    init(sides: Int, label: String, store: AppStateStore) {
        self.sides = sides
        self.label = label
        self.store = store
        _diceCount = State(initialValue: store.diceCount(forSides: sides))
    }

    var body: some View {
        VStack(spacing: 8) {
            Text(label)
                .font(.subheadline.bold())
                .foregroundStyle(LifeGridPalette.secondaryText)
                .accessibilityLabel("\(label) die")

            if let result = lastResult {
                Text("\(result.total)")
                    .font(.largeTitle.bold().monospacedDigit())
                    .foregroundStyle(LifeGridPalette.primaryText)
                    .accessibilityLabel("\(label) result")
                    .accessibilityValue("\(result.total), from \(result.diceCount) \(label)")
            } else {
                Text("—")
                    .font(.largeTitle.monospacedDigit())
                    .foregroundStyle(LifeGridPalette.secondaryText)
                    .accessibilityLabel("\(label), no roll yet")
            }

            HStack(spacing: 8) {
                Button {
                    if diceCount > 1 { diceCount -= 1 }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Fewer \(label)")

                Text("\(diceCount)")
                    .font(.title3.monospacedDigit().bold())
                    .frame(minWidth: 28)
                    .accessibilityLabel("Number of dice")
                    .accessibilityValue("\(diceCount)")

                Button {
                    if diceCount < 100 { diceCount += 1 }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("More \(label)")
            }

            Button {
                Task { await roll() }
            } label: {
                Text("Roll \(diceCount)d\(sides)")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity, minHeight: 36)
            }
            .buttonStyle(.borderedProminent)
            .tint(LifeGridPalette.accent)
            .accessibilityLabel("Roll \(diceCount) \(label)")

            if let result = lastResult, !result.individualResults.isEmpty {
                let visible = showAllResults || result.individualResults.count <= 20
                    ? result.individualResults
                    : Array(result.individualResults.prefix(20))
                Text(visible.map(String.init).joined(separator: " "))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(LifeGridPalette.secondaryText)
                    .lineLimit(3)
                    .multilineTextAlignment(.center)
                if result.individualResults.count > 20, !showAllResults {
                    Button("Show All (\(result.individualResults.count))") {
                        showAllResults = true
                    }
                    .font(.caption2)
                    .accessibilityLabel("Show all \(result.individualResults.count) individual results")
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
        .onChange(of: diceCount) { _, newCount in
            Task { await store.setDiceCount(newCount, forSides: sides) }
        }
    }

    private func roll() async {
        showAllResults = false
        lastResult = await store.rollDice(sides: sides, count: diceCount)
        await store.playHaptic(.adjustment)
    }
}
