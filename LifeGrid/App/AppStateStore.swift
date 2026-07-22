import Foundation
import Observation

@MainActor
@Observable
final class AppStateStore {
    private(set) var state: PersistedAppState
    private(set) var persistenceErrorDescription: String?
    private(set) var hasLoaded = false
    private let environment: AppEnvironment
    private var persistenceIsBlocked = false
    private var recoveryTask: Task<Bool, Never>?
    private var persistenceRevision = 0
    private var persistenceTail: Task<PersistenceOutcome, Never>?

    init(
        environment: AppEnvironment,
        initialState: PersistedAppState = .default
    ) {
        self.environment = environment
        self.state = initialState
    }

    func load() async {
        defer { hasLoaded = true }
        do {
            state = try await environment.repository.load()
            if environment.uiTestingCommanderDisabled {
                state.preferences.commanderEnabled = false
            }
            persistenceIsBlocked = false
            persistenceErrorDescription = nil
        } catch {
            persistenceIsBlocked = true
            persistenceErrorDescription = String(describing: error)
        }
    }

    func applyFoundationMutation(
        _ mutation: (inout PersistedAppState) -> Void
    ) async {
        await mutateAndPersist(mutation)
    }

    func startGame(
        using setup: GameSetup,
        rememberLastSetup: Bool
    ) async {
        let startedAt = await environment.clock.now()
        let game = ActiveGameFactory.make(
            setup: setup,
            startedAt: startedAt
        )
        await mutateAndPersist({ state in
            state.preferences.rememberLastSetup = rememberLastSetup
            state.activeGame = game
            if rememberLastSetup {
                state.lastSetup = setup
            }
        })
    }

    func setRememberLastSetup(_ enabled: Bool) async {
        await mutateAndPersist({ state in
            state.preferences.rememberLastSetup = enabled
        })
    }

    func setDefaultStartingLife(_ value: Int) async {
        guard value > 0 else { return }
        await mutateAndPersist({ state in
            state.preferences.defaultStartingLife = value
            state.lastSetup.startingLife = value
        })
    }

    @discardableResult
    func changeLocalLife(by amount: Int) async -> ManualLifeChange? {
        guard state.activeGame != nil else { return nil }

        var change: ManualLifeChange?
        let didMutate = await mutateAndPersist(onlyIf: { state in
            guard var game = state.activeGame else { return false }
            let previousValue = game.currentLife
            let result = previousValue.addingReportingOverflow(amount)
            guard !result.overflow else { return false }

            game.currentLife = result.partialValue
            state.activeGame = game
            change = ManualLifeChange(
                previousValue: previousValue,
                currentValue: result.partialValue
            )
            return true
        })
        return didMutate ? change : nil
    }

    @discardableResult
    func setLocalLife(to value: Int) async -> ManualLifeChange? {
        guard state.activeGame != nil else { return nil }

        var change: ManualLifeChange?
        let didMutate = await mutateAndPersist(onlyIf: { state in
            guard var game = state.activeGame else { return false }
            let previousValue = game.currentLife

            game.currentLife = value
            state.activeGame = game
            change = ManualLifeChange(
                previousValue: previousValue,
                currentValue: value
            )
            return true
        })
        return didMutate ? change : nil
    }

    func restoreLocalLife(to value: Int) async {
        guard state.activeGame != nil else { return }

        _ = await mutateAndPersist(onlyIf: { state in
            guard var game = state.activeGame else { return false }
            game.currentLife = value
            state.activeGame = game
            return true
        })
    }

    func playHaptic(_ event: HapticEvent) async {
        guard state.preferences.hapticsEnabled else { return }
        await environment.haptics.play(event)
    }

    func adjustLocalCommanderTax(
        _ slot: LocalCommanderTaxSlot,
        by amount: Int
    ) async {
        guard state.activeGame != nil else { return }

        _ = await mutateAndPersist(onlyIf: { state in
            guard var game = state.activeGame else { return false }
            let currentValue: Int
            switch slot {
            case .primary:
                currentValue = game.ownCommanderTaxA
            case .partner:
                currentValue = game.ownCommanderTaxB
            }

            let result = currentValue.addingReportingOverflow(amount)
            guard !result.overflow else { return false }
            let updatedValue = max(0, result.partialValue)

            switch slot {
            case .primary:
                game.ownCommanderTaxA = updatedValue
            case .partner:
                game.ownCommanderTaxB = updatedValue
            }
            state.activeGame = game
            return true
        })
    }

    @discardableResult
    func addOpponent() async -> OpponentMutationResult<OpponentState> {
        var added: OpponentState?
        let outcome = await mutateAndPersistWithOutcome(onlyIf: { state in
            guard var game = state.activeGame,
                  game.opponents.count < OpponentState.maximumCount else { return false }
            let opponent = OpponentState.newDefault(
                displayName: OpponentState.nextDefaultDisplayName(in: game.opponents)
            )
            game.opponents.append(opponent)
            state.activeGame = game
            added = opponent
            return true
        })
        return opponentMutationResult(for: added, outcome: outcome)
    }

    @discardableResult
    func changePrimaryCommanderDamage(
        for opponentID: UUID,
        by amount: Int
    ) async -> OpponentMutationResult<CommanderDamageChange> {
        guard amount != 0 else { return .rejected }
        return await updatePrimaryCommanderDamage(for: opponentID) { current in
            let result = current.addingReportingOverflow(amount)
            guard !result.overflow else { return nil }
            return max(0, result.partialValue)
        }
    }

    @discardableResult
    func setPrimaryCommanderDamage(
        for opponentID: UUID,
        to value: Int
    ) async -> OpponentMutationResult<CommanderDamageChange> {
        guard value >= 0 else { return .rejected }
        return await updatePrimaryCommanderDamage(for: opponentID) { _ in value }
    }

    func saveForLifecycle() async {
        guard hasLoaded else { return }
        _ = await persistCurrentState()
    }

    private func mutateAndPersist(
        onlyIf mutation: (inout PersistedAppState) -> Bool
    ) async -> Bool {
        await mutateAndPersistWithOutcome(onlyIf: mutation).didMutate
    }

    private func mutateAndPersist(
        _ mutation: (inout PersistedAppState) -> Void
    ) async {
        _ = await mutateAndPersist(onlyIf: { state in
            mutation(&state)
            return true
        })
    }

    private func updatePrimaryCommanderDamage(
        for opponentID: UUID,
        transform: (Int) -> Int?
    ) async -> OpponentMutationResult<CommanderDamageChange> {
        var change: CommanderDamageChange?
        let outcome = await mutateAndPersistWithOutcome(onlyIf: { state in
            guard var game = state.activeGame,
                  let opponentIndex = game.opponents.firstIndex(where: { $0.id == opponentID }) else {
                return false
            }

            let previousDamage = game.opponents[opponentIndex].primaryCommanderDamage
            guard let currentDamage = transform(previousDamage),
                  currentDamage != previousDamage else {
                return false
            }
            let damageDelta = currentDamage.subtractingReportingOverflow(previousDamage)
            guard !damageDelta.overflow else { return false }

            let previousLife = game.currentLife
            let currentLife: Int
            if state.preferences.commanderDamageChangesLife {
                let lifeResult = previousLife.subtractingReportingOverflow(damageDelta.partialValue)
                guard !lifeResult.overflow else { return false }
                currentLife = lifeResult.partialValue
            } else {
                currentLife = previousLife
            }

            game.opponents[opponentIndex].primaryCommanderDamage = currentDamage
            game.currentLife = currentLife
            state.activeGame = game
            change = CommanderDamageChange(
                previousDamage: previousDamage,
                currentDamage: currentDamage,
                previousLife: previousLife,
                currentLife: currentLife
            )
            return true
        })
        return opponentMutationResult(for: change, outcome: outcome)
    }

    private func mutateAndPersistWithOutcome(
        onlyIf mutation: (inout PersistedAppState) -> Bool
    ) async -> MutationPersistenceOutcome {
        guard await recoverPersistenceIfNeeded() else { return .rejected }
        guard mutation(&state) else { return .rejected }
        switch await persistCurrentState() {
        case .success:
            return .persisted
        case .failure:
            return .retainedInMemory
        }
    }

    private func opponentMutationResult<Value>(
        for value: Value?,
        outcome: MutationPersistenceOutcome
    ) -> OpponentMutationResult<Value> where Value: Equatable & Sendable {
        guard let value else { return .rejected }
        switch outcome {
        case .persisted:
            return .persisted(value)
        case .retainedInMemory:
            return .retainedInMemory(value)
        case .rejected:
            return .rejected
        }
    }

    private func recoverPersistenceIfNeeded() async -> Bool {
        guard persistenceIsBlocked else { return true }
        if let recoveryTask {
            return await recoveryTask.value
        }

        let repository = environment.repository
        let operation = Task<Bool, Never> { @MainActor in
            do {
                state = try await repository.load()
                persistenceIsBlocked = false
                persistenceErrorDescription = nil
                return true
            } catch {
                persistenceErrorDescription = String(describing: error)
                return false
            }
        }
        recoveryTask = operation
        let recovered = await operation.value
        recoveryTask = nil
        return recovered
    }

    private func persistCurrentState() async -> PersistenceOutcome {
        guard !persistenceIsBlocked else {
            return .failure(
                persistenceErrorDescription ?? "Persistence is unavailable."
            )
        }

        let snapshot = state
        let predecessor = persistenceTail
        let repository = environment.repository
        persistenceRevision += 1
        let revision = persistenceRevision
        let operation = Task<PersistenceOutcome, Never> {
            if let predecessor {
                _ = await predecessor.value
            }
            do {
                try await repository.save(snapshot)
                return .success
            } catch {
                return .failure(String(describing: error))
            }
        }
        persistenceTail = operation

        let outcome = await operation.value
        if revision == persistenceRevision {
            switch outcome {
            case .success:
                persistenceErrorDescription = nil
            case .failure(let description):
                persistenceErrorDescription = description
            }
        }
        return outcome
    }
}

private enum MutationPersistenceOutcome: Sendable {
    case rejected
    case persisted
    case retainedInMemory

    var didMutate: Bool {
        self != .rejected
    }
}

private enum PersistenceOutcome: Sendable {
    case success
    case failure(String)
}
