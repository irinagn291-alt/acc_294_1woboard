import Foundation

/// A ring on a Covered station. The amount is the admission at that ring.
/// A day's till total is the sum of marks for that daykey, never a stored field.
struct TillMark: Codable, Equatable, Sendable, Identifiable {
    var id: UUID
    var stationID: UUID
    var daykey: Int
    var amount: Double
    var instant: Date

    init(
        id: UUID = UUID(),
        stationID: UUID,
        daykey: Int,
        amount: Double,
        instant: Date
    ) {
        self.id = id
        self.stationID = stationID
        self.daykey = daykey
        self.amount = amount
        self.instant = instant
    }
}
