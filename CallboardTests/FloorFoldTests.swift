import XCTest
@testable import Callboard

/// Family invariant: health = 100 - incidents - repairs - age penalties + recent maint.
/// Bracket: power-of-two seed interleave.
final class FloorFoldTests: XCTestCase {
    private var calendar: Calendar!

    override func setUp() {
        super.setUp()
        var gregorian = Calendar(identifier: .gregorian)
        if let zone = TimeZone(secondsFromGMT: 0) {
            gregorian.timeZone = zone
        }
        calendar = gregorian
    }

    func test_marksHealthIsSeparateFromWatchRateOLSandCOSC() {
        // This floor scores marks and age. It does not fit a daily rate, so OLS and COSC stay off the house.
        let today = DayKey.make(Date(), calendar: calendar)
        let score = StationHealth.score(Station(name: "Front", placedDaykey: today), today: today, calendar: calendar)
        XCTAssertEqual(score, 100)
    }

    func test_healthFormula_countsMarksAndAge() {
        let today = day("2026-09-27")
        let placed = day("2026-09-20")
        let lastMaint = day("2026-09-23")
        let station = Station(
            name: "Front door",
            placedDaykey: DayKey.make(placed, calendar: calendar),
            incidents: [
                IncidentMark(daykey: DayKey.make(today, calendar: calendar), drawing: Data([1])),
                IncidentMark(daykey: DayKey.make(today, calendar: calendar), drawing: Data([2]))
            ],
            repairs: [RepairMark(daykey: DayKey.make(today, calendar: calendar))],
            maints: [MaintMark(daykey: DayKey.make(lastMaint, calendar: calendar))]
        )
        let score = StationHealth.score(station, today: DayKey.make(today, calendar: calendar), calendar: calendar)
        XCTAssertEqual(score, 100 - 2 - 1 - 4 + 0)
    }

    func test_healthFormula_recentMaintCreditsToday() {
        let today = day("2026-09-27")
        let station = Station(
            name: "Balcony",
            placedDaykey: DayKey.make(day("2026-09-01"), calendar: calendar),
            incidents: [IncidentMark(daykey: DayKey.make(today, calendar: calendar), drawing: Data([9]))],
            repairs: [],
            maints: [
                MaintMark(daykey: DayKey.make(day("2026-09-20"), calendar: calendar)),
                MaintMark(daykey: DayKey.make(today, calendar: calendar))
            ]
        )
        let score = StationHealth.score(station, today: DayKey.make(today, calendar: calendar), calendar: calendar)
        XCTAssertEqual(score, 100 - 1 - 0 - 0 + 1)
    }

    func test_powerOfTwoSeedInterleave_openingPairIsFirstTwoSlots() {
        let names = ["Reed", "Marlow", "Quinn", "Adler"]
        let order = BracketSeed.interleaved(names)
        XCTAssertEqual(order, ["Reed", "Adler", "Marlow", "Quinn"])
        let eight = BracketSeed.interleaved(["1", "2", "3", "4", "5", "6", "7", "8"])
        XCTAssertEqual(eight, ["1", "8", "4", "5", "2", "7", "3", "6"])
        XCTAssertNil(BracketSeed.interleaved(["only"]))
        XCTAssertNil(BracketSeed.interleaved(["a", "b", "c"]))
    }

    func test_ring_emptyFloorIsRefusedAndStaysBare() {
        let now = day("2026-09-27")
        let chart = HouseChart.bare()
        let result = FloorFold.ring(chart, stationID: UUID(), now: now, calendar: calendar)
        guard case .refused(.bareFloor, let next) = result else {
            XCTFail("Expected a bare floor")
            return
        }
        XCTAssertTrue(next.isBare)
        XCTAssertTrue(next.tillMarks.isEmpty)
    }

    func test_ring_onCoveredWritesTillAndAddsToFloat() {
        let now = day("2026-09-27")
        let chart = liveHouse(now: now)
        let before = chart.float.balance(daykey: DayKey.make(now, calendar: calendar), tillMarks: chart.tillMarks)
        let result = FloorFold.ring(chart, stationID: DemoHouse.frontID, now: now, calendar: calendar)
        guard case .wrote(let next) = result else {
            XCTFail("Ring on the covered front station should write")
            return
        }
        XCTAssertEqual(next.tillMarks.count, chart.tillMarks.count + 1)
        XCTAssertTrue(next.gapMarks.count == chart.gapMarks.count)
        let after = next.float.balance(daykey: DayKey.make(now, calendar: calendar), tillMarks: next.tillMarks)
        XCTAssertEqual(after, before + chart.walkInAdmission)
    }

    func test_ring_onOpenWritesGapAndKeepsFloat() {
        let now = day("2026-09-27")
        let chart = liveHouse(now: now)
        let daykey = DayKey.make(now, calendar: calendar)
        let before = chart.float.balance(daykey: daykey, tillMarks: chart.tillMarks)
        let result = FloorFold.ring(chart, stationID: DemoHouse.balconyID, now: now, calendar: calendar)
        guard case .wrote(let next) = result else {
            XCTFail("Ring on an open station still writes a gap")
            return
        }
        XCTAssertEqual(next.gapMarks.count, chart.gapMarks.count + 1)
        XCTAssertEqual(next.tillMarks.count, chart.tillMarks.count)
        XCTAssertEqual(next.float.balance(daykey: daykey, tillMarks: next.tillMarks), before)
    }

    func test_coverWhileDarkIsRefused() {
        let now = day("2026-09-27")
        var chart = HouseChart.bare()
        chart = FloorFold.placeStation(chart, name: "Front door", now: now, calendar: calendar)
        let stationID = chart.stations[0].id
        let result = FloorFold.cover(chart, stationID: stationID, now: now, calendar: calendar)
        guard case .refused(.coverWhileDark, let next) = result else {
            XCTFail("Cover on Dark is refused")
            return
        }
        XCTAssertEqual(next.phase, .dark)
        XCTAssertTrue(next.coverMarks.isEmpty)
        XCTAssertEqual(next.stations[0].posture, .open)
    }

    func test_advance_onDeckWritesMarkAndPromotesPair() {
        let now = day("2026-09-27")
        let chart = liveHouse(now: now)
        let bout = chart.bouts[0]
        XCTAssertEqual(bout.onDeck, [DemoHouse.reedID, DemoHouse.adlerID])
        let result = FloorFold.advance(chart, boutID: bout.id, entrantID: DemoHouse.adlerID, now: now)
        guard case .wrote(let next) = result else {
            XCTFail("On-deck advance should write")
            return
        }
        XCTAssertEqual(next.advanceMarks.count, 1)
        XCTAssertTrue(next.faultMarks.isEmpty)
        XCTAssertEqual(next.bouts[0].onDeck, [DemoHouse.marlowID, DemoHouse.quinnID])
        XCTAssertEqual(next.phase, .live)
    }

    func test_advance_offDeckWritesFaultAndStays() {
        let now = day("2026-09-27")
        let chart = liveHouse(now: now)
        let bout = chart.bouts[0]
        let result = FloorFold.advance(chart, boutID: bout.id, entrantID: DemoHouse.marlowID, now: now)
        guard case .wrote(let next) = result else {
            XCTFail("A fault is still a write")
            return
        }
        XCTAssertEqual(next.faultMarks.count, 1)
        XCTAssertTrue(next.advanceMarks.isEmpty)
        XCTAssertEqual(next.bouts[0].cursor, bout.cursor)
    }

    func test_architectureFold_reachesLiveOnlyWhenCoveredAndOnDeck() {
        let now = day("2026-09-27")
        var chart = HouseChart.bare()
        XCTAssertEqual(chart.writing, .bare)
        chart.staff = [Staff(id: DemoHouse.staffID, name: "Nia Cole")]
        chart = FloorFold.placeStation(chart, name: "Front door", now: now, calendar: calendar)
        chart.stations[0].id = DemoHouse.frontID
        guard case .wrote(let clocked) = FloorFold.clockIn(chart, staffID: DemoHouse.staffID, now: now, calendar: calendar) else {
            XCTFail("Clock should fold Dark to OnShift")
            return
        }
        XCTAssertEqual(clocked.phase, .onShift)
        XCTAssertEqual(clocked.shiftMarks.count, 1)
        guard case .wrote(let covered) = FloorFold.cover(clocked, stationID: DemoHouse.frontID, now: now, calendar: calendar) else {
            XCTFail("Cover should fold Open to Covered")
            return
        }
        XCTAssertEqual(covered.stations[0].posture, .covered)
        XCTAssertEqual(covered.phase, .onShift)
        let entrants = [
            Entrant(id: DemoHouse.reedID, name: "Reed"),
            Entrant(id: DemoHouse.marlowID, name: "Marlow"),
            Entrant(id: DemoHouse.quinnID, name: "Quinn"),
            Entrant(id: DemoHouse.adlerID, name: "Adler")
        ]
        guard case .wrote(let live) = FloorFold.seedBout(covered, title: "Late house", entrants: entrants, now: now) else {
            XCTFail("Seed should fold the bracket to Live")
            return
        }
        XCTAssertEqual(live.bracketPhase, .live)
        XCTAssertEqual(live.phase, .live)
        XCTAssertEqual(live.bouts[0].order.first, DemoHouse.reedID)
    }

    func test_midnightRoll_keepsYesterdayTotalsAndOpensAFreshLine() {
        let yesterday = day("2026-09-26")
        let today = day("2026-09-27")
        let chart = liveHouse(now: yesterday)
        let oldKey = DayKey.make(yesterday, calendar: calendar)
        let kept = chart.float.balance(daykey: oldKey, tillMarks: chart.tillMarks)
        XCTAssertGreaterThan(kept, 0)
        let rolled = FloorFold.roll(chart, now: today, calendar: calendar)
        let newKey = DayKey.make(today, calendar: calendar)
        XCTAssertEqual(rolled.float.balance(daykey: oldKey, tillMarks: rolled.tillMarks), kept)
        XCTAssertEqual(rolled.float.opening(for: newKey), 0)
        XCTAssertEqual(rolled.float.balance(daykey: newKey, tillMarks: rolled.tillMarks), 0)
        XCTAssertEqual(rolled.shiftMarks.filter { $0.daykey == oldKey }.count, chart.shiftMarks.filter { $0.daykey == oldKey }.count)
    }

    func test_healthBelowCoverIsRefused() {
        let now = day("2026-09-27")
        var chart = HouseChart.bare()
        chart.staff = [Staff(id: DemoHouse.staffID, name: "Nia Cole")]
        chart = FloorFold.placeStation(chart, name: "Dim booth", now: now, calendar: calendar)
        let stationID = chart.stations[0].id
        guard case .wrote(let clocked) = FloorFold.clockIn(chart, staffID: DemoHouse.staffID, now: now, calendar: calendar) else {
            return XCTFail("clock")
        }
        chart = clocked
        for _ in 0..<50 {
            guard case .wrote(let next) = FloorFold.fileIncident(chart, stationID: stationID, drawing: Data([3]), now: now, calendar: calendar) else {
                return XCTFail("incident")
            }
            chart = next
        }
        let health = StationHealth.score(chart.stations[0], today: DayKey.make(now, calendar: calendar), calendar: calendar)
        XCTAssertLessThan(health, StationHealth.coverMinimum)
        guard case .refused(.healthBelowCover, _) = FloorFold.cover(chart, stationID: stationID, now: now, calendar: calendar) else {
            return XCTFail("Cover below 60 is refused")
        }
    }

    private func liveHouse(now: Date) -> HouseChart {
        DemoHouse.make(now: now)
    }

    private func day(_ iso: String) -> Date {
        let parts = iso.split(separator: "-").compactMap { Int($0) }
        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = calendar.timeZone
        components.year = parts[0]
        components.month = parts[1]
        components.day = parts[2]
        components.hour = 15
        return calendar.date(from: components) ?? Date(timeIntervalSince1970: 0)
    }
}
