import SwiftUI

struct PinCounterSheet: View {
    @Bindable var store: AppStateStore
    @Environment(\.dismiss) private var dismiss

    private var pinnedIDs: Set<CounterID> {
        Set(store.state.activeGame?.pinnedCounterIDs ?? [])
    }

    private var availableBuiltIn: [CounterID] {
        BuiltInCounterID.allCases.map { .builtIn($0) }
            .filter { !pinnedIDs.contains($0) }
    }

    private var availableCustom: [CounterID] {
        store.state.customCounters.map { .custom($0.id) }
            .filter { !pinnedIDs.contains($0) }
    }

    private var pinSlotsRemaining: Int {
        max(0, 4 - pinnedIDs.count)
    }

    var body: some View {
        NavigationStack {
            List {
                if pinSlotsRemaining == 0 {
                    ContentUnavailableView(
                        "All slots pinned",
                        systemImage: "pin.fill",
                        description: Text("Unpin a counter to make room.")
                    )
                } else {
                    if !availableBuiltIn.isEmpty {
                        Section("Counters") {
                            ForEach(availableBuiltIn, id: \.self) { counterID in
                                pinRow(for: counterID)
                            }
                        }
                    }

                    if !availableCustom.isEmpty {
                        Section("Custom") {
                            ForEach(availableCustom, id: \.self) { counterID in
                                pinRow(for: counterID)
                            }
                        }
                    }

                    if availableBuiltIn.isEmpty && availableCustom.isEmpty {
                        ContentUnavailableView(
                            "All counters pinned",
                            systemImage: "pin.fill",
                            description: Text("You can pin up to four counters.")
                        )
                    }
                }

                Section {
                    Button {
                        Task {
                            let created = await store.addCustomCounter(
                                name: "New Counter"
                            )
                            if let counterID = created.map({ CounterID.custom($0.id) }),
                               await store.pinCounter(counterID) {
                                dismiss()
                            }
                        }
                    } label: {
                        Label("New Custom Counter", systemImage: "plus")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(LifeGridPalette.background)
            .preferredColorScheme(.dark)
            .navigationTitle("Pin Counter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func pinRow(for counterID: CounterID) -> some View {
        Button {
            Task {
                if await store.pinCounter(counterID) {
                    dismiss()
                }
            }
        } label: {
            HStack {
                Text(counterName(counterID))
                    .foregroundStyle(LifeGridPalette.primaryText)
                Spacer()
                counterValueDisplay(for: counterID)
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(LifeGridPalette.secondaryText)
            }
        }
        .listRowBackground(LifeGridPalette.surface)
    }

    private func counterName(_ id: CounterID) -> String {
        switch id {
        case .builtIn(let builtIn): return builtIn.displayName
        case .custom(let uuid):
            return store.state.customCounters.first(where: { $0.id == uuid })?.name
                ?? "Custom"
        }
    }

    private func currentValue(_ id: CounterID) -> Int {
        store.state.activeGame?.counterValues[id, default: 0] ?? 0
    }

    @ViewBuilder
    private func counterValueDisplay(for id: CounterID) -> some View {
        if case .builtIn(let builtIn) = id, builtIn.isDayNight {
            Text(store.state.activeGame?.dayNightState.displayString ?? "Not Set")
        } else {
            Text("\(currentValue(id))")
        }
    }
}
