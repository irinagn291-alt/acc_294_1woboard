import Foundation

/// A volunteer the house can clock onto a shift.
struct Staff: Codable, Equatable, Sendable, Identifiable {
    var id: UUID
    var name: String

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}
