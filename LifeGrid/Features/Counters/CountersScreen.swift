import SwiftUI

struct CountersScreen: View {
    @Bindable var store: AppStateStore
    @State private var showsPinEditor = false
    @State private var showsCustomEditor = false

    private var game: ActiveGame? { store.state.activeGame }
    private var pinnedIDs: [CounterID] { game?.pinnedCounterIDs ?? [] }

    private let builtInOrder: [BuiltInCounterID] = [
        .poison, .energy, .experience, .treasure, .radiation,
        .storm, .charge, .doom, .tickets, .dayNight,
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Counters")
                            .font(.title2.bold())
                        Text("Track counters for the active game")
                            .font(.caption)
                            .foregroundStyle(LifeGridPalette.secondaryText)
                    }

                    if let game {
                        pinnedSection(game: game)
                        allCountersSection(game: game)
                    } else {
                        emptyState
                    }

                    customCountersSection
                }
                .frame(maxWidth: 560)
                .padding(16)
                .frame(maxWidth: .infinity)
            }
            .background(LifeGridPalette.background.ignoresSafeArea())
            .foregroundStyle(LifeGridPalette.primaryText)
            .sheet(isPresented: $showsPinEditor) {
                PinCounterSheet(store: store)
            }
            .sheet(isPresented: $showsCustomEditor) {
                CustomCounterEditor(store: store)
            }
        }
    }

    // MARK: - Pinned

    @ViewBuilder
    private func pinnedSection(game: ActiveGame) -> some View {
        if !pinnedIDs.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Pinned")
                        .font(.headline)
                    Spacer()
                    Button("Edit Pins") {
                        showsPinEditor = true
                    }
                    .font(.subheadline)
                    .foregroundStyle(LifeGridPalette.accent)
                }

                ForEach(pinnedIDs, id: \.self) { counterID in
                    CounterCard(
                        store: store,
                        counterID: counterID,
                        value: game.counterValues[counterID, default: 0],
                        label: counterLabel(for: counterID),
                        isDayNight: counterID == .builtIn(.dayNight),
                        dayNightState: game.dayNightState,
                        isPinned: true
                    )
                }
            }
            .lifeGridCard()
        }
    }

    // MARK: - All counters

    @ViewBuilder
    private func allCountersSection(game: ActiveGame) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("All Counters")
                .font(.headline)

            ForEach(builtInOrder, id: \.self) { builtIn in
                let counterID = CounterID.builtIn(builtIn)
                CounterCard(
                    store: store,
                    counterID: counterID,
                    value: game.counterValues[counterID, default: 0],
                    label: builtIn.label,
                    isDayNight: builtIn == .dayNight,
                    dayNightState: game.dayNightState,
                    isPinned: pinnedIDs.contains(counterID)
                )
            }

            if !store.state.customCounters.isEmpty {
                ForEach(store.state.customCounters) { custom in
                    let counterID = CounterID.custom(custom.id)
                    CounterCard(
                        store: store,
                        counterID: counterID,
                        value: game.counterValues[counterID, default: 0],
                        label: custom.name,
                        isDayNight: false,
                        dayNightState: game.dayNightState,
                        isPinned: pinnedIDs.contains(counterID)
                    )
                }
            }
        }
        .lifeGridCard()
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 10) {
            Text("No active game")
                .font(.headline)
            Text("Start a new game to track counters")
                .font(.subheadline)
                .foregroundStyle(LifeGridPalette.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .lifeGridCard()
    }

    // MARK: - Custom counters

    @ViewBuilder
    private var customCountersSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Custom Counters")
                .font(.headline)

            if store.state.customCounters.isEmpty {
                Text("No custom counters yet")
                    .font(.subheadline)
                    .foregroundStyle(LifeGridPalette.secondaryText)
            } else {
                ForEach(store.state.customCounters) { custom in
                    HStack {
                        Text(custom.name)
                            .font(.body)
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }

            Button {
                showsCustomEditor = true
            } label: {
                Label("Add Custom Counter", systemImage: "plus")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.bordered)
            .tint(LifeGridPalette.accent)
        }
        .lifeGridCard()
    }

    // MARK: - Helpers

    private func counterLabel(for counterID: CounterID) -> String {
        switch counterID {
        case .builtIn(let builtIn):
            return builtIn.label
        case .custom(let uuid):
            return store.state.customCounters.first(where: { $0.id == uuid })?.name ?? "Custom"
        }
    }
}

extension BuiltInCounterID {
    var label: String {
        switch self {
        case .poison: return "Poison"
        case .energy: return "Energy"
        case .experience: return "Experience"
        case .treasure: return "Treasure"
        case .radiation: return "Radiation"
        case .storm: return "Storm"
        case .charge: return "Charge"
        case .doom: return "Doom"
        case .tickets: return "Tickets"
        case .dayNight: return "Day/Night"
        }
    }
}
