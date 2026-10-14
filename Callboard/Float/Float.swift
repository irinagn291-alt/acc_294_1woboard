import Foundation

/// The house float. Each daykey owns an opening line. Till totals are the
/// sum of TillMarks for that daykey plus the opening, and are not stored.
struct HouseFloat: Codable, Equatable, Sendable {
    var lines: [FloatLine]

    init(lines: [FloatLine] = []) {
        self.lines = lines
    }

    func opening(for daykey: Int) -> Double {
        lines.first { $0.daykey == daykey }?.opening ?? 0
    }

    func balance(daykey: Int, tillMarks: [TillMark]) -> Double {
        let rung = tillMarks.filter { $0.daykey == daykey }.reduce(0) { $0 + $1.amount }
        return opening(for: daykey) + rung
    }
}

struct FloatLine: Codable, Equatable, Sendable, Identifiable {
    var id: UUID
    var daykey: Int
    var opening: Double

    init(id: UUID = UUID(), daykey: Int, opening: Double) {
        self.id = id
        self.daykey = daykey
        self.opening = opening
    }
}
