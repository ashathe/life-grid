import SwiftUI

struct PinCounterSheet: View {
    @Bindable var store: AppStateStore
    @Environment(\.dismiss) private var dismiss

    private var game: ActiveGame? { store.state.activeGame }
    private var pinnedIDs: [CounterID] { game?.pinnedCounterIDs ?? [] }

    private let builtInOrder: [BuiltInCounterID] = [
        .poison, .energy, .experience, .treasure, .radiation,
        .storm, .charge, .doom, .tickets, .dayNight,
    ]

    var body: some View {
        NavigationStack {
            List {
                Section("Built-in") {
                    ForEach(builtInOrder, id: \.self) { builtIn in
                        pinRow(for: .builtIn(builtIn), label: builtIn.label)
                    }
                }

                if !store.state.customCounters.isEmpty {
                    Section("Custom") {
                        ForEach(store.state.customCounters) { custom in
                            pinRow(for: .custom(custom.id), label: custom.name)
                        }
                    }
                }
            }
            .navigationTitle("Edit Pins")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .background(LifeGridPalette.background)
            .scrollContentBackground(.hidden)
        }
        .presentationDetents([.medium, .large])
    }

    private func pinRow(for counterID: CounterID, label: String) -> some View {
        let isPinned = pinnedIDs.contains(counterID)
        let atMax = pinnedIDs.count >= 4 && !isPinned

        return HStack {
            Text(label)
                .font(.body)
            Spacer()
            if isPinned {
                Button("Remove") {
                    Task { await store.unpinCounter(counterID) }
                }
                .font(.subheadline)
                .foregroundStyle(LifeGridPalette.destructive)
                .frame(minHeight: 44)
            } else {
                Button("Pin") {
                    Task { await store.pinCounter(counterID) }
                }
                .font(.subheadline)
                .foregroundStyle(LifeGridPalette.accent)
                .frame(minHeight: 44)
                .disabled(atMax)
            }
        }
        .foregroundStyle(isPinned ? LifeGridPalette.primaryText : LifeGridPalette.secondaryText)
    }
}
