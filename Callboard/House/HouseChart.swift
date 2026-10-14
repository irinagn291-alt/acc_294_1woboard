import Foundation

/// One Codable chart root. schemaVersion starts at 1 and the decoder switches on it.
/// Screens never encode this themselves; HouseStore is the seam.
struct HouseChart: Codable, Equatable, Sendable {
    var schemaVersion: Int
    var writing: FloorWriting
    var phase: HousePhase
    var bracketPhase: BracketPhase
    var walkInAdmission: Double
    var onboardingComplete: Bool
    var stations: [Station]
    var staff: [Staff]
    var shifts: [Shift]
    var bouts: [Bout]
    var entrants: [Entrant]
    var float: HouseFloat
    var coverMarks: [CoverMark]
    var shiftMarks: [ShiftMark]
    var tillMarks: [TillMark]
    var gapMarks: [GapMark]
    var advanceMarks: [AdvanceMark]
    var faultMarks: [FaultMark]

    static let schema = 1

    static func bare(admission: Double = 12) -> HouseChart {
        HouseChart(
            schemaVersion: schema,
            writing: .bare,
            phase: .dark,
            bracketPhase: .idle,
            walkInAdmission: admission,
            onboardingComplete: false,
            stations: [],
            staff: [],
            shifts: [],
            bouts: [],
            entrants: [],
            float: HouseFloat(),
            coverMarks: [],
            shiftMarks: [],
            tillMarks: [],
            gapMarks: [],
            advanceMarks: [],
            faultMarks: []
        )
    }

    var isBare: Bool { writing == .bare || stations.isEmpty }

    static func decode(_ data: Data) -> HouseChart? {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        let probe: VersionProbe
        do {
            probe = try decoder.decode(VersionProbe.self, from: data)
        } catch {
            return nil
        }
        switch probe.schemaVersion {
        case schema:
            do {
                return try decoder.decode(HouseChart.self, from: data)
            } catch {
                return nil
            }
        default:
            return nil
        }
    }

    func encoded() -> Data? {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .useDefaultKeys
        do {
            return try encoder.encode(self)
        } catch {
            return nil
        }
    }
}

enum FloorWriting: String, Codable, Equatable, Sendable {
    case bare
    case occupied
}

enum HousePhase: String, Codable, Equatable, Sendable {
    case dark
    case onShift
    case live
}

enum BracketPhase: String, Codable, Equatable, Sendable {
    case idle
    case live
}

private struct VersionProbe: Decodable {
    var schemaVersion: Int
}

enum DemoHouse {
    static let frontID = seedID("A1000001-0000-4000-8000-000000000001")
    static let balconyID = seedID("A1000001-0000-4000-8000-000000000002")
    static let aisleID = seedID("A1000001-0000-4000-8000-000000000003")
    static let cloakID = seedID("A1000001-0000-4000-8000-000000000004")
    static let staffID = seedID("B2000001-0000-4000-8000-000000000001")
    static let reedID = seedID("C3000001-0000-4000-8000-000000000001")
    static let marlowID = seedID("C3000001-0000-4000-8000-000000000002")
    static let quinnID = seedID("C3000001-0000-4000-8000-000000000003")
    static let adlerID = seedID("C3000001-0000-4000-8000-000000000004")

    /// Happy path: one clocked shift, front station covered, first pair OnDeck, several rings.
    static func make(now: Date = Date()) -> HouseChart {
        var chart = HouseChart.bare()
        chart.staff = [Staff(id: staffID, name: "Nia Cole")]
        chart = FloorFold.placeStation(chart, name: "Front door", now: now)
        chart.stations[0].id = frontID
        chart = FloorFold.placeStation(chart, name: "Balcony", now: now)
        chart.stations[1].id = balconyID
        chart = FloorFold.placeStation(chart, name: "Side aisle", now: now)
        chart.stations[2].id = aisleID
        chart = FloorFold.placeStation(chart, name: "Cloak", now: now)
        chart.stations[3].id = cloakID
        guard case .wrote(let clocked) = FloorFold.clockIn(chart, staffID: staffID, now: now) else {
            return chart
        }
        chart = clocked
        guard case .wrote(let covered) = FloorFold.cover(chart, stationID: frontID, now: now) else {
            return chart
        }
        chart = covered
        let entrants = [
            Entrant(id: reedID, name: "Reed"),
            Entrant(id: marlowID, name: "Marlow"),
            Entrant(id: quinnID, name: "Quinn"),
            Entrant(id: adlerID, name: "Adler")
        ]
        guard case .wrote(let seeded) = FloorFold.seedBout(chart, title: "Late house", entrants: entrants, now: now) else {
            return chart
        }
        chart = seeded
        for _ in 0..<3 {
            guard case .wrote(let rung) = FloorFold.ring(chart, stationID: frontID, now: now) else {
                return chart
            }
            chart = rung
        }
        chart.onboardingComplete = true
        return chart
    }
}

/// Seed literals are fixed UUID strings written in this file.
private func seedID(_ value: String) -> UUID {
    if let parsed = UUID(uuidString: value) {
        return parsed
    }
    return UUID()
}
