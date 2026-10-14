import Foundation

/// An open or closed volunteer duty. The house is OnShift while any shift
/// has no end instant.
struct Shift: Codable, Equatable, Sendable, Identifiable {
    var id: UUID
    var staffID: UUID
    var started: Date
    var ended: Date?

    init(id: UUID = UUID(), staffID: UUID, started: Date, ended: Date? = nil) {
        self.id = id
        self.staffID = staffID
        self.started = started
        self.ended = ended
    }

    var isOpen: Bool { ended == nil }
}
