import Foundation

/// The only seam between the floor fold and storage. Memory is the source of
/// truth. UserDefaults key clb.house.v1 and the atomic house file are projections.
/// This actor is not the main actor, so file reads and writes stay off the UI thread.
actor HouseStore {
    static let houseKey = "clb.house.v1"
    static let demoKey = "clb.demo.v1"
    static let debounceNanoseconds: UInt64 = 400_000_000

    private let defaults: UserDefaults
    private let chartURL: URL
    private let backupURL: URL
    private var chart: HouseChart
    private var saveTask: Task<Void, Never>?
    private(set) var loadNotice: String?

    init(defaults: UserDefaults, chartURL: URL, chart: HouseChart = .bare()) {
        self.defaults = defaults
        self.chartURL = chartURL
        self.backupURL = chartURL.appendingPathExtension("backup")
        self.chart = chart
    }

    static func testing(suite: String, chartURL: URL) -> HouseStore {
        let defaults = UserDefaults(suiteName: suite) ?? .standard
        return HouseStore(defaults: defaults, chartURL: chartURL)
    }

    static func plant(_ data: Data, suite: String, key: String) {
        let defaults = UserDefaults(suiteName: suite) ?? .standard
        defaults.set(data, forKey: key)
    }

    static func live() -> HouseStore {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let folder = support.appendingPathComponent("1Woboard", isDirectory: true)
        return HouseStore(defaults: .standard, chartURL: folder.appendingPathComponent("house.json"))
    }

    func current() -> HouseChart { chart }

    func houseBlob() -> Data? {
        defaults.data(forKey: Self.houseKey)
    }

    func prepareLaunch(now: Date = Date()) async {
        await load()
        #if targetEnvironment(simulator)
        await seedDemoIfNeeded(now: now)
        #endif
        chart = FloorFold.roll(chart, now: now)
        await persist()
    }

    func load() async {
        loadNotice = nil
        if let fileData = read(chartURL), let decoded = HouseChart.decode(fileData) {
            chart = decoded
            defaults.set(fileData, forKey: Self.houseKey)
            return
        }
        if let backup = read(backupURL), let decoded = HouseChart.decode(backup) {
            chart = decoded
            loadNotice = "The house file was unreadable. The last good copy is back."
            await persist()
            return
        }
        if let stored = defaults.data(forKey: Self.houseKey), let decoded = HouseChart.decode(stored) {
            chart = decoded
            await persist()
            return
        }
        let hadBytes = read(chartURL) != nil || read(backupURL) != nil || defaults.data(forKey: Self.houseKey) != nil
        if hadBytes {
            loadNotice = "The house file could not be read. Starting from an empty floor."
        }
        chart = .bare()
    }

    func apply(_ result: FoldResult) async {
        switch result {
        case .wrote(let next):
            chart = next
            scheduleSave()
        case .refused(_, let next):
            chart = next
        }
    }

    func replace(_ next: HouseChart) async {
        chart = next
        scheduleSave()
    }

    func roll(now: Date) async {
        chart = FloorFold.roll(chart, now: now)
        scheduleSave()
    }

    /// Coalesces rapid marks. Sleep yields the actor so later marks still land.
    func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(nanoseconds: Self.debounceNanoseconds)
            guard !Task.isCancelled else { return }
            await persist()
        }
    }

    func flush() async {
        saveTask?.cancel()
        saveTask = nil
        await persist()
    }

    func resetAllData() async {
        saveTask?.cancel()
        saveTask = nil
        defaults.removeObject(forKey: Self.houseKey)
        remove(chartURL)
        remove(backupURL)
        chart = .bare()
        loadNotice = nil
    }

    func seedDemoIfNeeded(now: Date) async {
        #if targetEnvironment(simulator)
        if defaults.bool(forKey: Self.demoKey) {
            return
        }
        if !chart.isBare {
            defaults.set(true, forKey: Self.demoKey)
            return
        }
        chart = DemoHouse.make(now: now)
        defaults.set(true, forKey: Self.demoKey)
        await persist()
        #else
        _ = now
        #endif
    }

    private func persist() async {
        guard let data = chart.encoded() else {
            loadNotice = "The house could not be saved. The floor on screen is unchanged."
            return
        }
        do {
            try writeAtomically(data)
            defaults.set(data, forKey: Self.houseKey)
        } catch {
            loadNotice = "The house could not be saved. The floor on screen is unchanged."
        }
    }

    private func writeAtomically(_ data: Data) throws {
        let manager = FileManager.default
        let folder = chartURL.deletingLastPathComponent()
        try manager.createDirectory(at: folder, withIntermediateDirectories: true)
        if manager.fileExists(atPath: chartURL.path) {
            do {
                let existing = try Data(contentsOf: chartURL)
                if HouseChart.decode(existing) != nil {
                    try existing.write(to: backupURL, options: .atomic)
                }
            } catch {
                loadNotice = "The previous house file could not be copied aside."
            }
        }
        try data.write(to: chartURL, options: .atomic)
    }

    private func read(_ url: URL) -> Data? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        do {
            return try Data(contentsOf: url)
        } catch {
            return nil
        }
    }

    private func remove(_ url: URL) {
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            loadNotice = "A house file could not be removed."
        }
    }
}
