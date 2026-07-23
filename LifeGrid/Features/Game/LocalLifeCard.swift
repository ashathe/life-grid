import SwiftUI

struct LocalLifeCard: View {
    @Bindable var store: AppStateStore
    let game: ActiveGame

    @State private var exactLifeText = ""
    @State private var exactLifeError: String?
    @State private var showsExactLifeEntry = false
    @State private var lifeInteraction = LocalLifeInteractionController()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Text(localPlayerName)
                    .font(.headline)
                    .lineLimit(2)
                    .accessibilityLabel(localPlayerName)

                if game.currentMonarchPlayerID == .local {
                    StatusBadge(label: "Monarch", color: Color(red: 0.95, green: 0.75, blue: 0.25))
                } else {
                    Button {
                        Task { await store.assignMonarch(to: .local) }
                    } label: {
                        StatusBadge(label: "Monarch", color: Color(red: 0.95, green: 0.75, blue: 0.25), active: false)
                    }
                    .buttonStyle(.plain)
                }
                if game.playerHasCitysBlessing {
                    Button {
                        Task { await store.toggleCitysBlessing(for: .local) }
                    } label: {
                        StatusBadge(label: "City's Blessing", color: LifeGridPalette.accent)
                    }
                    .buttonStyle(.plain)
                } else {
                    Button {
                        Task { await store.toggleCitysBlessing(for: .local) }
                    } label: {
                        StatusBadge(label: "City's Blessing", color: LifeGridPalette.accent, active: false)
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                if lifeInteraction.undoState != nil {
                    Button("Undo") {
                        Task {
                            await lifeInteraction.undo(in: store)
                        }
                    }
                    .frame(minWidth: 44, minHeight: 44)
                    .accessibilityLabel("Undo life change")
                    .accessibilityHint("Restores the previous life total")
                    .accessibilityIdentifier("life-undo")
                }
            }

            lifeControls

            Text("Tap ±1 · Hold to repeat · Tap life total to set")
                .font(.caption)
                .foregroundStyle(LifeGridPalette.secondaryText)
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)

            if store.state.preferences.commanderEnabled {
                Divider().overlay(LifeGridPalette.border)
                commanderTaxRow

                if store.state.preferences.ownPartnerCommanderEnabled {
                    partnerTaxRow
                }

                partnerToggle
            }
        }
        .foregroundStyle(LifeGridPalette.primaryText)
        .lifeGridCard()
        .sheet(isPresented: $showsExactLifeEntry) {
            exactLifeSheet
        }
        .onDisappear {
            lifeInteraction.cancel()
        }
    }

    private var lifeControls: some View {
        HStack(spacing: 0) {
            RepeatActionButton(
                accessibilityLabel: "Remove one life",
                accessibilityHint: "Hold to repeatedly remove life",
                onInitial: {
                    await applyManualDelta(-1)
                },
                onRepeat: {
                    await applyManualDelta(-1)
                    await store.playHaptic(.adjustment)
                },
                onEnd: {
                    finishHeldOperation()
                }
            ) {
                Text("−")
                    .font(.title2)
                    .frame(maxWidth: .infinity, minHeight: 72)
            }
            .accessibilityIdentifier("life-decrement")

            Divider()
                .overlay(LifeGridPalette.border)
                .frame(height: 72)

            Button {
                exactLifeText = "\(currentLife)"
                exactLifeError = nil
                showsExactLifeEntry = true
            } label: {
                Text("\(currentLife)")
                    .font(.largeTitle.bold().monospacedDigit())
                    .frame(minWidth: 88, minHeight: 72)
            }
            .buttonStyle(.plain)
            .frame(minWidth: 44, minHeight: 44)
            .accessibilityLabel("Set life total")
            .accessibilityValue("\(currentLife)")
            .accessibilityHint("Opens exact life entry")
            .accessibilityIdentifier("life-total")

            Divider()
                .overlay(LifeGridPalette.border)
                .frame(height: 72)

            RepeatActionButton(
                accessibilityLabel: "Add one life",
                accessibilityHint: "Hold to repeatedly add life",
                onInitial: {
                    await applyManualDelta(1)
                },
                onRepeat: {
                    await applyManualDelta(1)
                    await store.playHaptic(.adjustment)
                },
                onEnd: {
                    finishHeldOperation()
                }
            ) {
                Text("+")
                    .font(.title2)
                    .frame(maxWidth: .infinity, minHeight: 72)
            }
            .accessibilityIdentifier("life-increment")
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

    private var commanderTaxRow: some View {
        HStack(spacing: 10) {
            Text("Commander Tax")
                .font(.subheadline.bold())

            Spacer()

            taxButton(
                title: "−2",
                identifier: "commander-tax-decrement",
                accessibilityLabel: "Decrease commander tax by two",
                amount: -2
            )

            Text("\(primaryCommanderTax)")
                .font(.headline.monospacedDigit())
                .frame(minWidth: 32)
                .accessibilityLabel("Commander tax")
                .accessibilityValue("\(primaryCommanderTax)")

            taxButton(
                title: "+2",
                identifier: "commander-tax-increment",
                accessibilityLabel: "Increase commander tax by two",
                amount: 2
            )
        }
    }

    private var exactLifeSheet: some View {
        NavigationStack {
            Form {
                TextField("Life total", text: $exactLifeText)
                    .keyboardType(.numbersAndPunctuation)

                if let exactLifeError {
                    Text(exactLifeError)
                        .font(.footnote)
                        .foregroundStyle(LifeGridPalette.destructive)
                        .accessibilityLabel(exactLifeError)
                }
            }
            .scrollContentBackground(.hidden)
            .background(LifeGridPalette.background)
            .preferredColorScheme(.dark)
            .accessibilityIdentifier("life-exact-entry")
            .navigationTitle("Set Life Total")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        exactLifeError = nil
                        showsExactLifeEntry = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Set") {
                        Task {
                            await applyExactLife()
                        }
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var localPlayerName: String {
        Self.displayName(for: store.state.preferences.playerName)
    }

    nonisolated static func displayName(for playerName: String) -> String {
        let trimmedName = playerName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        return trimmedName.isEmpty ? "You" : trimmedName
    }

    private var currentLife: Int {
        guard store.state.activeGame?.id == game.id else {
            return game.currentLife
        }
        return store.state.activeGame?.currentLife ?? game.currentLife
    }

    private var primaryCommanderTax: Int {
        guard store.state.activeGame?.id == game.id else {
            return game.ownCommanderTaxA
        }
        return store.state.activeGame?.ownCommanderTaxA
            ?? game.ownCommanderTaxA
    }

    private var partnerCommanderTax: Int {
        guard store.state.activeGame?.id == game.id else {
            return game.ownCommanderTaxB
        }
        return store.state.activeGame?.ownCommanderTaxB
            ?? game.ownCommanderTaxB
    }

    private var partnerTaxRow: some View {
        HStack(spacing: 10) {
            Text("Partner Tax")
                .font(.subheadline.bold())

            Spacer()

            taxButton(
                title: "−2",
                identifier: "partner-tax-decrement",
                accessibilityLabel: "Decrease partner commander tax by two",
                amount: -2,
                slot: .partner
            )

            Text("\(partnerCommanderTax)")
                .font(.headline.monospacedDigit())
                .frame(minWidth: 32)
                .accessibilityLabel("Partner commander tax")
                .accessibilityValue("\(partnerCommanderTax)")

            taxButton(
                title: "+2",
                identifier: "partner-tax-increment",
                accessibilityLabel: "Increase partner commander tax by two",
                amount: 2,
                slot: .partner
            )
        }
    }

    @MainActor
    private func applyManualDelta(_ amount: Int) async {
        await lifeInteraction.applyManualDelta(amount, to: store)
    }

    @MainActor
    private func applyExactLife() async {
        guard let value = Int(exactLifeText) else {
            exactLifeError = "Enter a whole-number life total."
            return
        }
        guard let change = await store.setLocalLife(to: value) else {
            return
        }

        exactLifeError = nil
        showsExactLifeEntry = false
        lifeInteraction.registerUndo(restoreValue: change.previousValue)
    }

    @MainActor
    private func finishHeldOperation() {
        lifeInteraction.finishHeldOperation()
    }

    private var partnerToggle: some View {
        HStack {
            if store.state.preferences.ownPartnerCommanderEnabled {
                Button {
                    Task { await store.setPartnerCommanderEnabled(false) }
                } label: {
                    Label("Remove Partner", systemImage: "xmark.circle.fill")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(LifeGridPalette.destructive)
            } else {
                Button {
                    Task { await store.setPartnerCommanderEnabled(true) }
                } label: {
                    Label("Add Partner", systemImage: "person.badge.plus")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(LifeGridPalette.accent)
            }
        }
        .padding(.top, 4)
    }

    private func taxButton(
        title: String,
        identifier: String,
        accessibilityLabel: String,
        amount: Int,
        slot: LocalCommanderTaxSlot = .primary
    ) -> some View {
        Button {
            Task {
                await store.adjustLocalCommanderTax(slot, by: amount)
            }
        } label: {
            Text(title)
                .font(.subheadline.monospacedDigit())
                .frame(width: 44, height: 44)
                .background(
                    LifeGridPalette.control,
                    in: RoundedRectangle(cornerRadius: 8)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(
            amount < 0
                ? "Keeps commander tax at zero or decreases it by two"
                : "Increases commander tax by two"
        )
        .accessibilityIdentifier(identifier)
    }
}

struct StatusBadge: View {
    let label: String
    let color: Color
    var active: Bool = true

    var body: some View {
        Text(label)
            .font(.caption2.bold())
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(active ? color.opacity(0.25) : LifeGridPalette.control)
            .foregroundStyle(active ? color : LifeGridPalette.secondaryText)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(active ? color.opacity(0.5) : Color.clear)
            }
    }
}
