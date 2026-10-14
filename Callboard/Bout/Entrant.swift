import Foundation

/// A name on the interleaved bracket. Identity is the id, not a list index.
struct Entrant: Codable, Equatable, Sendable, Identifiable {
    var id: UUID
    var name: String

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}
