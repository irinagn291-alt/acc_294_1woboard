import Foundation

/// Written when Cover folds a station from Open to Covered at health >= 60.
struct CoverMark: Codable, Equatable, Sendable, Identifiable {
    var id: UUID
    var stationID: UUID
    var health: Int
    var instant: Date

    init(id: UUID = UUID(), stationID: UUID, health: Int, instant: Date) {
        self.id = id
        self.stationID = stationID
        self.health = health
        self.instant = instant
    }
}
