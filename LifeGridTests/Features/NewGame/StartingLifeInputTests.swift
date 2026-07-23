import Testing
@testable import LifeGrid

@Suite(.serialized) struct StartingLifeInputTests {
    @Test(arguments: [20, 25, 30, 40, 60])
    func approvedPresetProducesValue(_ value: Int) {
        let input = StartingLifeInput(value: value)

        #expect(input.choice == .preset(value))
        #expect(input.value == value)
        #expect(input.validationMessage == nil)
    }

    @Test(arguments: ["1", "40", String(Int.max)])
    func positiveCustomWholeNumberIsValid(_ text: String) {
        var input = StartingLifeInput(value: 37)
        input.customText = text

        #expect(input.choice == .custom)
        #expect(input.value == Int(text))
        #expect(input.validationMessage == nil)
    }

    @Test(arguments: ["", "abc", "0", "-1", "1.5", "   ", "999999999999999999999999999999999999"])
    func invalidCustomValueIsRejected(_ text: String) {
        var input = StartingLifeInput(value: 37)
        input.customText = text

        #expect(input.value == nil)
        #expect(input.validationMessage == "Enter a positive whole number.")
    }

    @Test func switchingToPresetPreservesCustomDraft() {
        var input = StartingLifeInput(value: 37)

        input.choice = .preset(40)
        input.choice = .custom

        #expect(input.customText == "37")
        #expect(input.value == 37)
    }
}
