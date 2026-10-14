import SwiftUI

/// Shift sheet. Clock writes a ShiftMark and folds Dark to OnShift.
struct ShiftsSheet: View {
    @ObservedObject var desk: FloorDesk
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var name = ""
    @State private var shown = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FoyerMeasure.steps(2)) {
                if let notice = desk.notice {
                    FoyerLine(text: notice, step: .body)
                    Button("Retry") { Task { await desk.retryNotice() } }
                        .buttonStyle(FoyerFillStyle(tone: .quiet))
                }
                if desk.chart.staff.isEmpty && desk.chart.shifts.isEmpty {
                    empty
                } else {
                    roster
                }
            }
            .padding(FoyerMeasure.steps(2))
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(DesignTokens.bg)
        .navigationTitle("Shifts")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.immediately)
        .foyerKeyboardDone()
        .onAppear { shown = true }
    }

    private var empty: some View {
        VStack(alignment: .leading, spacing: FoyerMeasure.steps(2)) {
            FoyerArt(name: "clb_EmptyList", steps: 14)
            FoyerLine(text: "No one is on the roster", step: .title, heavy: true)
            FoyerLine(text: "Add a volunteer, then clock them in.", step: .body, color: DesignTokens.muted)
            field
            Button("Add volunteer") {
                Task { await desk.addVolunteer(name: name); name = "" }
            }
            .buttonStyle(FoyerFillStyle(busy: desk.busy))
            .disabled(desk.busy)
        }
        .frame(maxWidth: .infinity, minHeight: FoyerMeasure.steps(48), maxHeight: .infinity, alignment: .topLeading)
        .foyerStagger(index: 0, shown: shown, reduceMotion: reduceMotion)
    }

    private var roster: some View {
        VStack(alignment: .leading, spacing: FoyerMeasure.steps(2)) {
            FoyerLine(text: phaseLine, step: .caption, color: DesignTokens.muted)
            field
            Button("Add volunteer") {
                Task { await desk.addVolunteer(name: name); name = "" }
            }
            .buttonStyle(FoyerFillStyle(tone: .quiet, busy: desk.busy))
            .disabled(desk.busy)
            ForEach(desk.chart.staff) { person in
                VStack(alignment: .leading, spacing: FoyerMeasure.unit) {
                    FoyerLine(text: person.name, step: .headline, heavy: true)
                    if let open = desk.chart.shifts.first(where: { $0.staffID == person.id && $0.isOpen }) {
                        FoyerLine(text: "On the floor", step: .caption, color: DesignTokens.accent)
                        Button("Clock out") {
                            Task { await desk.clockOut(shiftID: open.id) }
                        }
                        .buttonStyle(FoyerFillStyle(tone: .quiet, busy: desk.busy))
                        .disabled(desk.busy)
                    } else {
                        FoyerLine(text: "Off duty", step: .caption, color: DesignTokens.muted)
                        Button("Clock in") {
                            Task { await desk.clockIn(staffID: person.id) }
                        }
                        .buttonStyle(FoyerFillStyle(busy: desk.busy))
                        .disabled(desk.busy)
                    }
                }
                .padding(FoyerMeasure.steps(2))
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: FoyerMeasure.card))
            }
        }
        .foyerStagger(index: 1, shown: shown, reduceMotion: reduceMotion)
    }

    private var field: some View {
        TextField("Volunteer name", text: $name)
            .font(FoyerStep.body.font())
            .foregroundStyle(DesignTokens.ink)
            .padding(FoyerMeasure.steps(2))
            .background(DesignTokens.surface, in: RoundedRectangle(cornerRadius: FoyerMeasure.chip))
    }

    private var phaseLine: String {
        switch desk.chart.phase {
        case .dark: "House is Dark until someone clocks in."
        case .onShift: "House is OnShift."
        case .live: "House is Live."
        }
    }
}

/// Shift screen for the live driver. Clock writes a ShiftMark.
struct ShiftsView: View {
    @ObservedObject var desk: FloorDesk

    var body: some View {
        ShiftsSheet(desk: desk)
    }
}
