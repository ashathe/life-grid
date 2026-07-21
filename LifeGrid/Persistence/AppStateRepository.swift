protocol AppStateRepository: Sendable {
    func load() async throws -> PersistedAppState
    func save(_ state: PersistedAppState) async throws
}
