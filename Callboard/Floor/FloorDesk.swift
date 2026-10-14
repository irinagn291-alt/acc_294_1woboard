import Foundation
import UIKit

/// Main-actor seam from the floor fold to the foyer screens.
/// Sheets never write the chart. Clock, Cover, Ring, Seed, and Advance do.
@MainActor
final class FloorDesk: ObservableObject {
    enum Sheet: String, Identifiable {
        case shifts
        case bracket
        case finance
        case door
        case settings
        var id: String { rawValue }
    }

    private let store: HouseStore
    let shelf: TitleShelfClient

    @Published private(set) var chart: HouseChart = .bare()
    @Published private(set) var ready = false
    @Published private(set) var busy = false
    @Published var notice: String?
    @Published var sheet: Sheet?

    private var launchRead = false
    private var lastTap: LastTap?

    /// The tap Retry should repeat. A load failure has no tap, so Retry reloads the file.
    private enum LastTap {
        case cover(UUID)
        case ring(UUID)
        case seed(String, [String])
        case advance(UUID, UUID)
        case clockIn(UUID)
        case clockOut(UUID)
        case maintain(UUID)
        case place(String)
    }

    init(store: HouseStore? = nil) {
        let live = store ?? HouseStore.live()
        self.store = live
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        self.shelf = TitleShelfClient(
            transport: URLSessionTransport(),
            cacheDirectory: caches.appendingPathComponent("CallboardShelf", isDirectory: true)
        )
    }

    func boot() async {
        await store.prepareLaunch()
        await refresh()
        ready = true
        openReviewIfReady()
    }

    func flush() async {
        await store.flush()
    }

    func refresh() async {
        chart = await store.current()
        if let loaded = await store.loadNotice {
            notice = loaded
            lastTap = nil
        }
    }

    func retryLoad() async {
        lastTap = nil
        notice = nil
        await store.load()
        await refresh()
    }

    /// Repeats Cover, Ring, Seed, or the other refused tap. Reloads only when the file itself failed.
    func retryNotice() async {
        let failedLoad = await store.loadNotice != nil
        guard let lastTap, !failedLoad else {
            await retryLoad()
            return
        }
        switch lastTap {
        case .cover(let id):
            await cover(stationID: id)
        case .ring(let id):
            await ring(stationID: id)
        case .seed(let title, let names):
            await seedBout(title: title, names: names)
        case .advance(let boutID, let entrantID):
            await advance(boutID: boutID, entrantID: entrantID)
        case .clockIn(let id):
            await clockIn(staffID: id)
        case .clockOut(let id):
            await clockOut(shiftID: id)
        case .maintain(let id):
            await maintain(stationID: id)
        case .place(let name):
            await placeStation(name: name)
        }
    }

    func finishWelcome() async {
        var next = chart
        next.onboardingComplete = true
        await store.replace(next)
        await refresh()
        openReviewIfReady()
    }

    func placeStation(name: String) async {
        lastTap = .place(name)
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            notice = "Name the station, then place it."
            return
        }
        await commitChart(FloorFold.placeStation(chart, name: trimmed, now: Date()))
    }

    func addVolunteer(name: String) async {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            notice = "Write a name before you add a volunteer."
            return
        }
        var next = chart
        next.staff.append(Staff(name: trimmed))
        await commitChart(next)
    }

    func clockIn(staffID: UUID) async {
        lastTap = .clockIn(staffID)
        await commit(FloorFold.clockIn(chart, staffID: staffID, now: Date()))
    }

    func clockOut(shiftID: UUID) async {
        lastTap = .clockOut(shiftID)
        await commit(FloorFold.clockOut(chart, shiftID: shiftID, now: Date()))
    }

    func cover(stationID: UUID) async {
        lastTap = .cover(stationID)
        await commit(FloorFold.cover(chart, stationID: stationID, now: Date()))
    }

    func ring(stationID: UUID) async {
        lastTap = .ring(stationID)
        await commit(FloorFold.ring(chart, stationID: stationID, now: Date()))
    }

    func fileIncident(stationID: UUID, drawing: Data) async {
        guard !drawing.isEmpty else {
            notice = "Draw the incident on the slate, then save it."
            return
        }
        await commit(FloorFold.fileIncident(chart, stationID: stationID, drawing: drawing, now: Date()))
    }

    func maintain(stationID: UUID) async {
        lastTap = .maintain(stationID)
        await commit(FloorFold.maintain(chart, stationID: stationID, now: Date()))
    }

    func seedBout(title: String, names: [String]) async {
        lastTap = .seed(title, names)
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let people = names.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        guard !trimmed.isEmpty else {
            notice = "Name the bout before you seed it."
            return
        }
        let entrants = people.map { Entrant(name: $0) }
        await commit(FloorFold.seedBout(chart, title: trimmed, entrants: entrants, now: Date()))
    }

    func advance(boutID: UUID, entrantID: UUID) async {
        lastTap = .advance(boutID, entrantID)
        await commit(FloorFold.advance(chart, boutID: boutID, entrantID: entrantID, now: Date()))
    }

    func resetAll() async {
        await store.resetAllData()
        await refresh()
        sheet = nil
    }

    func replayWelcome() async {
        var next = chart
        next.onboardingComplete = false
        await store.replace(next)
        await refresh()
        sheet = nil
    }

    func openReviewIfReady() {
        guard chart.onboardingComplete, !launchRead else { return }
        launchRead = true
        switch ReviewLaunch.screen {
        case "today":
            sheet = nil
        case "log":
            sheet = .finance
        case "goals":
            sheet = .bracket
        case "shifts":
            sheet = .shifts
        case "settings":
            sheet = .settings
        case "door":
            sheet = .door
        default:
            break
        }
    }

    func report(_ text: String) {
        notice = text.isEmpty ? nil : text
    }

    func stationName(_ id: UUID) -> String {
        chart.stations.first { $0.id == id }?.name ?? "Station"
    }

    func entrantName(_ id: UUID) -> String {
        chart.entrants.first { $0.id == id }?.name ?? "Entrant"
    }

    func staffName(_ id: UUID) -> String {
        chart.staff.first { $0.id == id }?.name ?? "Volunteer"
    }

    private func commit(_ result: FoldResult) async {
        guard !busy else { return }
        busy = true
        defer { busy = false }
        switch result {
        case .wrote(let next):
            notice = nil
            lastTap = nil
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            await store.apply(.wrote(next))
        case .refused(let reason, let next):
            notice = Self.refusalLine(reason)
            await store.apply(.refused(reason, next))
        }
        await refresh()
    }

    private func commitChart(_ next: HouseChart) async {
        guard !busy else { return }
        busy = true
        defer { busy = false }
        notice = nil
        lastTap = nil
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        await store.replace(next)
        await refresh()
    }

    static func refusalLine(_ reason: FoldRefusal) -> String {
        switch reason {
        case .bareFloor:
            return "The floor has no stations. Place one, then try again."
        case .coverWhileDark:
            return "The house is Dark. Clock a volunteer in, then cover."
        case .healthBelowCover:
            return "Health is under 60. Maintain the station, then cover."
        case .alreadyCovered:
            return "This station is already Covered."
        case .unknownStation:
            return "That station is not on the floor."
        case .unknownStaff:
            return "That volunteer is not on the roster."
        case .noOpenShift:
            return "No open shift to clock out."
        case .unknownBout:
            return "That bout is not on the rail."
        case .notPowerOfTwo:
            return "Seed two, four, or eight entrants so the pair can interleave."
        }
    }
}
