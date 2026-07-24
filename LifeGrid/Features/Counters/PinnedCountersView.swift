import SwiftUI

struct PinnedCountersView: View {
    @Bindable var store: AppStateStore
    @State private var editMode = false
    @State private var showsPinPicker = false

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private var pinnedIDs: [CounterID] {
        store.state.activeGame?.pinnedCounterIDs ?? []
    }

    private var canPinMore: Bool {
        pinnedIDs.count < 4
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Pinned Counters")
                    .font(.headline)
                Spacer()
                if !pinnedIDs.isEmpty {
                    Button(editMode ? "Done" : "Edit Pins") {
                        withAnimation { editMode.toggle() }
                    }
                    .font(.subheadline)
                    .accessibilityIdentifier("edit-pins")
                }
                if canPinMore, !editMode, !pinnedIDs.isEmpty {
                    Button {
                        showsPinPicker = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Add pinned counter")
                    .accessibilityIdentifier("add-pin-counter")
                }
            }

            if pinnedIDs.isEmpty {
                Button {
                    showsPinPicker = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                        Text("Pin a Counter")
                            .font(.subheadline)
                    }
                    .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add a pinned counter")
                .accessibilityIdentifier("add-pin-counter-empty")
            } else {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(pinnedIDs, id: \.self) { counterID in
                        pinnedTile(counterID)
                    }
                }
            }
        }
        .foregroundStyle(LifeGridPalette.primaryText)
        .lifeGridCard()
        .sheet(isPresented: $showsPinPicker) {
            PinCounterSheet(store: store)
        }
    }

    private func pinnedTile(_ counterID: CounterID) -> some View {
        VStack(spacing: 6) {
            Text(displayName(for: counterID))
                .font(.caption.bold())
                .lineLimit(1)
                .foregroundStyle(LifeGridPalette.secondaryText)

            Text("\(currentValue(for: counterID))")
                .font(.title2.bold().monospacedDigit())
                .foregroundStyle(valueColor(for: counterID))
                .accessibilityLabel(displayName(for: counterID))
                .accessibilityValue("\(currentValue(for: counterID))")

            HStack(spacing: 12) {
                RepeatActionButton(
                    accessibilityLabel: "Remove one \(displayName(for: counterID))",
                    accessibilityHint: "Hold to repeatedly remove counters",
                    onInitial: {
                        await store.adjustCounter(counterID, by: -1)
                    },
                    onRepeat: {
                        await store.adjustCounter(counterID, by: -1)
                        await store.playHaptic(.adjustment)
                    },
                    onEnd: {}
                ) {
                    Text("−")
                        .font(.title3)
                        .frame(width: 44, height: 44)
                }
                .accessibilityIdentifier("pin-decrement-\(displayName(for: counterID))")

                RepeatActionButton(
                    accessibilityLabel: "Add one \(displayName(for: counterID))",
                    accessibilityHint: "Hold to repeatedly add counters",
                    onInitial: {
                        await store.adjustCounter(counterID, by: 1)
                    },
                    onRepeat: {
                        await store.adjustCounter(counterID, by: 1)
                        await store.playHaptic(.adjustment)
                    },
                    onEnd: {}
                ) {
                    Text("+")
                        .font(.title3)
                        .frame(width: 44, height: 44)
                }
                .accessibilityIdentifier("pin-increment-\(displayName(for: counterID))")
            }

            if editMode {
                Button {
                    Task { await store.unpinCounter(counterID) }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(LifeGridPalette.destructive)
                }
                .buttonStyle(.plain)
                .frame(height: 28)
                .accessibilityLabel("Unpin \(displayName(for: counterID))")
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

    private func displayName(for id: CounterID) -> String {
        switch id {
        case .builtIn(let builtIn): return builtIn.displayName
        case .custom(let uuid):
            return store.state.customCounters.first(where: { $0.id == uuid })?.name
                ?? "Custom"
        }
    }

    private func currentValue(for id: CounterID) -> Int {
        store.state.activeGame?.counterValues[id, default: 0] ?? 0
    }

    private func valueColor(for id: CounterID) -> Color {
        if id == CounterID.builtIn(.poison), currentValue(for: id) >= 10 {
            return LifeGridPalette.destructive
        }
        return LifeGridPalette.primaryText
    }
}
