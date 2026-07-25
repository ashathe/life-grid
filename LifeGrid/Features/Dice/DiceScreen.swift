import SwiftUI

struct DiceScreen: View {
    @Bindable var store: AppStateStore
    @State private var showsCustomDieEditor = false
    @State private var containerWidth: CGFloat = 0

    private var gridColumns: Int { max(2, Int(containerWidth / 180)) }

    private let builtInDice: [(sides: Int, label: String)] = [
        (4, "d4"), (6, "d6"), (8, "d8"),
        (10, "d10"), (12, "d12"), (20, "d20")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    CoinFlipView(store: store)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: gridColumns), spacing: 12) {
                        ForEach(builtInDice, id: \.sides) { die in
                            DiceRoller(
                                sides: die.sides,
                                label: die.label,
                                store: store
                            )
                        }

                        ForEach(store.state.savedDice) { die in
                            DiceRoller(
                                sides: die.sides,
                                label: "d\(die.sides)",
                                store: store
                            )
                            .overlay(alignment: .topTrailing) {
                                Button {
                                    Task { await store.deleteCustomDie(die.id) }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.caption)
                                        .foregroundStyle(LifeGridPalette.destructive)
                                }
                                .buttonStyle(.plain)
                                .padding(4)
                                .accessibilityLabel("Delete d\(die.sides)")
                            }
                        }
                    }

                    Button {
                        showsCustomDieEditor = true
                    } label: {
                        Label("Add Custom Die", systemImage: "plus")
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(LifeGridPalette.accent)

                    RandomPlayerPicker(store: store)

                    DiceHistoryView(store: store)
                }
                .frame(maxWidth: 560)
                .padding(12)
                .frame(maxWidth: .infinity)
            }
            .background(LifeGridPalette.background.ignoresSafeArea())
            .overlay {
                GeometryReader { geo in
                    Color.clear
                        .onAppear { containerWidth = geo.size.width }
                        .onChange(of: geo.size.width) { _, w in containerWidth = w }
                }
            }
            .foregroundStyle(LifeGridPalette.primaryText)
            .navigationTitle("Dice")
            .toolbarTitleDisplayMode(.inline)
            .sheet(isPresented: $showsCustomDieEditor) {
                SavedDieEditor(store: store)
            }
        }
    }
}
