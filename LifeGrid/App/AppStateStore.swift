import Observation

@MainActor
@Observable
final class AppStateStore {
    private(set) var state: PersistedAppState
    private(set) var persistenceErrorDescription: String?
    private let environment: AppEnvironment

    init(
        environment: AppEnvironment,
        initialState: PersistedAppState = .default
    ) {
        self.environment = environment
        self.state = initialState
    }

    func load() async {
        do {
            state = try await environment.repository.load()
            persistenceErrorDescription = nil
        } catch {
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
        await mutateAndPersist { state in
            state.preferences.rememberLastSetup = rememberLastSetup
            state.activeGame = game
            if rememberLastSetup {
                state.lastSetup = setup
            }
        }
    }

    func setRememberLastSetup(_ enabled: Bool) async {
        await mutateAndPersist { state in
            state.preferences.rememberLastSetup = enabled
        }
    }

    func setDefaultStartingLife(_ value: Int) async {
        guard value > 0 else { return }
        await mutateAndPersist { state in
            state.preferences.defaultStartingLife = value
            state.lastSetup.startingLife = value
        }
    }

    func saveForLifecycle() async {
        await persistCurrentState()
    }

    private func mutateAndPersist(
        _ mutation: (inout PersistedAppState) -> Void
    ) async {
        mutation(&state)
        await persistCurrentState()
    }

    private func persistCurrentState() async {
        do {
            try await environment.repository.save(state)
            persistenceErrorDescription = nil
        } catch {
            persistenceErrorDescription = String(describing: error)
        }
    }
}
