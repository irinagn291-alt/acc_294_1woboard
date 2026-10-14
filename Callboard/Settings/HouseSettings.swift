import SwiftUI
import UIKit

/// Settings sheet. Replay onboarding, confirmed reset, and the contact link.
struct HouseSettings: View {
    @ObservedObject var desk: FloorDesk
    @State private var confirmReset = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FoyerMeasure.steps(2)) {
                if desk.chart.stations.isEmpty && desk.chart.tillMarks.isEmpty {
                    FoyerArt(name: "clb_EmptyList", steps: 14)
                    FoyerLine(text: "Nothing is stored yet", step: .title, heavy: true)
                    FoyerLine(text: "Place a station on the floor. These controls stay here.", step: .body, color: DesignTokens.muted)
                        .frame(maxWidth: .infinity, minHeight: FoyerMeasure.steps(16), alignment: .leading)
                } else {
                    FoyerLine(text: "House on this device", step: .title, heavy: true)
                    FoyerLine(
                        text: "\(FoyerCount.count(desk.chart.stations.count)) stations, \(FoyerCount.count(desk.chart.tillMarks.count)) till marks.",
                        step: .body,
                        color: DesignTokens.muted
                    )
                }
                if let notice = desk.notice {
                    FoyerLine(text: notice, step: .body)
                    Button("Retry") { Task { await desk.retryNotice() } }
                        .buttonStyle(FoyerFillStyle(tone: .quiet))
                }
                Button("Replay onboarding") {
                    Task { await desk.replayWelcome() }
                }
                .buttonStyle(FoyerFillStyle(tone: .quiet))
                Button("Reset all data") { confirmReset = true }
                    .buttonStyle(FoyerFillStyle(tone: .destructive))
                Button {
                    guard let contact = URL(string: "https://callboard-floor.pro/contact-us") else { return }
                    UIApplication.shared.open(contact)
                } label: {
                    FoyerLine(text: "Contact Callboard", step: .headline, heavy: true, color: DesignTokens.ink)
                }
                .buttonStyle(FoyerFillStyle(tone: .quiet))
            }
            .padding(FoyerMeasure.steps(2))
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(DesignTokens.bg)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Reset the house?", isPresented: $confirmReset) {
            Button("Reset all data", role: .destructive) {
                Task { await desk.resetAll() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Stations, shifts, till marks, and the bracket leave this device.")
        }
    }
}
