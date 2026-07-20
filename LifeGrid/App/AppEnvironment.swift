struct AppEnvironment: Sendable {
    let repository: any AppStateRepository
    let randomSource: any RandomSource
    let clock: any ClockClient
    let haptics: any HapticsClient
    let sound: any SoundClient

    static func live() -> AppEnvironment {
        AppEnvironment(
            repository: JSONAppStateRepository(),
            randomSource: SystemRandomSource(),
            clock: SystemClockClient(),
            haptics: NoOpHapticsClient(),
            sound: NoOpSoundClient()
        )
    }
}
