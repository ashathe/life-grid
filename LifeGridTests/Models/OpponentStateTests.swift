import Testing
@testable import LifeGrid

struct OpponentStateTests {
    @Test func nextDefaultNameUsesFirstUnusedCanonicalLabel() {
        let opponents = [
            OpponentState.newDefault(displayName: "Opponent 1"),
            OpponentState.newDefault(displayName: "Amanda"),
            OpponentState.newDefault(displayName: "Opponent 3"),
            OpponentState.newDefault(displayName: "opponent 2"),
        ]

        #expect(OpponentState.nextDefaultDisplayName(in: opponents) == "Opponent 2")
    }

    @Test func newDefaultOpponentHasOnlyPrimaryZeroState() {
        let opponent = OpponentState.newDefault(displayName: "Opponent 4")

        #expect(opponent.displayName == "Opponent 4")
        #expect(opponent.isVisible)
        #expect(opponent.primaryCommanderName == nil)
        #expect(opponent.primaryCommanderDamage == 0)
        #expect(opponent.partner == nil)
        #expect(!opponent.hasCitysBlessing)
    }
}
