import Foundation

/// One bout. `order` is the power-of-two interleave. `cursor` is the start
/// of the current OnDeck pair (0, 2, 4, ...).
struct Bout: Codable, Equatable, Sendable, Identifiable {
    var id: UUID
    var title: String
    var order: [UUID]
    var cursor: Int

    init(id: UUID = UUID(), title: String, order: [UUID], cursor: Int = 0) {
        self.id = id
        self.title = title
        self.order = order
        self.cursor = cursor
    }

    var onDeck: [UUID] {
        guard cursor >= 0, cursor + 1 < order.count else { return [] }
        return [order[cursor], order[cursor + 1]]
    }

    var hasOnDeck: Bool { onDeck.count == 2 }
}
