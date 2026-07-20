import Foundation

actor JSONAppStateRepository: AppStateRepository {
    static let fileName = "life-grid-state.json"

    private let directoryURL: URL
    private let migration: StateMigration

    init(migration: StateMigration = StateMigration()) {
        let applicationSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]
        self.directoryURL = applicationSupport.appendingPathComponent(
            "Life Grid",
            isDirectory: true
        )
        self.migration = migration
    }

    init(directoryURL: URL, migration: StateMigration = StateMigration()) {
        self.directoryURL = directoryURL
        self.migration = migration
    }

    func load() throws -> PersistedAppState {
        let snapshotURL = directoryURL.appendingPathComponent(Self.fileName)

        guard FileManager.default.fileExists(atPath: snapshotURL.path) else {
            return .default
        }

        return try migration.migrate(Data(contentsOf: snapshotURL))
    }

    func save(_ state: PersistedAppState) throws {
        guard state.schemaVersion == PersistedAppState.currentSchemaVersion else {
            throw StateMigrationError.unsupportedSchema(state.schemaVersion)
        }

        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )
        let data = try JSONEncoder.lifeGrid.encode(state)
        let snapshotURL = directoryURL.appendingPathComponent(Self.fileName)
        try data.write(to: snapshotURL, options: .atomic)
    }
}
