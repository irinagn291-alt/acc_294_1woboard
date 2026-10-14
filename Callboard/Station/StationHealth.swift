import Foundation

/// Derived station health for the cover gate.
/// health = 100 - incidents - repairs - age penalties + recent maint.
/// Incidents and repairs are mark counts. Age penalties are whole days since
/// the last maint daykey (or the placed daykey when the station has no maint).
/// Recent maint is the count of maint marks that share today's daykey.
enum StationHealth {
    static let coverMinimum = 60

    static func score(
        _ station: Station,
        today: Int,
        calendar: Calendar = .current
    ) -> Int {
        let incidents = station.incidents.count
        let repairs = station.repairs.count
        let anchor = station.maints.map(\.daykey).max() ?? station.placedDaykey
        let agePenalties = wholeDays(from: anchor, to: today, calendar: calendar)
        let recentMaint = station.maints.filter { $0.daykey == today }.count
        return 100 - incidents - repairs - agePenalties + recentMaint
    }

    static func wholeDays(from earlier: Int, to later: Int, calendar: Calendar) -> Int {
        guard later >= earlier,
              let start = DayKey.startOfDay(earlier, calendar: calendar),
              let end = DayKey.startOfDay(later, calendar: calendar)
        else {
            return 0
        }
        let span = calendar.dateComponents([.day], from: start, to: end).day ?? 0
        return max(0, span)
    }
}
