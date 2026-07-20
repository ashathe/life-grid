import Foundation

struct AppEnvironment: Sendable {
    let repository: any AppStateRepository
    let randomSource: any RandomSource
    let clock: any ClockClient
    let haptics: any HapticsClient
    let sound: any SoundClient

    static func live() -> AppEnvironment {
        let fileManager = FileManager.default
        let applicationSupport = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]
        let stateDirectory = applicationSupport.appendingPathComponent(
            "Life Grid",
            isDirectory: true
        )

        if ProcessInfo.processInfo.arguments.contains("--ui-testing-reset-state") {
            let snapshotURL = stateDirectory.appendingPathComponent(
                JSONAppStateRepository.fileName
            )
            try? fileManager.removeItem(at: snapshotURL)
        }

        return AppEnvironment(
            repository: JSONAppStateRepository(directoryURL: stateDirectory),
            randomSource: SystemRandomSource(),
            clock: SystemClockClient(),
            haptics: NoOpHapticsClient(),
            sound: NoOpSoundClient()
        )
    }
}
