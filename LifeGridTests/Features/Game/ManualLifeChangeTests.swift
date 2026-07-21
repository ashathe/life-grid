import Testing
@testable import LifeGrid

struct ManualLifeChangeTests {
    @Test func equalityIncludesNegativeCurrentValue() {
        let change = ManualLifeChange(previousValue: 40, currentValue: -1)

        #expect(change == ManualLifeChange(previousValue: 40, currentValue: -1))
        #expect(change != ManualLifeChange(previousValue: 40, currentValue: 0))
        #expect(change != ManualLifeChange(previousValue: 39, currentValue: -1))
    }
}
