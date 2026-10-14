import Foundation

/// Bundled titles for the bracket sheet when search is empty or the network fails.
enum LocalShelf {
    static let titles: [ShelfTitle] = [
        ShelfTitle(id: "local-north-window", title: "North Window Set"),
        ShelfTitle(id: "local-late-house", title: "Late House Reel"),
        ShelfTitle(id: "local-foyer-quiet", title: "Foyer Quiet"),
        ShelfTitle(id: "local-aisle-four", title: "Aisle Four"),
        ShelfTitle(id: "local-cloak-bell", title: "Cloak Bell"),
        ShelfTitle(id: "local-balcony-two", title: "Balcony Two"),
        ShelfTitle(id: "local-matinee", title: "Saturday Matinee"),
        ShelfTitle(id: "local-last-tram", title: "Last Tram")
    ]

    static func match(_ query: String) -> [ShelfTitle] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return titles }
        return titles.filter { $0.title.localizedStandardContains(trimmed) }
    }
}

struct ShelfTitle: Equatable, Sendable, Identifiable {
    var id: String
    var title: String
}
