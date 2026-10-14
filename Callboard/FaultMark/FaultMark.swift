import Foundation

/// Advance tapped an entrant who is not one of the two OnDeck names.
struct FaultMark: Codable, Equatable, Sendable, Identifiable {
    var id: UUID
    var boutID: UUID
    var entrantID: UUID
    var instant: Date

    init(id: UUID = UUID(), boutID: UUID, entrantID: UUID, instant: Date) {
        self.id = id
        self.boutID = boutID
        self.entrantID = entrantID
        self.instant = instant
    }
}
