import Foundation
import Observation

@MainActor
@Observable
final class AppStateStore {
    private(set) var state: PersistedAppState
    private(set) var persistenceErrorDescription: String?
    private(set) var hasLoaded = false
    private let environment: AppEnvironment
    private var persistenceWriteBlockDescription: String?
    private var persistenceRevision = 0
    private var persistenceTail: Task<PersistenceOutcome, Never>?

    init(
        environment: AppEnvironment,
        initialState: PersistedAppState = .default
    ) {
        self.environment = environment
        self.state = initialState
    }

    func load() async {
        defer { hasLoaded = true }
        do {
            state = try await environment.repository.load()
            if environment.uiTestingCommanderDisabled {
                state.preferences.commanderEnabled = false
            }
            persistenceWriteBlockDescription = nil
            persistenceErrorDescription = nil
        } catch {
            let description = String(describing: error)
            persistenceErrorDescription = description
            if error is StateMigrationError {
                persistenceWriteBlockDescription = description
            } else {
                persistenceWriteBlockDescription = nil
            }
        }
    }

    func applyFoundationMutation(
        _ mutation: (inout PersistedAppState) -> Void
    ) async {
        await mutateAndPersist(mutation)
    }

    func startGame(
        using setup: GameSetup,
        rememberLastSetup: Bool
    ) async {
        let startedAt = await environment.clock.now()
        let game = ActiveGameFactory.make(
            setup: setup,
            startedAt: startedAt
        )
        await mutateAndPersist({ state in
            state.preferences.rememberLastSetup = rememberLastSetup
            state.activeGame = game
            if rememberLastSetup {
                state.lastSetup = setup
            }
        })
    }

    func setRememberLastSetup(_ enabled: Bool) async {
        await mutateAndPersist({ state in
            state.preferences.rememberLastSetup = enabled
        })
    }

    func setDefaultStartingLife(_ value: Int) async {
        guard value > 0 else { return }
        await mutateAndPersist({ state in
            state.preferences.defaultStartingLife = value
            state.lastSetup.startingLife = value
        })
    }

    func setPlayerName(_ name: String) async {
        await mutateAndPersist({ state in
            state.preferences.playerName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        })
    }

    func setCommanderEnabled(_ enabled: Bool) async {
        await mutateAndPersist({ state in state.preferences.commanderEnabled = enabled })
    }

    func setPartnerCommanderEnabled(_ enabled: Bool) async {
        await mutateAndPersist({ state in state.preferences.ownPartnerCommanderEnabled = enabled })
    }

    func setCommanderDamageLink(_ enabled: Bool) async {
        await mutateAndPersist({ state in state.preferences.commanderDamageChangesLife = enabled })
    }

    func setKeepScreenAwake(_ enabled: Bool) async {
        await mutateAndPersist({ state in state.preferences.keepScreenAwakeDuringGames = enabled })
    }

    func setHapticsEnabled(_ enabled: Bool) async {
        await mutateAndPersist({ state in state.preferences.hapticsEnabled = enabled })
    }

    func setSoundEffectsEnabled(_ enabled: Bool) async {
        await mutateAndPersist({ state in state.preferences.soundEffectsEnabled = enabled })
    }

    func setAppearance(_ mode: AppearanceMode) async {
        await mutateAndPersist({ state in state.preferences.appearance = mode })
    }

    func setAppScale(_ scale: AppScale) async {
        await mutateAndPersist({ state in state.preferences.appScale = scale })
    }

    func resetGame() async {
        guard state.activeGame != nil else { return }
        _ = await mutateAndPersist(onlyIf: { state in
            guard var game = state.activeGame else { return false }
            game.currentLife = state.lastSetup.startingLife
            game.ownCommanderTaxA = 0
            game.ownCommanderTaxB = 0
            game.counterValues = Dictionary(
                uniqueKeysWithValues: BuiltInCounterID.allCases
                    .filter { $0 != .dayNight }
                    .map { (CounterID.builtIn($0), 0) }
            )
            game.dayNightState = .notSet
            game.currentMonarchPlayerID = nil
            game.playerHasCitysBlessing = false
            for i in game.opponents.indices {
                game.opponents[i].primaryCommanderDamage = 0
                game.opponents[i].partner?.damage = 0
                game.opponents[i].hasCitysBlessing = false
                game.opponents[i].isVisible = true
            }
            state.activeGame = game
            return true
        })
    }

    @discardableResult
    func changeLocalLife(by amount: Int) async -> ManualLifeChange? {
        guard state.activeGame != nil else { return nil }

        var change: ManualLifeChange?
        let didMutate = await mutateAndPersist(onlyIf: { state in
            guard var game = state.activeGame else { return false }
            let previousValue = game.currentLife
            let result = previousValue.addingReportingOverflow(amount)
            guard !result.overflow else { return false }

            game.currentLife = result.partialValue
            state.activeGame = game
            change = ManualLifeChange(
                previousValue: previousValue,
                currentValue: result.partialValue
            )
            return true
        })
        return didMutate ? change : nil
    }

    @discardableResult
    func setLocalLife(to value: Int) async -> ManualLifeChange? {
        guard state.activeGame != nil else { return nil }

        var change: ManualLifeChange?
        let didMutate = await mutateAndPersist(onlyIf: { state in
            guard var game = state.activeGame else { return false }
            let previousValue = game.currentLife

            game.currentLife = value
            state.activeGame = game
            change = ManualLifeChange(
                previousValue: previousValue,
                currentValue: value
            )
            return true
        })
        return didMutate ? change : nil
    }

    func restoreLocalLife(to value: Int) async {
        guard state.activeGame != nil else { return }

        _ = await mutateAndPersist(onlyIf: { state in
            guard var game = state.activeGame else { return false }
            game.currentLife = value
            state.activeGame = game
            return true
        })
    }

    func playHaptic(_ event: HapticEvent) async {
        guard state.preferences.hapticsEnabled else { return }
        await environment.haptics.play(event)
    }

    func adjustLocalCommanderTax(
        _ slot: LocalCommanderTaxSlot,
        by amount: Int
    ) async {
        guard state.activeGame != nil else { return }

        _ = await mutateAndPersist(onlyIf: { state in
            guard var game = state.activeGame else { return false }
            let currentValue: Int
            switch slot {
            case .primary:
                currentValue = game.ownCommanderTaxA
            case .partner:
                currentValue = game.ownCommanderTaxB
            }

            let result = currentValue.addingReportingOverflow(amount)
            guard !result.overflow else { return false }
            let updatedValue = max(0, result.partialValue)

            switch slot {
            case .primary:
                game.ownCommanderTaxA = updatedValue
            case .partner:
                game.ownCommanderTaxB = updatedValue
            }
            state.activeGame = game
            return true
        })
    }

    @discardableResult
    func addOpponent() async -> OpponentMutationResult<OpponentState> {
        var added: OpponentState?
        let outcome = await mutateAndPersistWithOutcome(onlyIf: { state in
            guard var game = state.activeGame,
                  game.opponents.count < OpponentState.maximumCount else { return false }
            let opponent = OpponentState.newDefault(
                displayName: OpponentState.nextDefaultDisplayName(in: game.opponents)
            )
            game.opponents.append(opponent)
            state.activeGame = game
            added = opponent
            return true
        })
        return opponentMutationResult(for: added, outcome: outcome)
    }

    func removeLastOpponent() async {
        guard state.activeGame != nil else { return }
        _ = await mutateAndPersist(onlyIf: { state in
            guard var game = state.activeGame,
                  let removed = game.opponents.last else { return false }
            if game.currentMonarchPlayerID == PlayerID.opponent(removed.id) {
                game.currentMonarchPlayerID = nil
            }
            game.counterValues.removeValue(forKey: CounterID.custom(removed.id))
            game.opponents.removeLast()
            state.activeGame = game
            return true
        })
    }

    func renameOpponent(_ id: UUID, to name: String) async {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard state.activeGame != nil else { return }
        _ = await mutateAndPersist(onlyIf: { state in
            guard var game = state.activeGame,
                  let index = game.opponents.firstIndex(where: { $0.id == id }) else {
                return false
            }
            game.opponents[index].displayName = trimmed.isEmpty
                ? "Opponent \(index + 1)"
                : trimmed
            state.activeGame = game
            return true
        })
    }

    func setOpponentPartnerName(_ opponentID: UUID, name: String) async {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard state.activeGame != nil else { return }
        _ = await mutateAndPersist(onlyIf: { state in
            guard var game = state.activeGame,
                  let index = game.opponents.firstIndex(where: { $0.id == opponentID }) else {
                return false
            }
            let partnerName: String? = trimmed.isEmpty ? nil : trimmed
            if game.opponents[index].partner != nil {
                game.opponents[index].partner?.name = partnerName
            } else {
                game.opponents[index].partner = PartnerCommanderState(name: partnerName, damage: 0)
            }
            state.activeGame = game
            return true
        })
    }

    @discardableResult
    func changePrimaryCommanderDamage(
        for opponentID: UUID,
        by amount: Int
    ) async -> OpponentMutationResult<CommanderDamageChange> {
        guard amount != 0 else { return .rejected }
        return await updatePrimaryCommanderDamage(for: opponentID) { current in
            let result = current.addingReportingOverflow(amount)
            guard !result.overflow else { return nil }
            return max(0, result.partialValue)
        }
    }

    @discardableResult
    func setPrimaryCommanderDamage(
        for opponentID: UUID,
        to value: Int
    ) async -> OpponentMutationResult<CommanderDamageChange> {
        guard value >= 0 else { return .rejected }
        return await updatePrimaryCommanderDamage(for: opponentID) { _ in value }
    }

    @discardableResult
    func changePartnerCommanderDamage(
        for opponentID: UUID,
        by amount: Int
    ) async -> OpponentMutationResult<CommanderDamageChange> {
        guard amount != 0 else { return .rejected }
        return await updatePartnerCommanderDamage(for: opponentID) { current in
            let result = current.addingReportingOverflow(amount)
            guard !result.overflow else { return nil }
            return max(0, result.partialValue)
        }
    }

    @discardableResult
    func setPartnerCommanderDamage(
        for opponentID: UUID,
        to value: Int
    ) async -> OpponentMutationResult<CommanderDamageChange> {
        guard value >= 0 else { return .rejected }
        return await updatePartnerCommanderDamage(for: opponentID) { _ in value }
    }

    func addOpponentPartner(_ opponentID: UUID) async {
        guard state.activeGame != nil else { return }
        _ = await mutateAndPersist(onlyIf: { state in
            guard var game = state.activeGame,
                  let index = game.opponents.firstIndex(where: { $0.id == opponentID }),
                  game.opponents[index].partner == nil else { return false }
            game.opponents[index].partner = PartnerCommanderState(name: nil, damage: 0)
            state.activeGame = game
            return true
        })
    }

    func removeOpponentPartner(_ opponentID: UUID) async {
        guard state.activeGame != nil else { return }
        _ = await mutateAndPersist(onlyIf: { state in
            guard var game = state.activeGame,
                  let index = game.opponents.firstIndex(where: { $0.id == opponentID }) else {
                return false
            }
            game.opponents[index].partner = nil
            state.activeGame = game
            return true
        })
    }

    @discardableResult
    func adjustCounter(_ id: CounterID, by amount: Int) async -> Bool {
        guard state.activeGame != nil else { return false }
        let didMutate = await mutateAndPersist(onlyIf: { state in
            guard var game = state.activeGame else { return false }
            let currentValue = game.counterValues[id, default: 0]
            let result = currentValue.addingReportingOverflow(amount)
            guard !result.overflow else { return false }
            let clamped = max(0, result.partialValue)
            guard clamped != currentValue else { return false }
            game.counterValues[id] = clamped
            state.activeGame = game
            return true
        })
        return didMutate
    }

    @discardableResult
    func setCounterValue(_ id: CounterID, to value: Int) async -> Bool {
        guard state.activeGame != nil, value >= 0 else { return false }
        let didMutate = await mutateAndPersist(onlyIf: { state in
            guard var game = state.activeGame else { return false }
            let currentValue = game.counterValues[id, default: 0]
            guard value != currentValue else { return false }
            game.counterValues[id] = value
            state.activeGame = game
            return true
        })
        return didMutate
    }

    func toggleDayNight() async {
        guard state.activeGame != nil else { return }
        _ = await mutateAndPersist(onlyIf: { state in
            guard var game = state.activeGame else { return false }
            switch game.dayNightState {
            case .notSet:
                game.dayNightState = .day
            case .day:
                game.dayNightState = .night
            case .night:
                game.dayNightState = .day
            }
            state.activeGame = game
            return true
        })
    }

    @discardableResult
    func addCustomCounter(name: String) async -> CustomCounterDefinition? {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        guard !state.customCounters.contains(where: { $0.hasNameCollision(with: trimmed) }) else { return nil }
        guard !BuiltInCounterID.allCases.contains(where: {
            $0.displayName.caseInsensitiveCompare(trimmed) == .orderedSame
        }) else { return nil }

        var created: CustomCounterDefinition?
        _ = await mutateAndPersist({ state in
            let definition = CustomCounterDefinition(
                id: UUID(),
                name: trimmed,
                createdAt: Date()
            )
            state.customCounters.append(definition)
            created = definition
        })
        return created
    }

    @discardableResult
    func renameCustomCounter(_ id: UUID, to name: String) async -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return false }
        guard !state.customCounters.contains(where: {
            $0.id != id && $0.hasNameCollision(with: trimmed)
        }) else { return false }

        let didMutate = await mutateAndPersist(onlyIf: { state in
            guard let index = state.customCounters.firstIndex(where: { $0.id == id }) else {
                return false
            }
            state.customCounters[index].name = trimmed
            return true
        })
        return didMutate
    }

    @discardableResult
    func deleteCustomCounter(_ id: UUID) async -> Bool {
        let didMutate = await mutateAndPersist(onlyIf: { state in
            guard let index = state.customCounters.firstIndex(where: { $0.id == id }) else {
                return false
            }
            state.customCounters.remove(at: index)
            if var game = state.activeGame {
                let counterID = CounterID.custom(id)
                game.pinnedCounterIDs.removeAll(where: { $0 == counterID })
                game.counterValues.removeValue(forKey: counterID)
                state.activeGame = game
            }
            return true
        })
        return didMutate
    }

    @discardableResult
    func pinCounter(_ id: CounterID) async -> Bool {
        guard state.activeGame != nil else { return false }
        let didMutate = await mutateAndPersist(onlyIf: { state in
            guard var game = state.activeGame,
                  game.pinnedCounterIDs.count < 4,
                  !game.pinnedCounterIDs.contains(id) else { return false }
            game.pinnedCounterIDs.append(id)
            state.activeGame = game
            return true
        })
        return didMutate
    }

    @discardableResult
    func unpinCounter(_ id: CounterID) async -> Bool {
        guard state.activeGame != nil else { return false }
        let didMutate = await mutateAndPersist(onlyIf: { state in
            guard var game = state.activeGame else { return false }
            let before = game.pinnedCounterIDs.count
            game.pinnedCounterIDs.removeAll(where: { $0 == id })
            guard game.pinnedCounterIDs.count != before else { return false }
            state.activeGame = game
            return true
        })
        return didMutate
    }

    @discardableResult
    func rollDice(sides: Int, count: Int) async -> DiceRollEntry? {
        guard (2...999).contains(sides), (1...100).contains(count) else { return nil }

        var results: [Int] = []
        for _ in 0..<count {
            results.append(await environment.randomSource.nextInt(in: 1...sides))
        }
        let total = results.reduce(0, +)
        let entry = DiceRollEntry(
            id: UUID(),
            timestamp: Date(),
            sides: sides,
            diceCount: count,
            individualResults: results,
            total: total
        )

        _ = await mutateAndPersist({ state in
            state.diceHistory.append(entry)
            if state.diceHistory.count > 5 {
                state.diceHistory = Array(state.diceHistory.suffix(5))
            }
        })
        return entry
    }

    @discardableResult
    func addCustomDie(sides: Int) async -> SavedDieDefinition? {
        guard (2...999).contains(sides) else { return nil }
        guard !state.savedDice.contains(where: { $0.sides == sides }) else { return nil }

        var created: SavedDieDefinition?
        _ = await mutateAndPersist({ state in
            let die = SavedDieDefinition(id: UUID(), sides: sides)
            state.savedDice.append(die)
            created = die
        })
        return created
    }

    @discardableResult
    func deleteCustomDie(_ id: UUID) async -> Bool {
        let didMutate = await mutateAndPersist(onlyIf: { state in
            guard state.savedDice.contains(where: { $0.id == id }) else { return false }
            state.savedDice.removeAll(where: { $0.id == id })
            return true
        })
        return didMutate
    }

    func pickRandomStartingPlayer() async -> String? {
        guard let game = state.activeGame else { return nil }
        var candidates: [String] = []
        let localName = LocalLifeCard.displayName(
            for: state.preferences.playerName
        )
        candidates.append(localName)
        candidates.append(
            contentsOf: game.opponents.filter(\.isVisible).map(\.displayName)
        )
        guard !candidates.isEmpty else { return nil }
        let index = await environment.randomSource.nextInt(in: 0...(candidates.count - 1))
        return candidates[index]
    }

    func pickRandomOpponent() async -> String? {
        guard let game = state.activeGame else { return nil }
        let candidates = game.opponents
            .filter(\.isVisible)
            .map(\.displayName)
        guard !candidates.isEmpty else { return nil }
        let index = await environment.randomSource.nextInt(in: 0...(candidates.count - 1))
        return candidates[index]
    }

    func flipCoin() async -> CoinFlipFace {
        let value = await environment.randomSource.nextInt(in: 0...1)
        return value == 0 ? .heads : .tails
    }

    func assignMonarch(to playerID: PlayerID?) async {
        guard state.activeGame != nil else { return }
        _ = await mutateAndPersist(onlyIf: { state in
            guard var game = state.activeGame else { return false }
            game.currentMonarchPlayerID = playerID
            state.activeGame = game
            return true
        })
    }

    @discardableResult
    func toggleCitysBlessing(for playerID: PlayerID) async -> Bool {
        guard state.activeGame != nil else { return false }
        let didMutate = await mutateAndPersist(onlyIf: { state in
            guard var game = state.activeGame else { return false }
            switch playerID {
            case .local:
                game.playerHasCitysBlessing.toggle()
            case .opponent(let id):
                guard let index = game.opponents.firstIndex(where: { $0.id == id }) else {
                    return false
                }
                game.opponents[index].hasCitysBlessing.toggle()
            }
            state.activeGame = game
            return true
        })
        return didMutate
    }

    func saveForLifecycle() async {
        guard hasLoaded else { return }
        _ = await persistCurrentState()
    }

    private func mutateAndPersist(
        onlyIf mutation: (inout PersistedAppState) -> Bool
    ) async -> Bool {
        await mutateAndPersistWithOutcome(onlyIf: mutation).didMutate
    }

    private func mutateAndPersist(
        _ mutation: (inout PersistedAppState) -> Void
    ) async {
        _ = await mutateAndPersist(onlyIf: { state in
            mutation(&state)
            return true
        })
    }

    private func updatePrimaryCommanderDamage(
        for opponentID: UUID,
        transform: (Int) -> Int?
    ) async -> OpponentMutationResult<CommanderDamageChange> {
        var change: CommanderDamageChange?
        let outcome = await mutateAndPersistWithOutcome(onlyIf: { state in
            guard var game = state.activeGame,
                  let opponentIndex = game.opponents.firstIndex(where: { $0.id == opponentID }) else {
                return false
            }

            let previousDamage = game.opponents[opponentIndex].primaryCommanderDamage
            guard let currentDamage = transform(previousDamage),
                  currentDamage != previousDamage else {
                return false
            }
            let damageDelta = currentDamage.subtractingReportingOverflow(previousDamage)
            guard !damageDelta.overflow else { return false }

            let previousLife = game.currentLife
            let currentLife: Int
            if state.preferences.commanderDamageChangesLife {
                let lifeResult = previousLife.subtractingReportingOverflow(damageDelta.partialValue)
                guard !lifeResult.overflow else { return false }
                currentLife = lifeResult.partialValue
            } else {
                currentLife = previousLife
            }

            game.opponents[opponentIndex].primaryCommanderDamage = currentDamage
            game.currentLife = currentLife
            state.activeGame = game
            change = CommanderDamageChange(
                previousDamage: previousDamage,
                currentDamage: currentDamage,
                previousLife: previousLife,
                currentLife: currentLife
            )
            return true
        })
        return opponentMutationResult(for: change, outcome: outcome)
    }

    private func updatePartnerCommanderDamage(
        for opponentID: UUID,
        transform: (Int) -> Int?
    ) async -> OpponentMutationResult<CommanderDamageChange> {
        var change: CommanderDamageChange?
        let outcome = await mutateAndPersistWithOutcome(onlyIf: { state in
            guard var game = state.activeGame,
                  let opponentIndex = game.opponents.firstIndex(where: { $0.id == opponentID }),
                  let partner = game.opponents[opponentIndex].partner else {
                return false
            }

            let previousDamage = partner.damage
            guard let currentDamage = transform(previousDamage),
                  currentDamage != previousDamage else {
                return false
            }
            let damageDelta = currentDamage.subtractingReportingOverflow(previousDamage)
            guard !damageDelta.overflow else { return false }

            let previousLife = game.currentLife
            let currentLife: Int
            if state.preferences.commanderDamageChangesLife {
                let lifeResult = previousLife.subtractingReportingOverflow(damageDelta.partialValue)
                guard !lifeResult.overflow else { return false }
                currentLife = lifeResult.partialValue
            } else {
                currentLife = previousLife
            }

            game.opponents[opponentIndex].partner?.damage = currentDamage
            game.currentLife = currentLife
            state.activeGame = game
            change = CommanderDamageChange(
                previousDamage: previousDamage,
                currentDamage: currentDamage,
                previousLife: previousLife,
                currentLife: currentLife
            )
            return true
        })
        return opponentMutationResult(for: change, outcome: outcome)
    }

    private func mutateAndPersistWithOutcome(
        onlyIf mutation: (inout PersistedAppState) -> Bool
    ) async -> MutationPersistenceOutcome {
        guard persistenceWriteBlockDescription == nil else { return .rejected }
        guard mutation(&state) else { return .rejected }
        switch await persistCurrentState() {
        case .success:
            return .persisted
        case .failure:
            return .retainedInMemory
        }
    }

    private func opponentMutationResult<Value>(
        for value: Value?,
        outcome: MutationPersistenceOutcome
    ) -> OpponentMutationResult<Value> where Value: Equatable & Sendable {
        guard let value else { return .rejected }
        switch outcome {
        case .persisted:
            return .persisted(value)
        case .retainedInMemory:
            return .retainedInMemory(value)
        case .rejected:
            return .rejected
        }
    }

    private func persistCurrentState() async -> PersistenceOutcome {
        guard persistenceWriteBlockDescription == nil else {
            return .failure(
                persistenceErrorDescription ?? "Persistence is unavailable."
            )
        }

        let snapshot = state
        let predecessor = persistenceTail
        let repository = environment.repository
        persistenceRevision += 1
        let revision = persistenceRevision
        let operation = Task<PersistenceOutcome, Never> {
            if let predecessor {
                _ = await predecessor.value
            }
            do {
                try await repository.save(snapshot)
                return .success
            } catch {
                return .failure(String(describing: error))
            }
        }
        persistenceTail = operation

        let outcome = await operation.value
        if revision == persistenceRevision {
            switch outcome {
            case .success:
                persistenceErrorDescription = nil
            case .failure(let description):
                persistenceErrorDescription = description
            }
        }
        return outcome
    }
}

private enum MutationPersistenceOutcome: Sendable {
    case rejected
    case persisted
    case retainedInMemory

    var didMutate: Bool {
        self != .rejected
    }
}

private enum PersistenceOutcome: Sendable {
    case success
    case failure(String)
}
