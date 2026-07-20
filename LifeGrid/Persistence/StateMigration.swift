import Foundation

enum StateMigrationError: Error, Equatable {
    case unsupportedSchema(Int)
}

struct StateMigration: Sendable {
    func migrate(
        _ data: Data,
        decoder: JSONDecoder = .lifeGrid
    ) throws -> PersistedAppState {
        let schemaVersion = try decoder.decode(SchemaEnvelope.self, from: data).schemaVersion

        guard schemaVersion == PersistedAppState.currentSchemaVersion else {
            throw StateMigrationError.unsupportedSchema(schemaVersion)
        }

        return try decoder.decode(PersistedAppState.self, from: data)
    }
}

private struct SchemaEnvelope: Decodable {
    let schemaVersion: Int
}
