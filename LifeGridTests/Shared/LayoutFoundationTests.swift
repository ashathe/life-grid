import Testing
@testable import LifeGrid

@Suite(.serialized) struct LayoutFoundationTests {
    @Test func portraitPhoneUsesSingleColumn() {
        let context = GameLayoutContext(
            width: 390,
            height: 844,
            horizontalSizeClassIsRegular: false
        )

        #expect(GameLayoutMode.resolve(context) == .singleColumn)
    }

    @Test func landscapePhoneUsesTwoColumns() {
        let context = GameLayoutContext(
            width: 844,
            height: 390,
            horizontalSizeClassIsRegular: false
        )

        #expect(GameLayoutMode.resolve(context) == .twoColumn)
    }

    @Test func regularWidthUsesTwoColumns() {
        let context = GameLayoutContext(
            width: 1_024,
            height: 1_366,
            horizontalSizeClassIsRegular: true
        )

        #expect(GameLayoutMode.resolve(context) == .twoColumn)
    }

    @Test(arguments: AppScale.allCases)
    func everyScaleKeepsMinimumTouchTarget(_ scale: AppScale) {
        #expect(scale.metrics.minimumTouchTarget >= 44)
    }

    @Test func appScaleDoesNotEncodeDynamicType() {
        #expect(AppScale.allCases.map(\.metrics.spacingMultiplier) == [0.85, 1.0, 1.15])
        #expect(AppScale.allCases.map(\.metrics.minimumTouchTarget) == [44, 44, 44])
    }
}
