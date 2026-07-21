import Foundation

struct AppEnvironment: Sendable {
    let repository: any AppStateRepository
    let randomSource: any RandomSource
    let clock: any ClockClient
    let haptics: any HapticsClient
    let sound: any SoundClient
    let uiTestingCommanderDisabled: Bool

    init(
        repository: any AppStateRepository,
        randomSource: any RandomSource,
        clock: any ClockClient,
        haptics: any HapticsClient,
        sound: any SoundClient,
        uiTestingCommanderDisabled: Bool = false
    ) {
        self.repository = repository
        self.randomSource = randomSource
        self.clock = clock
        self.haptics = haptics
        self.sound = sound
        self.uiTestingCommanderDisabled = uiTestingCommanderDisabled
    }

    static func live() -> AppEnvironment {
        let fileManager = FileManager.default
        let arguments = ProcessInfo.processInfo.arguments
        let applicationSupport = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]
        let stateDirectory = applicationSupport.appendingPathComponent(
            "Life Grid",
            isDirectory: true
        )

        if arguments.contains("--ui-testing-reset-state") {
            let snapshotURL = stateDirectory.appendingPathComponent(
                JSONAppStateRepository.fileName
            )
            try? fileManager.removeItem(at: snapshotURL)
        }

        return AppEnvironment(
            repository: JSONAppStateRepository(directoryURL: stateDirectory),
            randomSource: SystemRandomSource(),
            clock: SystemClockClient(),
            haptics: UIKitHapticsClient(),
            sound: NoOpSoundClient(),
            uiTestingCommanderDisabled: arguments.contains(
                "--ui-testing-commander-disabled"
            )
        )
    }
}
