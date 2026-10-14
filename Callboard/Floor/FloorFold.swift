import Foundation

/// House ADT fold. Clock, Cover, Ring, Seed, and Advance are the only writers.
/// A floor with no stations is Bare. Live requires OnShift, a covered front
/// station, and an OnDeck pair.
enum FloorFold {
    static func placeStation(
        _ chart: HouseChart,
        name: String,
        now: Date,
        calendar: Calendar = .current
    ) -> HouseChart {
        var chart = chart
        let daykey = DayKey.make(now, calendar: calendar)
        chart.stations.append(Station(name: name, placedDaykey: daykey))
        chart.writing = .occupied
        chart.float = opened(chart.float, daykey: daykey)
        return recompute(chart)
    }

    static func clockIn(
        _ chart: HouseChart,
        staffID: UUID,
        now: Date,
        calendar: Calendar = .current
    ) -> FoldResult {
        guard chart.staff.contains(where: { $0.id == staffID }) else {
            return .refused(.unknownStaff, chart)
        }
        var chart = chart
        let daykey = DayKey.make(now, calendar: calendar)
        let shift = Shift(staffID: staffID, started: now)
        chart.shifts.append(shift)
        chart.shiftMarks.append(
            ShiftMark(shiftID: shift.id, staffID: staffID, edge: .clockIn, daykey: daykey, instant: now)
        )
        chart.float = opened(chart.float, daykey: daykey)
        if chart.phase == .dark {
            chart.phase = .onShift
        }
        return .wrote(recompute(chart))
    }

    static func clockOut(
        _ chart: HouseChart,
        shiftID: UUID,
        now: Date,
        calendar: Calendar = .current
    ) -> FoldResult {
        guard let index = chart.shifts.firstIndex(where: { $0.id == shiftID && $0.isOpen }) else {
            return .refused(.noOpenShift, chart)
        }
        var chart = chart
        chart.shifts[index].ended = now
        let staffID = chart.shifts[index].staffID
        let daykey = DayKey.make(now, calendar: calendar)
        chart.shiftMarks.append(
            ShiftMark(shiftID: shiftID, staffID: staffID, edge: .clockOut, daykey: daykey, instant: now)
        )
        return .wrote(recompute(chart))
    }

    static func cover(
        _ chart: HouseChart,
        stationID: UUID,
        now: Date,
        calendar: Calendar = .current
    ) -> FoldResult {
        if chart.writing == .bare || chart.stations.isEmpty {
            return .refused(.bareFloor, chart)
        }
        if chart.phase == .dark {
            return .refused(.coverWhileDark, chart)
        }
        guard let index = chart.stations.firstIndex(where: { $0.id == stationID }) else {
            return .refused(.unknownStation, chart)
        }
        if chart.stations[index].posture == .covered {
            return .refused(.alreadyCovered, chart)
        }
        let today = DayKey.make(now, calendar: calendar)
        let health = StationHealth.score(chart.stations[index], today: today, calendar: calendar)
        if health < StationHealth.coverMinimum {
            return .refused(.healthBelowCover, chart)
        }
        var chart = chart
        chart.stations[index].posture = .covered
        chart.coverMarks.append(
            CoverMark(stationID: stationID, health: health, instant: now)
        )
        return .wrote(recompute(chart))
    }

    static func ring(
        _ chart: HouseChart,
        stationID: UUID,
        now: Date,
        calendar: Calendar = .current
    ) -> FoldResult {
        if chart.stations.isEmpty {
            var bare = chart
            bare.writing = .bare
            bare.phase = .dark
            return .refused(.bareFloor, bare)
        }
        guard let station = chart.stations.first(where: { $0.id == stationID }) else {
            return .refused(.unknownStation, chart)
        }
        var chart = chart
        let daykey = DayKey.make(now, calendar: calendar)
        chart.float = opened(chart.float, daykey: daykey)
        if station.posture == .covered {
            chart.tillMarks.append(
                TillMark(
                    stationID: stationID,
                    daykey: daykey,
                    amount: chart.walkInAdmission,
                    instant: now
                )
            )
        } else {
            chart.gapMarks.append(
                GapMark(stationID: stationID, daykey: daykey, instant: now)
            )
        }
        return .wrote(chart)
    }

    static func fileIncident(
        _ chart: HouseChart,
        stationID: UUID,
        drawing: Data,
        now: Date,
        calendar: Calendar = .current
    ) -> FoldResult {
        guard let index = chart.stations.firstIndex(where: { $0.id == stationID }) else {
            return .refused(.unknownStation, chart)
        }
        var chart = chart
        let daykey = DayKey.make(now, calendar: calendar)
        chart.stations[index].incidents.append(
            IncidentMark(daykey: daykey, drawing: drawing)
        )
        return .wrote(chart)
    }

    static func repair(
        _ chart: HouseChart,
        stationID: UUID,
        now: Date,
        calendar: Calendar = .current
    ) -> FoldResult {
        guard let index = chart.stations.firstIndex(where: { $0.id == stationID }) else {
            return .refused(.unknownStation, chart)
        }
        var chart = chart
        chart.stations[index].repairs.append(
            RepairMark(daykey: DayKey.make(now, calendar: calendar))
        )
        return .wrote(chart)
    }

    static func maintain(
        _ chart: HouseChart,
        stationID: UUID,
        now: Date,
        calendar: Calendar = .current
    ) -> FoldResult {
        guard let index = chart.stations.firstIndex(where: { $0.id == stationID }) else {
            return .refused(.unknownStation, chart)
        }
        var chart = chart
        chart.stations[index].maints.append(
            MaintMark(daykey: DayKey.make(now, calendar: calendar))
        )
        return .wrote(chart)
    }

    /// Interleaves entrants and folds the bracket from Idle to Live.
    static func seedBout(
        _ chart: HouseChart,
        title: String,
        entrants: [Entrant],
        now: Date
    ) -> FoldResult {
        guard let order = BracketSeed.interleaved(entrants) else {
            return .refused(.notPowerOfTwo, chart)
        }
        var chart = chart
        let fresh = entrants.filter { entrant in
            !chart.entrants.contains(where: { $0.id == entrant.id })
        }
        chart.entrants.append(contentsOf: fresh)
        let bout = Bout(title: title, order: order.map(\.id), cursor: 0)
        chart.bouts.append(bout)
        chart.bracketPhase = .live
        _ = now
        return .wrote(recompute(chart))
    }

    static func advance(
        _ chart: HouseChart,
        boutID: UUID,
        entrantID: UUID,
        now: Date
    ) -> FoldResult {
        guard let index = chart.bouts.firstIndex(where: { $0.id == boutID }) else {
            return .refused(.unknownBout, chart)
        }
        var chart = chart
        let deck = chart.bouts[index].onDeck
        if deck.contains(entrantID) {
            chart.advanceMarks.append(
                AdvanceMark(boutID: boutID, entrantID: entrantID, instant: now)
            )
            chart.bouts[index].cursor += 2
        } else {
            chart.faultMarks.append(
                FaultMark(boutID: boutID, entrantID: entrantID, instant: now)
            )
        }
        return .wrote(recompute(chart))
    }

    /// Previous daykey keeps its marks. The new daykey gets a fresh opening line.
    static func roll(
        _ chart: HouseChart,
        now: Date,
        calendar: Calendar = .current
    ) -> HouseChart {
        var chart = chart
        let daykey = DayKey.make(now, calendar: calendar)
        chart.float = opened(chart.float, daykey: daykey)
        return chart
    }

    static func recompute(_ chart: HouseChart) -> HouseChart {
        var chart = chart
        if chart.stations.isEmpty {
            chart.writing = .bare
            chart.phase = .dark
            return chart
        }
        chart.writing = .occupied
        let onDuty = chart.shifts.contains(where: \.isOpen)
        let frontCovered = chart.stations[0].posture == .covered
        let onDeck = chart.bouts.contains(where: \.hasOnDeck)
        if !onDuty {
            chart.phase = .dark
        } else if frontCovered && onDeck && chart.bracketPhase == .live {
            chart.phase = .live
        } else {
            chart.phase = .onShift
        }
        return chart
    }

    private static func opened(_ float: HouseFloat, daykey: Int) -> HouseFloat {
        var float = float
        if float.lines.contains(where: { $0.daykey == daykey }) {
            return float
        }
        float.lines.append(FloatLine(daykey: daykey, opening: 0))
        return float
    }
}

enum FoldResult: Equatable, Sendable {
    case wrote(HouseChart)
    case refused(FoldRefusal, HouseChart)
}

enum FoldRefusal: String, Equatable, Sendable {
    case bareFloor
    case coverWhileDark
    case healthBelowCover
    case alreadyCovered
    case unknownStation
    case unknownStaff
    case noOpenShift
    case unknownBout
    case notPowerOfTwo
}

/// Power-of-two seed interleave. The opening OnDeck pair is the first two slots.
enum BracketSeed {
    static func interleaved<T>(_ entrants: [T]) -> [T]? {
        let count = entrants.count
        guard count >= 2, count & (count - 1) == 0 else { return nil }
        return fold(entrants)
    }

    private static func fold<T>(_ entrants: [T]) -> [T] {
        if entrants.count <= 1 { return entrants }
        let half = entrants.count / 2
        let left = fold(Array(entrants[..<half]))
        let right = fold(Array(entrants[half...].reversed()))
        var mixed: [T] = []
        mixed.reserveCapacity(entrants.count)
        for index in left.indices {
            mixed.append(left[index])
            mixed.append(right[index])
        }
        return mixed
    }
}
