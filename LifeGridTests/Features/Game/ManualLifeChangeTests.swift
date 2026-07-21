import Foundation
import Testing
@testable import LifeGrid

struct ManualLifeChangeTests {
    @Test func equalityIncludesNegativeCurrentValue() {
        let change = ManualLifeChange(previousValue: 40, currentValue: -1)

        #expect(change == ManualLifeChange(previousValue: 40, currentValue: -1))
        #expect(change != ManualLifeChange(previousValue: 40, currentValue: 0))
        #expect(change != ManualLifeChange(previousValue: 39, currentValue: -1))
    }

    @Test func replacementUndoOperationHasNewIdentityAndRestoreValue() {
        let firstOperationID = UUID(
            uuidString: "00000000-0000-0000-0000-000000000001"
        )!
        let replacementOperationID = UUID(
            uuidString: "00000000-0000-0000-0000-000000000002"
        )!
        let first = LocalLifeUndoState(
            restoreValue: 40,
            operationID: firstOperationID
        )
        let replacement = LocalLifeUndoState(
            restoreValue: -7,
            operationID: replacementOperationID
        )

        #expect(replacement.operationID != first.operationID)
        #expect(replacement.restoreValue == -7)
        #expect(replacement != first)
    }

    @Test func blankTrimmedPlayerNameDisplaysYou() {
        #expect(LocalLifeCard.displayName(for: " \n ") == "You")
    }

    @Test func nonemptyPlayerNameDisplaysTrimmedValue() {
        #expect(
            LocalLifeCard.displayName(for: "  Michi\n") == "Michi"
        )
    }
}
