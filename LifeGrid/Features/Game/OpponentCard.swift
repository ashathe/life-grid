import SwiftUI

struct OpponentCard: View {
    @Bindable var store: AppStateStore
    let opponentID: UUID

    @State private var exactDamageText = ""
    @State private var exactDamageError: String?
    @State private var showsExactDamageEntry = false

    var body: some View {
        if let opponent = currentOpponent {
            VStack(alignment: .leading, spacing: 12) {
                Text(Self.displayName(for: opponent))
                    .font(.headline)
                    .lineLimit(2)
                Text("Commander Damage")
                    .font(.caption)
                    .foregroundStyle(LifeGridPalette.secondaryText)
                damageControls(for: opponent)
            }
            .foregroundStyle(LifeGridPalette.primaryText)
            .lifeGridCard()
            .sheet(isPresented: $showsExactDamageEntry) {
                exactDamageSheet(for: opponent)
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
                    _ = await applyDamageDelta(-1)
                },
                onRepeat: {
                    if await applyDamageDelta(-1) {
                        await store.playHaptic(.adjustment)
                    }
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
            }
            .buttonStyle(.plain)
            .frame(minWidth: 44, minHeight: 44)
            .accessibilityLabel("Set \(name)'s commander damage")
            .accessibilityValue(
                damage >= 21 ? "\(damage), commander lethal" : "\(damage)"
            )
            .accessibilityHint("Opens exact commander damage entry")
            .accessibilityIdentifier("Set \(name)'s commander damage")

            Divider()
                .overlay(LifeGridPalette.border)
                .frame(height: 72)

            RepeatActionButton(
                accessibilityLabel: "Add one commander damage from \(name)",
                accessibilityHint: "Hold to repeatedly add commander damage",
                onInitial: {
                    _ = await applyDamageDelta(1)
                },
                onRepeat: {
                    if await applyDamageDelta(1) {
                        await store.playHaptic(.adjustment)
                    }
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
            .accessibilityIdentifier("opponent-damage-exact-entry")
            .navigationTitle("Set Commander Damage")
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
        guard let currentOpponent else {
            exactDamageError = "Opponent is no longer in this game."
            return
        }
        guard currentOpponent.primaryCommanderDamage != value else {
            exactDamageError = nil
            showsExactDamageEntry = false
            return
        }
        guard await store.setPrimaryCommanderDamage(for: opponentID, to: value) != nil else {
            exactDamageError = "Opponent is no longer in this game."
            return
        }
        exactDamageError = nil
        showsExactDamageEntry = false
    }

    @MainActor
    private func applyDamageDelta(_ amount: Int) async -> Bool {
        guard let change = await store.changePrimaryCommanderDamage(
            for: opponentID,
            by: amount
        ) else { return false }
        return change.currentDamage != change.previousDamage
    }

    nonisolated static func displayName(for opponent: OpponentState) -> String {
        let trimmed = opponent.displayName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        return trimmed.isEmpty ? "Opponent" : trimmed
    }
}
