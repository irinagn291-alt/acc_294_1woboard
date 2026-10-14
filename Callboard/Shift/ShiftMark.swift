import Foundation

/// Append-only clock edge. daykey is YYYYMMDD from Calendar startOfDay.
struct ShiftMark: Codable, Equatable, Sendable, Identifiable {
    var id: UUID
    var shiftID: UUID
    var staffID: UUID
    var edge: ShiftEdge
    var daykey: Int
    var instant: Date

    init(
        id: UUID = UUID(),
        shiftID: UUID,
        staffID: UUID,
        edge: ShiftEdge,
        daykey: Int,
        instant: Date
    ) {
        self.id = id
        self.shiftID = shiftID
        self.staffID = staffID
        self.edge = edge
        self.daykey = daykey
        self.instant = instant
    }
}

enum ShiftEdge: String, Codable, Equatable, Sendable {
    case clockIn
    case clockOut
}
