import Foundation

/// An OnDeck winner. The bracket cursor moves to the next interleaved pair.
struct AdvanceMark: Codable, Equatable, Sendable, Identifiable {
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
