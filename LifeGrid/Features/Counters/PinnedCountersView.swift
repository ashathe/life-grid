import SwiftUI

struct PinnedCountersView: View {
    @Bindable var store: AppStateStore
    @State private var editMode = false
    @State private var showsPinPicker = false

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
                if canPinMore, !editMode {
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
                Text("Tap + to pin up to four counters to this screen.")
                    .font(.caption)
                    .foregroundStyle(LifeGridPalette.secondaryText)
            } else {
                ForEach(pinnedIDs, id: \.self) { counterID in
                    pinnedCounterRow(counterID)
                }
            }
        }
        .foregroundStyle(LifeGridPalette.primaryText)
        .lifeGridCard()
        .sheet(isPresented: $showsPinPicker) {
            PinCounterSheet(store: store)
        }
    }

    private func pinnedCounterRow(_ counterID: CounterID) -> some View {
        HStack(spacing: 0) {
            Text(displayName(for: counterID))
                .font(.subheadline.bold())
                .lineLimit(1)

            Spacer()

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

            Text("\(currentValue(for: counterID))")
                .font(.headline.monospacedDigit())
                .frame(minWidth: 36)
                .accessibilityLabel(displayName(for: counterID))
                .accessibilityValue("\(currentValue(for: counterID))")

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

            if editMode {
                Button {
                    Task { await store.unpinCounter(counterID) }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(LifeGridPalette.destructive)
                }
                .buttonStyle(.plain)
                .frame(width: 44, height: 44)
                .accessibilityLabel("Unpin \(displayName(for: counterID))")
                .accessibilityIdentifier("unpin-\(displayName(for: counterID))")
            }
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
}
