import SwiftUI



struct OpponentCard: View {
    @Bindable var store: AppStateStore
    let opponentID: UUID

    @State private var exactDamageText = ""
    @State private var exactDamageError: String?
    @State private var showsExactDamageEntry = false
    @State private var exactDamageIsPartner = false
    @State private var showsEditor = false

    var body: some View {
        if let opponent = currentOpponent {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(Self.displayName(for: opponent))
                        .font(.headline)
                        .lineLimit(2)

                    Spacer()

                    Button {
                        showsEditor = true
                    } label: {
                        Image(systemName: "pencil")
                            .font(.caption)
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Edit \(Self.displayName(for: opponent))")
                }

                HStack(spacing: 6) {
                    let isMonarch = store.state.activeGame?.currentMonarchPlayerID == PlayerID.opponent(opponent.id)
                    Button {
                        Task { await store.assignMonarch(to: isMonarch ? nil : PlayerID.opponent(opponent.id)) }
                    } label: {
                        StatusBadge(
                            label: "Monarch",
                            color: Color(red: 0.95, green: 0.75, blue: 0.25),
                            active: isMonarch
                        )
                    }
                    .buttonStyle(.plain)

                    Button {
                        Task { await store.toggleCitysBlessing(for: PlayerID.opponent(opponent.id)) }
                    } label: {
                        StatusBadge(
                            label: "City's Blessing",
                            color: LifeGridPalette.accent,
                            active: opponent.hasCitysBlessing
                        )
                    }
                    .buttonStyle(.plain)
                }

                Text("Commander Damage")
                    .font(.caption)
                    .foregroundStyle(LifeGridPalette.secondaryText)
                damageControls(for: opponent)

                if let partner = opponent.partner {
                    Divider().overlay(LifeGridPalette.border)
                    HStack {
                        Text(partner.name ?? "Partner")
                            .font(.caption)
                            .foregroundStyle(LifeGridPalette.secondaryText)
                        Spacer()
                        Button {
                            Task { await store.removeOpponentPartner(opponent.id) }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(LifeGridPalette.destructive)
                        }
                        .buttonStyle(.plain)
                    }
                    partnerDamageControls(for: opponent, partner: partner)
                } else {
                    Button {
                        Task { await store.addOpponentPartner(opponent.id) }
                    } label: {
                        Label("Add Partner", systemImage: "person.badge.plus")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(LifeGridPalette.accent)
                }
            }
            .foregroundStyle(LifeGridPalette.primaryText)
            .lifeGridCard()
            .sheet(isPresented: $showsExactDamageEntry) {
                exactDamageSheet(for: opponent)
            }
            .sheet(isPresented: $showsEditor) {
                OpponentEditor(store: store, opponent: opponent)
            }
        }
    }

    private var currentOpponent: OpponentState? {
        store.state.activeGame?.opponents.first(where: { $0.id == opponentID })
    }

    private func damageControls(for opponent: OpponentState) -> some View {
        let name = Self.displayName(for: opponent)
        let damage = opponent.primaryCommanderDamage

        return HStack(spacing: 0) {
            RepeatActionButton(
                accessibilityLabel: "Remove one commander damage from \(name)",
                accessibilityHint: "Hold to repeatedly remove commander damage",
                onInitial: {
                    _ = await store.changePrimaryCommanderDamage(for: opponentID, by: -1)
                },
                onRepeat: {
                    let result = await store.changePrimaryCommanderDamage(for: opponentID, by: -1)
                    if result.mutation != nil { await store.playHaptic(.adjustment) }
                }
            ) {
                Text("−")
                    .font(.title2)
                    .frame(maxWidth: .infinity, minHeight: 72)
            }

            Divider()
                .overlay(LifeGridPalette.border)
                .frame(height: 72)

            Button {
                openExactDamageEntry(for: opponent)
            } label: {
                Text("\(damage)")
                    .font(.largeTitle.bold().monospacedDigit())
                    .foregroundStyle(
                        damage >= 21
                            ? LifeGridPalette.destructive
                            : LifeGridPalette.primaryText
                    )
                    .frame(minWidth: 88, minHeight: 72)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Set \(name)'s commander damage")
            .accessibilityValue(
                damage >= 21 ? "\(damage), commander lethal" : "\(damage)"
            )
            .accessibilityHint("Opens exact commander damage entry")

            Divider()
                .overlay(LifeGridPalette.border)
                .frame(height: 72)

            RepeatActionButton(
                accessibilityLabel: "Add one commander damage from \(name)",
                accessibilityHint: "Hold to repeatedly add commander damage",
                onInitial: {
                    _ = await store.changePrimaryCommanderDamage(for: opponentID, by: 1)
                },
                onRepeat: {
                    let result = await store.changePrimaryCommanderDamage(for: opponentID, by: 1)
                    if result.mutation != nil { await store.playHaptic(.adjustment) }
                }
            ) {
                Text("+")
                    .font(.title2)
                    .frame(maxWidth: .infinity, minHeight: 72)
            }
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

    private func exactDamageSheet(for opponent: OpponentState) -> some View {
        NavigationStack {
            Form {
                TextField("Commander damage", text: $exactDamageText)
                    .keyboardType(.numberPad)

                if let exactDamageError {
                    Text(exactDamageError)
                        .font(.footnote)
                        .foregroundStyle(LifeGridPalette.destructive)
                        .accessibilityLabel(exactDamageError)
                }
            }
            .scrollContentBackground(.hidden)
            .background(LifeGridPalette.background)
            .preferredColorScheme(.dark)
            .accessibilityIdentifier(
                Self.exactDamageEntryIdentifier(for: opponentID)
            )
            .navigationTitle(exactDamageIsPartner ? "Set Partner Damage" : "Set Commander Damage")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        exactDamageError = nil
                        showsExactDamageEntry = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Set") {
                        Task {
                            await applyExactDamage()
                        }
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func openExactDamageEntry(for opponent: OpponentState) {
        exactDamageIsPartner = false
        exactDamageText = "\(opponent.primaryCommanderDamage)"
        exactDamageError = nil
        showsExactDamageEntry = true
    }

    @MainActor
    private func applyExactDamage() async {
        guard let value = Int(exactDamageText), value >= 0 else {
            exactDamageError = "Enter a non-negative whole-number commander damage value."
            return
        }
        guard let opponent = currentOpponent else {
            exactDamageError = "Opponent is no longer in this game."
            return
        }
        let currentDamage = exactDamageIsPartner
            ? opponent.partner?.damage ?? 0
            : opponent.primaryCommanderDamage
        guard currentDamage != value else {
            exactDamageError = nil
            showsExactDamageEntry = false
            return
        }
        let result: OpponentMutationResult<CommanderDamageChange>
        if exactDamageIsPartner {
            result = await store.setPartnerCommanderDamage(for: opponentID, to: value)
        } else {
            result = await store.setPrimaryCommanderDamage(for: opponentID, to: value)
        }
        switch result {
        case .persisted:
            exactDamageError = nil
            showsExactDamageEntry = false
        case .retainedInMemory:
            exactDamageError = Self.retainedInMemoryMessage
        case .rejected:
            exactDamageError = Self.exactDamageRejectionMessage(
                opponentExists: currentOpponent != nil
            )
        }
    }

    nonisolated static func exactDamageEntryIdentifier(
        for opponentID: UUID
    ) -> String {
        "opponent-damage-exact-entry-\(opponentID.uuidString.lowercased())"
    }

    nonisolated static func exactDamageRejectionMessage(
        opponentExists: Bool
    ) -> String {
        opponentExists
            ? "Commander damage could not be updated."
            : "Opponent is no longer in this game."
    }

    nonisolated static let retainedInMemoryMessage =
        "The change is kept for this session but could not be saved."

    nonisolated static func displayName(for opponent: OpponentState) -> String {
        let trimmed = opponent.displayName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        return trimmed.isEmpty ? "Opponent" : trimmed
    }

    private func partnerDamageControls(for opponent: OpponentState, partner: PartnerCommanderState) -> some View {
        let name = partner.name ?? "Partner"
        let damage = partner.damage

        return HStack(spacing: 0) {
            RepeatActionButton(
                accessibilityLabel: "Remove one partner damage from \(name)",
                accessibilityHint: "Hold to repeatedly remove partner damage",
                onInitial: {
                    await store.changePartnerCommanderDamage(for: opponentID, by: -1)
                },
                onRepeat: {
                    await store.changePartnerCommanderDamage(for: opponentID, by: -1)
                    await store.playHaptic(.adjustment)
                },
                onEnd: {}
            ) {
                Text("−")
                    .font(.title2)
                    .frame(maxWidth: .infinity, minHeight: 60)
            }

            Divider().overlay(LifeGridPalette.border).frame(height: 60)

            Button {
                exactDamageIsPartner = true
                exactDamageText = "\(damage)"
                exactDamageError = nil
                showsExactDamageEntry = true
            } label: {
                Text("\(damage)")
                    .font(.title2.bold().monospacedDigit())
                    .foregroundStyle(
                        damage >= 21 ? LifeGridPalette.destructive : LifeGridPalette.primaryText
                    )
                    .frame(minWidth: 72, minHeight: 60)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Set \(name)'s partner damage")
            .accessibilityValue(damage >= 21 ? "\(damage), lethal" : "\(damage)")

            Divider().overlay(LifeGridPalette.border).frame(height: 60)

            RepeatActionButton(
                accessibilityLabel: "Add one partner damage from \(name)",
                accessibilityHint: "Hold to repeatedly add partner damage",
                onInitial: {
                    await store.changePartnerCommanderDamage(for: opponentID, by: 1)
                },
                onRepeat: {
                    await store.changePartnerCommanderDamage(for: opponentID, by: 1)
                    await store.playHaptic(.adjustment)
                },
                onEnd: {}
            ) {
                Text("+")
                    .font(.title2)
                    .frame(maxWidth: .infinity, minHeight: 60)
            }
        }
        .background(LifeGridPalette.field, in: RoundedRectangle(cornerRadius: 9))
        .overlay {
            RoundedRectangle(cornerRadius: 9).stroke(LifeGridPalette.border)
        }
        .clipShape(RoundedRectangle(cornerRadius: 9))
    }
}
