import XCTest
@testable import Callboard

final class HouseStoreTests: XCTestCase {
    private var directory: URL!
    private var suite: String!

    override func setUp() async throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        suite = "clb.test." + UUID().uuidString
    }

    override func tearDown() async throws {
        if let suite {
            UserDefaults().removePersistentDomain(forName: suite)
        }
        if let directory {
            try? FileManager.default.removeItem(at: directory)
        }
    }

    func test_roundTrip_writeFlushAndReload() async throws {
        let store = HouseStore.testing(suite: suite, chartURL: directory.appendingPathComponent("house.json"))
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        await store.replace(DemoHouse.make(now: now))
        await store.flush()
        let reloaded = HouseStore.testing(suite: suite, chartURL: directory.appendingPathComponent("house.json"))
        await reloaded.load()
        let chart = await reloaded.current()
        XCTAssertEqual(chart.stations.count, 4)
        XCTAssertEqual(chart.phase, .live)
        XCTAssertEqual(chart.tillMarks.count, 3)
        XCTAssertEqual(chart.schemaVersion, 1)
        XCTAssertTrue(chart.onboardingComplete)
        let blob = await reloaded.houseBlob()
        XCTAssertNotNil(blob)
    }

    func test_corruptFile_fallsBackToBackup() async throws {
        let url = directory.appendingPathComponent("house.json")
        let good = DemoHouse.make(now: Date(timeIntervalSince1970: 1_800_000_000))
        let encoded = try XCTUnwrap(good.encoded())
        try encoded.write(to: url.appendingPathExtension("backup"), options: .atomic)
        try Data("not-json".utf8).write(to: url, options: .atomic)
        let store = HouseStore.testing(suite: suite, chartURL: url)
        await store.load()
        let chart = await store.current()
        XCTAssertEqual(chart.stations.count, 4)
        let notice = await store.loadNotice
        XCTAssertNotNil(notice)
    }

    func test_corruptFileAndBackup_startsBareAndTells() async throws {
        let url = directory.appendingPathComponent("house.json")
        try Data("bad".utf8).write(to: url, options: .atomic)
        try Data("also-bad".utf8).write(to: url.appendingPathExtension("backup"), options: .atomic)
        HouseStore.plant(Data("nope".utf8), suite: suite, key: HouseStore.houseKey)
        let store = HouseStore.testing(suite: suite, chartURL: url)
        await store.load()
        let chart = await store.current()
        XCTAssertTrue(chart.isBare)
        XCTAssertEqual(chart.phase, .dark)
        let notice = await store.loadNotice
        XCTAssertNotNil(notice)
    }

    func test_unknownSchema_isBare() async throws {
        let url = directory.appendingPathComponent("house.json")
        try Data(#"{"schemaVersion":99}"#.utf8).write(to: url, options: .atomic)
        let store = HouseStore.testing(suite: suite, chartURL: url)
        await store.load()
        let chart = await store.current()
        XCTAssertTrue(chart.isBare)
    }

    func test_resetAllData_deletesTheKey() async throws {
        let url = directory.appendingPathComponent("house.json")
        let store = HouseStore.testing(suite: suite, chartURL: url)
        await store.replace(DemoHouse.make())
        await store.flush()
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        await store.resetAllData()
        let blob = await store.houseBlob()
        XCTAssertNil(blob)
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
        let chart = await store.current()
        XCTAssertTrue(chart.isBare)
    }

    func test_daykey_usesStartOfDay() {
        var calendar = Calendar(identifier: .gregorian)
        if let zone = TimeZone(secondsFromGMT: 0) {
            calendar.timeZone = zone
        }
        var parts = DateComponents()
        parts.calendar = calendar
        parts.timeZone = calendar.timeZone
        parts.year = 2026
        parts.month = 9
        parts.day = 27
        parts.hour = 23
        parts.minute = 30
        let late = calendar.date(from: parts) ?? Date()
        XCTAssertEqual(DayKey.make(late, calendar: calendar), 20260927)
    }

    @MainActor
    func test_refusedCoverAndSeed_keepNoticeAndRetryRepeats() async {
        let store = HouseStore.testing(suite: suite, chartURL: directory.appendingPathComponent("house.json"))
        let desk = FloorDesk(store: store)
        await desk.cover(stationID: UUID())
        XCTAssertEqual(desk.notice, FloorDesk.refusalLine(.bareFloor))
        await desk.retryNotice()
        XCTAssertEqual(desk.notice, FloorDesk.refusalLine(.bareFloor))
        await desk.seedBout(title: "Late house", names: ["Reed", "Marlow", "Quinn"])
        XCTAssertEqual(desk.notice, FloorDesk.refusalLine(.notPowerOfTwo))
    }
}
