import Foundation

protocol ClockClient: Sendable {
    func now() async -> Date
}

struct SystemClockClient: ClockClient {
    func now() async -> Date { Date() }
}
