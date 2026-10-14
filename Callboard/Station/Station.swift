import Foundation

/// A foyer station on the floor fold. Health is never stored; marks on this
/// value are the only inputs StationHealth reads.
struct Station: Codable, Equatable, Sendable, Identifiable {
    var id: UUID
    var name: String
    /// Open until Cover folds it to Covered.
    var posture: StationPosture
    /// Day the station was placed. Age uses this when no maint mark exists.
    var placedDaykey: Int
    var incidents: [IncidentMark]
    var repairs: [RepairMark]
    var maints: [MaintMark]

    init(
        id: UUID = UUID(),
        name: String,
        posture: StationPosture = .open,
        placedDaykey: Int,
        incidents: [IncidentMark] = [],
        repairs: [RepairMark] = [],
        maints: [MaintMark] = []
    ) {
        self.id = id
        self.name = name
        self.posture = posture
        self.placedDaykey = placedDaykey
        self.incidents = incidents
        self.repairs = repairs
        self.maints = maints
    }
}

enum StationPosture: String, Codable, Equatable, Sendable {
    case open
    case covered
}

/// Saved incident drawing. The bytes are the slate; the count lowers health.
struct IncidentMark: Codable, Equatable, Sendable, Identifiable {
    var id: UUID
    var daykey: Int
    var drawing: Data

    init(id: UUID = UUID(), daykey: Int, drawing: Data) {
        self.id = id
        self.daykey = daykey
        self.drawing = drawing
    }
}

/// A repair logged against one station. Counted, not a stored health delta.
struct RepairMark: Codable, Equatable, Sendable, Identifiable {
    var id: UUID
    var daykey: Int

    init(id: UUID = UUID(), daykey: Int) {
        self.id = id
        self.daykey = daykey
    }
}

/// A maint mark. Today's marks are the recent-maint credit.
struct MaintMark: Codable, Equatable, Sendable, Identifiable {
    var id: UUID
    var daykey: Int

    init(id: UUID = UUID(), daykey: Int) {
        self.id = id
        self.daykey = daykey
    }
}
