import SwiftUI

/// Finance sheet. Today's TillMarks reconcile against the house float.
struct FinanceSheet: View {
    @ObservedObject var desk: FloorDesk
    @State private var exportURL: URL?
    @State private var exporting = false

    private var today: Int { DayKey.make(Date()) }

    private var marks: [TillMark] {
        desk.chart.tillMarks.filter { $0.daykey == today }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FoyerMeasure.steps(2)) {
                if let notice = desk.notice {
                    FoyerLine(text: notice, step: .body)
                    Button("Retry") { Task { await desk.retryNotice() } }
                        .buttonStyle(FoyerFillStyle(tone: .quiet))
                }
                FoyerLine(text: "House float", step: .micro, color: DesignTokens.muted)
                FoyerLine(
                    text: FoyerCount.amount(desk.chart.float.balance(daykey: today, tillMarks: desk.chart.tillMarks)),
                    step: .display,
                    heavy: true
                )
                .monospacedDigit()
                if marks.isEmpty {
                    VStack(alignment: .leading, spacing: FoyerMeasure.steps(2)) {
                        FoyerArt(name: "clb_EmptyList", steps: 14)
                        FoyerLine(text: "No rings tonight", step: .title, heavy: true)
                        FoyerLine(text: "Cover a station, then ring a walk-in. The till lands here.", step: .body, color: DesignTokens.muted)
                    }
                    .frame(maxWidth: .infinity, minHeight: FoyerMeasure.steps(36), maxHeight: .infinity, alignment: .topLeading)
                } else {
                    ForEach(marks) { mark in
                        HStack {
                            FoyerLine(text: desk.stationName(mark.stationID), step: .body)
                            Spacer(minLength: FoyerMeasure.steps(1))
                            FoyerLine(text: FoyerCount.amount(mark.amount), step: .headline, heavy: true)
                                .monospacedDigit()
                        }
                        .padding(FoyerMeasure.steps(2))
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: FoyerMeasure.card))
                    }
                }
                let gaps = desk.chart.gapMarks.filter { $0.daykey == today }
                if !gaps.isEmpty {
                    FoyerLine(text: "\(FoyerCount.count(gaps.count)) open rings did not enter the float.", step: .caption, color: DesignTokens.muted)
                }
                Button("Export tonight CSV") {
                    Task { await exportTonight() }
                }
                .buttonStyle(FoyerFillStyle(busy: exporting))
                .disabled(marks.isEmpty || exporting)
            }
            .padding(FoyerMeasure.steps(2))
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(DesignTokens.bg)
        .navigationTitle("Finance")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: exportBinding) { token in
            ShareLink(item: token.url) {
                Label("Share the till file", systemImage: "square.and.arrow.up")
                    .font(FoyerStep.headline.font(heavy: true))
                    .foregroundStyle(DesignTokens.ink)
                    .frame(maxWidth: .infinity, minHeight: FoyerMeasure.hit)
            }
            .padding(FoyerMeasure.steps(3))
            .presentationDetents([.medium])
            .presentationCornerRadius(FoyerMeasure.card)
            .presentationBackground(.regularMaterial)
        }
    }

    private var exportBinding: Binding<ExportToken?> {
        Binding(
            get: { exportURL.map { ExportToken(url: $0) } },
            set: { exportURL = $0?.url }
        )
    }

    private func exportTonight() async {
        guard !exporting else { return }
        exporting = true
        defer { exporting = false }
        var lines = ["station,amount,daykey"]
        for mark in marks {
            let name = desk.stationName(mark.stationID).replacingOccurrences(of: ",", with: " ")
            lines.append("\(name),\(mark.amount),\(mark.daykey)")
        }
        let payload = lines.joined(separator: "\n")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("callboard-till-\(today).csv")
        let wrote = await Task.detached(priority: .userInitiated) {
            do {
                try payload.write(to: url, atomically: true, encoding: .utf8)
                return true
            } catch {
                return false
            }
        }.value
        if wrote {
            exportURL = url
        } else {
            desk.report("The till file could not be written. Try the export again.")
        }
    }
}

/// Finance screen for the live driver. Today's till reconciles against the float.
struct FinanceView: View {
    @ObservedObject var desk: FloorDesk

    var body: some View {
        FinanceSheet(desk: desk)
    }
}

private struct ExportToken: Identifiable {
    var id: String { url.path }
    var url: URL
}
