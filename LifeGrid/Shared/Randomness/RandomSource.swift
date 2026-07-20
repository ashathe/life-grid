protocol RandomSource: Sendable {
    func nextInt(in range: ClosedRange<Int>) async -> Int
}

struct SystemRandomSource: RandomSource {
    func nextInt(in range: ClosedRange<Int>) async -> Int {
        Int.random(in: range)
    }
}
