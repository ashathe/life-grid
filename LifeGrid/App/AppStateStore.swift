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
