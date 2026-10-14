import Foundation

/// A ring on an Open station. Float does not move.
struct GapMark: Codable, Equatable, Sendable, Identifiable {
    var id: UUID
    var stationID: UUID
    var daykey: Int
    var instant: Date

    init(id: UUID = UUID(), stationID: UUID, daykey: Int, instant: Date) {
        self.id = id
        self.stationID = stationID
        self.daykey = daykey
        self.instant = instant
    }
}
