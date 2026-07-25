import Foundation
@testable import LifeGrid

actor ScriptedRandomSource: RandomSource {
    private var values: [Int]

    init(_ values: [Int]) {
        self.values = values
    }

    func nextInt(in range: ClosedRange<Int>) -> Int {
        let value = values.removeFirst()
        precondition(range.contains(value))
        return value
    }
}

struct TestClock: ClockClient {
    let date: Date

    func now() async -> Date { date }
}

actor RecordingHapticsClient: HapticsClient {
    private var recordedEvents: [HapticEvent] = []

    func play(_ event: HapticEvent) {
        recordedEvents.append(event)
    }

    func events() -> [HapticEvent] { recordedEvents }
}

actor RecordingSoundClient: SoundClient {
    private var recordedEvents: [SoundEvent] = []

    func play(_ event: SoundEvent) {
        recordedEvents.append(event)
    }

    func events() -> [SoundEvent] { recordedEvents }
}

enum ScriptedRepositoryError: Error {
    case loadFailed
    case saveFailed
}

enum ScriptedLoadFailure: Sendable {
    case none
    case transient(calls: Set<Int>)
    case unsupportedSchema(Int)
}

actor ScriptedAppStateRepository: AppStateRepository {
    private let loadedState: PersistedAppState
    private let loadFailure: ScriptedLoadFailure
    private let failingSaveCalls: Set<Int>
    private var loadCallCount = 0
    private var saveCallCount = 0
    private var snapshots: [PersistedAppState] = []

    init(
        loadedState: PersistedAppState = .default,
        loadFailure: ScriptedLoadFailure = .none,
        failingSaveCalls: Set<Int> = []
    ) {
        self.loadedState = loadedState
        self.loadFailure = loadFailure
        self.failingSaveCalls = failingSaveCalls
    }

    // Legacy convenience init for existing tests
    convenience init(
        loadedState: PersistedAppState = .default,
        shouldFailLoad: Bool = false,
        failingLoadCalls: Set<Int> = [],
        failingSaveCalls: Set<Int> = []
    ) {
        let loadFail: ScriptedLoadFailure = shouldFailLoad ? .transient(calls: failingLoadCalls.isEmpty ? Set([1]) : failingLoadCalls) : .none
        self.init(loadedState: loadedState, loadFailure: loadFail, failingSaveCalls: failingSaveCalls)
    }

    func load() throws -> PersistedAppState {
        loadCallCount += 1
        switch loadFailure {
        case .none:
            break
        case .transient(let calls):
            if calls.contains(loadCallCount) {
                throw ScriptedRepositoryError.loadFailed
            }
        case .unsupportedSchema(let version):
            throw StateMigrationError.unsupportedSchema(version)
        }
        return loadedState
    }

    func save(_ state: PersistedAppState) throws {
        saveCallCount += 1
        snapshots.append(state)
        if failingSaveCalls.contains(saveCallCount) {
            throw ScriptedRepositoryError.saveFailed
        }
    }

    func savedSnapshots() -> [PersistedAppState] { snapshots }
}

actor SuspendingFirstSaveAppStateRepository: AppStateRepository {
    private var saveCallCount = 0
    private var snapshots: [PersistedAppState] = []
    private var firstSaveRelease: CheckedContinuation<Void, Never>?
    private var firstSaveStartWaiters: [CheckedContinuation<Void, Never>] = []

    func load() -> PersistedAppState { .default }

    func save(_ state: PersistedAppState) async {
        saveCallCount += 1
        let call = saveCallCount

        if call == 1 {
            let waiters = firstSaveStartWaiters
            firstSaveStartWaiters.removeAll()
            waiters.forEach { $0.resume() }
            await withCheckedContinuation { continuation in
                firstSaveRelease = continuation
            }
        }

        snapshots.append(state)
    }

    func waitUntilFirstSaveStarts() async {
        guard saveCallCount == 0 else { return }
        await withCheckedContinuation { continuation in
            firstSaveStartWaiters.append(continuation)
        }
    }

    func releaseFirstSave() {
        firstSaveRelease?.resume()
        firstSaveRelease = nil
    }

    func savedSnapshots() -> [PersistedAppState] { snapshots }
}
