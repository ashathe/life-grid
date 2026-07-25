import SwiftUI

struct CounterCard: View {
    let name: String
    let counterID: CounterID
    @Bindable var store: AppStateStore

    @State private var exactText = ""
    @State private var exactError: String?
    @State private var showsExactEntry = false

    private var currentValue: Int {
        store.state.activeGame?.counterValues[counterID, default: 0] ?? 0
    }

    private var valueColor: Color {
        if counterID == CounterID.builtIn(.poison), currentValue >= 10 {
            return LifeGridPalette.destructive
        }
        return LifeGridPalette.primaryText
    }

    private var isLethal: Bool {
        counterID == CounterID.builtIn(.poison) && currentValue >= 10
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name)
                .font(.subheadline.bold())
                .foregroundStyle(LifeGridPalette.secondaryText)

            counterControls
        }
        .foregroundStyle(LifeGridPalette.primaryText)
        .padding(10)
        .background(LifeGridPalette.field, in: RoundedRectangle(cornerRadius: 10))
        .overlay { RoundedRectangle(cornerRadius: 10).stroke(LifeGridPalette.border) }
        .sheet(isPresented: $showsExactEntry) {
            exactEntrySheet
        }
    }

    private var counterControls: some View {
        HStack(spacing: 0) {
            RepeatActionButton(
                accessibilityLabel: "Remove one \(name) counter",
                accessibilityHint: "Hold to repeatedly remove counters",
                onInitial: {
                    await store.adjustCounter(counterID, by: -1)
                },
                onRepeat: {
                    let didMutate = await store.adjustCounter(counterID, by: -1)
                    if didMutate { await store.playHaptic(.adjustment) }
                },
                onEnd: {}
            ) {
                Text("−")
                    .font(.title3)
                    .frame(maxWidth: .infinity, minHeight: 48)
            }
            .accessibilityIdentifier("counter-decrement-\(name)")

            Divider()
                .overlay(LifeGridPalette.border)
                .frame(height: 48)

            Button {
                exactText = "\(currentValue)"
                exactError = nil
                showsExactEntry = true
            } label: {
                Text("\(currentValue)")
                    .font(.title3.bold().monospacedDigit())
                    .foregroundStyle(valueColor)
                    .frame(minWidth: 56, minHeight: 48)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Set \(name) counter value")
            .accessibilityValue("\(currentValue)")
            .accessibilityHint("Opens exact entry")
            .accessibilityIdentifier("counter-value-\(name)")

            Divider()
                .overlay(LifeGridPalette.border)
                .frame(height: 48)

            RepeatActionButton(
                accessibilityLabel: "Add one \(name) counter",
                accessibilityHint: "Hold to repeatedly add counters",
                onInitial: {
                    await store.adjustCounter(counterID, by: 1)
                },
                onRepeat: {
                    let didMutate = await store.adjustCounter(counterID, by: 1)
                    if didMutate { await store.playHaptic(.adjustment) }
                },
                onEnd: {}
            ) {
                Text("+")
                    .font(.title3)
                    .frame(maxWidth: .infinity, minHeight: 48)
            }
            .accessibilityIdentifier("counter-increment-\(name)")
        }
        .background(
            LifeGridPalette.field,
            in: RoundedRectangle(cornerRadius: 9)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 9)
                .stroke(LifeGridPalette.border)
        }
        .clipShape(RoundedRectangle(cornerRadius: 9))
    }

    private var exactEntrySheet: some View {
        NavigationStack {
            Form {
                TextField("Value", text: $exactText)
                    .keyboardType(.numberPad)

                if let exactError {
                    Text(exactError)
                        .font(.footnote)
                        .foregroundStyle(LifeGridPalette.destructive)
                        .accessibilityLabel(exactError)
                }
            }
            .scrollContentBackground(.hidden)
            .background(LifeGridPalette.background)
            .preferredColorScheme(.dark)
            .accessibilityIdentifier("counter-exact-entry")
            .navigationTitle("Set \(name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        exactError = nil
                        showsExactEntry = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Set") {
                        Task { await applyExact() }
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func applyExact() async {
        guard let value = Int(exactText) else {
            exactError = "Enter a whole-number value."
            return
        }
        let success = await store.setCounterValue(counterID, to: value)
        if success {
            exactError = nil
            showsExactEntry = false
        }
    }
}
