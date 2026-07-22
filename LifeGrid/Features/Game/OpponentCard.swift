import SwiftUI

@MainActor
final class OpponentDamageInteractionController {
    private let store: AppStateStore
    private let opponentID: UUID
    private let amount: Int
    private let driver: RepeatActionDriver
    private var actionTail: Task<Void, Never>?

    init(
        store: AppStateStore,
        opponentID: UUID,
        amount: Int,
        schedule: RepeatActionSchedule = .localLife,
        sleep: RepeatActionDriver.Sleep? = nil
    ) {
        self.store = store
        self.opponentID = opponentID
        self.amount = amount
        if let sleep {
            self.driver = RepeatActionDriver(
                schedule: schedule,
                sleep: sleep
            )
        } else {
            self.driver = RepeatActionDriver(schedule: schedule)
        }
    }

    func begin() {
        driver.begin(
            onInitial: { [weak self] in
                self?.enqueue(isRepeat: false)
            },
            onRepeat: { [weak self] in
                self?.enqueue(isRepeat: true)
            }
        )
    }

    func end() {
        driver.end()
    }

    func gestureActivityChanged(from wasActive: Bool, to isActive: Bool) {
        driver.gestureActivityChanged(from: wasActive, to: isActive)
    }

    func cancel() {
        driver.cancel()
    }

    func waitForPendingActions() async {
        await actionTail?.value
    }

    private func enqueue(isRepeat: Bool) {
        let predecessor = actionTail
        actionTail = Task { @MainActor [weak self] in
            if let predecessor {
                await predecessor.value
            }
            guard let self else { return }
            let result = await store.changePrimaryCommanderDamage(
                for: opponentID,
                by: amount
            )
            guard result.mutation != nil, isRepeat else { return }
            await store.playHaptic(.adjustment)
        }
    }
}

private struct OpponentDamageRepeatButton<Label: View>: View {
    private let accessibilityLabel: String
    private let accessibilityHint: String
    private let label: Label
    @State private var interaction: OpponentDamageInteractionController
    @GestureState private var gestureIsActive = false

    init(
        store: AppStateStore,
        opponentID: UUID,
        amount: Int,
        accessibilityLabel: String,
        accessibilityHint: String,
        @ViewBuilder label: () -> Label
    ) {
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityHint = accessibilityHint
        self.label = label()
        _interaction = State(initialValue: OpponentDamageInteractionController(
            store: store,
            opponentID: opponentID,
            amount: amount
        ))
    }

    var body: some View {
        label
            .frame(minHeight: 44)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .updating($gestureIsActive) { _, isActive, _ in
                        isActive = true
                    }
                    .onChanged { _ in
                        interaction.begin()
                    }
            )
            .onChange(of: gestureIsActive) { wasActive, isActive in
                interaction.gestureActivityChanged(
                    from: wasActive,
                    to: isActive
                )
            }
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityHint(accessibilityHint)
            .onDisappear {
                interaction.cancel()
            }
    }
}

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
            OpponentDamageRepeatButton(
                store: store,
                opponentID: opponentID,
                amount: -1,
                accessibilityLabel: "Remove one commander damage from \(name)",
                accessibilityHint: "Hold to repeatedly remove commander damage"
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

            OpponentDamageRepeatButton(
                store: store,
                opponentID: opponentID,
                amount: 1,
                accessibilityLabel: "Add one commander damage from \(name)",
                accessibilityHint: "Hold to repeatedly add commander damage"
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
            .accessibilityIdentifier(
                Self.exactDamageEntryIdentifier(for: opponentID)
            )
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
        guard let opponentBeforeUpdate = currentOpponent else {
            exactDamageError = "Opponent is no longer in this game."
            return
        }
        guard opponentBeforeUpdate.primaryCommanderDamage != value else {
            exactDamageError = nil
            showsExactDamageEntry = false
            return
        }
        let result = await store.setPrimaryCommanderDamage(
            for: opponentID,
            to: value
        )
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
}
