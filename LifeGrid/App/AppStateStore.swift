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

    func saveForLifecycle() async {
        guard hasLoaded else { return }
        await persistCurrentState()
    }

    private func mutateAndPersist(
        onlyIf mutation: (inout PersistedAppState) -> Bool
    ) async -> Bool {
        guard await recoverPersistenceIfNeeded() else { return false }
        guard mutation(&state) else { return false }
        await persistCurrentState()
        return true
    }

    private func mutateAndPersist(
        _ mutation: (inout PersistedAppState) -> Void
    ) async {
        _ = await mutateAndPersist(onlyIf: { state in
            mutation(&state)
            return true
        })
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

    private func persistCurrentState() async {
        guard !persistenceIsBlocked else { return }

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
        guard revision == persistenceRevision else { return }
        switch outcome {
        case .success:
            persistenceErrorDescription = nil
        case .failure(let description):
            persistenceErrorDescription = description
        }
    }
}

private enum PersistenceOutcome: Sendable {
    case success
    case failure(String)
}
