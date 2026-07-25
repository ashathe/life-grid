import SwiftUI

struct CountersScreen: View {
    @Bindable var store: AppStateStore
    @State private var showsPinPicker = false
    @State private var showsCustomEditor = false
    @State private var renameTarget: CustomCounterDefinition?
    @State private var deleteTarget: CustomCounterDefinition?
    @State private var showsDeleteConfirmation = false
    @State private var containerWidth: CGFloat = 0

    private var gridColumns: Int { max(2, Int(containerWidth / 180)) }

    private var pinnedIDs: [CounterID] {
        store.state.activeGame?.pinnedCounterIDs ?? []
    }

    private var unpinnedBuiltInIDs: [CounterID] {
        BuiltInCounterID.allCases.map { .builtIn($0) }
            .filter { !pinnedIDs.contains($0) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if store.state.activeGame == nil {
                        noGameView
                    } else {
                        counterSections
                    }
                }
                .padding(12)
                .frame(maxWidth: 560)
            }
            .frame(maxWidth: .infinity)
            .background(LifeGridPalette.background.ignoresSafeArea())
            .overlay {
                GeometryReader { geo in
                    Color.clear
                        .onAppear { containerWidth = geo.size.width }
                        .onChange(of: geo.size.width) { _, w in containerWidth = w }
                }
            }
            .foregroundStyle(LifeGridPalette.primaryText)
            .navigationTitle("Counters")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    if store.state.activeGame != nil, pinnedIDs.count < 4 {
                        Button {
                            showsPinPicker = true
                        } label: {
                            Image(systemName: "pin.fill")
                        }
                        .accessibilityLabel("Pin a counter")
                        .accessibilityIdentifier("toolbar-pin-counter")
                    }
                    Button {
                        showsCustomEditor = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("New custom counter")
                    .accessibilityIdentifier("toolbar-add-custom")
                }
            }
            .sheet(isPresented: $showsPinPicker) {
                PinCounterSheet(store: store)
            }
            .sheet(isPresented: $showsCustomEditor) {
                CustomCounterEditor(mode: .create, store: store)
            }
            .sheet(item: $renameTarget) { counter in
                CustomCounterEditor(
                    mode: .rename(id: counter.id, currentName: counter.name),
                    store: store
                )
            }
            .alert("Delete Counter?", isPresented: $showsDeleteConfirmation, presenting: deleteTarget) { counter in
                Button("Delete", role: .destructive) {
                    Task { await store.deleteCustomCounter(counter.id) }
                }
                Button("Cancel", role: .cancel) {}
            } message: { counter in
                let pinned = pinnedIDs.contains(.custom(counter.id))
                let hasValue = (store.state.activeGame?.counterValues[.custom(counter.id)] ?? 0) != 0
                if pinned && hasValue {
                    Text("\"\(counter.name)\" is pinned and has a nonzero value. Deletion removes the pin, its current value, and the saved definition.")
                } else if pinned {
                    Text("\"\(counter.name)\" is pinned. Deletion removes the pin and deletes the saved definition.")
                } else if hasValue {
                    Text("\"\(counter.name)\" has a nonzero value. Deletion removes the current value and the saved definition.")
                } else {
                    Text("Delete the saved counter \"\(counter.name)\"?")
                }
            }
        }
    }

    private var noGameView: some View {
        ContentUnavailableView(
            "No Active Game",
            systemImage: "number",
            description: Text("Start a game to use counters.")
        )
    }

    private var counterSections: some View {
        VStack(alignment: .leading, spacing: 24) {
            if !pinnedIDs.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Pinned")
                        .font(.headline)
                        .padding(.horizontal, 4)

                    ForEach(pinnedIDs, id: \.self) { counterID in
                        HStack {
                            if case .builtIn(let builtIn) = counterID, builtIn.isDayNight {
                                DayNightCard(store: store)
                            } else {
                                CounterCard(
                                    name: counterName(counterID),
                                    counterID: counterID,
                                    store: store
                                )
                            }

                            Button {
                                Task { await store.unpinCounter(counterID) }
                            } label: {
                                Image(systemName: "pin.slash.fill")
                                    .font(.subheadline)
                                    .frame(width: 44, height: 44)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Unpin \(counterName(counterID))")
                        }
                    }
                }
            }

            if !unpinnedBuiltInIDs.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Counters")
                        .font(.headline)
                        .padding(.horizontal, 4)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: gridColumns), spacing: 12) {
                        ForEach(unpinnedBuiltInIDs, id: \.self) { counterID in
                            HStack(alignment: .top) {
                                if case .builtIn(let builtIn) = counterID, builtIn.isDayNight {
                                    DayNightCard(store: store)
                                } else {
                                    CounterCard(
                                        name: counterName(counterID),
                                        counterID: counterID,
                                        store: store
                                    )
                                }
                                if pinnedIDs.count < 4 {
                                    Button {
                                        Task { await store.pinCounter(counterID) }
                                    } label: {
                                        Image(systemName: "pin.fill")
                                            .font(.caption)
                                            .frame(width: 28, height: 28)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
            }

            if !store.state.customCounters.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Custom")
                        .font(.headline)
                        .padding(.horizontal, 4)

                    ForEach(store.state.customCounters) { custom in
                        let counterID = CounterID.custom(custom.id)
                        HStack(alignment: .top) {
                            CounterCard(
                                name: custom.name,
                                counterID: counterID,
                                store: store
                            )

                            VStack(spacing: 4) {
                                if pinnedIDs.count < 4, !pinnedIDs.contains(counterID) {
                                    Button {
                                        Task { await store.pinCounter(counterID) }
                                    } label: {
                                        Image(systemName: "pin.fill")
                                            .font(.subheadline)
                                            .frame(width: 36, height: 36)
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("Pin \(custom.name)")
                                } else if pinnedIDs.contains(counterID) {
                                    Button {
                                        Task { await store.unpinCounter(counterID) }
                                    } label: {
                                        Image(systemName: "pin.slash.fill")
                                            .font(.subheadline)
                                            .frame(width: 36, height: 36)
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("Unpin \(custom.name)")
                                }

                                Button {
                                    renameTarget = custom
                                } label: {
                                    Image(systemName: "pencil")
                                        .font(.caption)
                                        .frame(width: 36, height: 36)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Rename \(custom.name)")

                                Button {
                                    deleteTarget = custom
                                    showsDeleteConfirmation = true
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.caption)
                                        .foregroundStyle(LifeGridPalette.destructive)
                                        .frame(width: 36, height: 36)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Delete \(custom.name)")
                            }
                        }
                    }
                }
            }
        }
    }

    private func counterName(_ id: CounterID) -> String {
        switch id {
        case .builtIn(let builtIn): return builtIn.displayName
        case .custom(let uuid):
            return store.state.customCounters.first(where: { $0.id == uuid })?.name
                ?? "Custom"
        }
    }
}
