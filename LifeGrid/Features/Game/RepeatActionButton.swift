import Observation
import SwiftUI

struct RepeatActionSchedule: Equatable, Sendable {
    let initialDelay: Duration
    let interval: Duration

    static let localLife = Self(
        initialDelay: .milliseconds(350),
        interval: .milliseconds(120)
    )
}

@MainActor
@Observable
final class RepeatActionDriver {
    typealias Sleep = @Sendable (Duration) async throws -> Void

    private let schedule: RepeatActionSchedule
    private let sleep: Sleep
    private var repeatTask: Task<Void, Never>?

    init(
        schedule: RepeatActionSchedule = .localLife,
        sleep: @escaping Sleep = { duration in
            try await Task.sleep(for: duration)
        }
    ) {
        self.schedule = schedule
        self.sleep = sleep
    }

    func begin(onRepeat: @escaping @MainActor @Sendable () -> Void) {
        guard repeatTask == nil else { return }
        repeatTask = Task { @MainActor [weak self] in
            guard let self else { return }
            await repeatUntilCancelled(onRepeat: onRepeat)
        }
    }

    func cancel() {
        repeatTask?.cancel()
        repeatTask = nil
    }

    private func repeatUntilCancelled(
        onRepeat: @escaping @MainActor @Sendable () -> Void
    ) async {
        do {
            try await sleep(schedule.initialDelay)
        } catch {
            return
        }

        while !Task.isCancelled {
            onRepeat()

            do {
                try await sleep(schedule.interval)
            } catch {
                return
            }
        }
    }
}

struct RepeatActionButton<Label: View>: View {
    private let accessibilityLabel: String
    private let accessibilityHint: String
    private let onInitial: @MainActor @Sendable () async -> Void
    private let onRepeat: @MainActor @Sendable () async -> Void
    private let onEnd: @MainActor @Sendable () async -> Void
    private let label: Label
    @State private var driver: RepeatActionDriver
    @State private var actionTail: Task<Void, Never>?

    init(
        accessibilityLabel: String,
        accessibilityHint: String,
        schedule: RepeatActionSchedule = .localLife,
        onInitial: @escaping @MainActor @Sendable () async -> Void,
        onRepeat: @escaping @MainActor @Sendable () async -> Void,
        onEnd: @escaping @MainActor @Sendable () async -> Void = {},
        @ViewBuilder label: () -> Label
    ) {
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityHint = accessibilityHint
        self.onInitial = onInitial
        self.onRepeat = onRepeat
        self.onEnd = onEnd
        self.label = label()
        _driver = State(initialValue: RepeatActionDriver(schedule: schedule))
    }

    var body: some View {
        Button {
            enqueue(onInitial)
        } label: {
            label
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.35)
                .onEnded { _ in
                    driver.begin(onRepeat: { enqueue(onRepeat) })
                }
        )
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
        .onDisappear {
            driver.cancel()
        }
    }

    private func enqueue(
        _ action: @escaping @MainActor @Sendable () async -> Void
    ) {
        let predecessor = actionTail
        actionTail = Task { @MainActor in
            if let predecessor {
                await predecessor.value
            }
            guard !Task.isCancelled else { return }
            await action()
        }
    }
}
