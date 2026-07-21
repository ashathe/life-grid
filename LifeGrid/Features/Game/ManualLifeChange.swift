import Foundation
import Observation

struct ManualLifeChange: Equatable, Sendable {
    let previousValue: Int
    let currentValue: Int
}

struct LocalLifeUndoState: Equatable, Sendable {
    let restoreValue: Int
    let operationID: UUID
}

enum LocalCommanderTaxSlot: Equatable, Sendable {
    case primary
    case partner
}

@MainActor
@Observable
final class LocalLifeInteractionController {
    typealias Sleep = @Sendable (Duration) async throws -> Void

    private(set) var undoState: LocalLifeUndoState?
    @ObservationIgnored private let sleep: Sleep
    @ObservationIgnored private var undoCancellationTask: Task<Void, Never>?
    @ObservationIgnored private var heldOperationRestoreValue: Int?

    init(
        sleep: @escaping Sleep = { duration in
            try await Task.sleep(for: duration)
        }
    ) {
        self.sleep = sleep
    }

    func applyManualDelta(
        _ amount: Int,
        to store: AppStateStore
    ) async {
        guard let change = await store.changeLocalLife(by: amount) else {
            return
        }
        if heldOperationRestoreValue == nil {
            heldOperationRestoreValue = change.previousValue
        }
    }

    func finishHeldOperation() {
        guard let restoreValue = heldOperationRestoreValue else {
            return
        }
        heldOperationRestoreValue = nil
        registerUndo(restoreValue: restoreValue)
    }

    func registerUndo(restoreValue: Int) {
        undoCancellationTask?.cancel()
        let operation = LocalLifeUndoState(
            restoreValue: restoreValue,
            operationID: UUID()
        )
        undoState = operation
        scheduleUndoExpiration(matching: operation.operationID)
    }

    @discardableResult
    func undo(in store: AppStateStore) async -> Bool {
        guard let undoState else { return false }
        undoCancellationTask?.cancel()
        undoCancellationTask = nil
        self.undoState = nil
        await store.restoreLocalLife(to: undoState.restoreValue)
        return true
    }

    func cancel() {
        undoCancellationTask?.cancel()
        undoCancellationTask = nil
        undoState = nil
        heldOperationRestoreValue = nil
    }

    private func scheduleUndoExpiration(matching operationID: UUID) {
        let sleep = self.sleep
        undoCancellationTask = Task { @MainActor [weak self] in
            do {
                try await sleep(.seconds(4))
            } catch {
                return
            }
            guard let self, undoState?.operationID == operationID else {
                return
            }
            undoState = nil
            undoCancellationTask = nil
        }
    }
}
