import Testing
@testable import LifeGrid

struct CommanderDamageChangeTests {
    @Test func valuePreservesDamageAndLifeBoundaries() {
        let change = CommanderDamageChange(
            previousDamage: 20,
            currentDamage: 21,
            previousLife: 23,
            currentLife: 22
        )

        #expect(change.previousDamage == 20)
        #expect(change.currentDamage == 21)
        #expect(change.previousLife == 23)
        #expect(change.currentLife == 22)
    }
}
