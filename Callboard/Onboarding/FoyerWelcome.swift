import SwiftUI

/// Three foyer pages. Skip still writes the completion flag and defaults.
struct FoyerWelcome: View {
    @ObservedObject var desk: FloorDesk
    @State private var page = 0

    private let pages: [(String, String)] = [
        ("A door till for the hall", "Ring walk-ins on a covered station while the volunteer shift stays on the floor."),
        ("Cover, then ring", "Clock in, cover a station at health 60 or more, then ring the admission onto the till."),
        ("Advance the pair", "Tap the on-deck winner. The interleaved bout moves. Anyone else is a fault.")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: FoyerMeasure.steps(2)) {
            VStack(alignment: .leading, spacing: FoyerMeasure.steps(2)) {
                FoyerArt(name: "clb_Onboarding\(page + 1)", steps: 22)
                FoyerLine(text: pages[page].0, step: .display, heavy: true)
                FoyerLine(text: pages[page].1, step: .body, color: DesignTokens.muted)
                FoyerLine(
                    text: "\(FoyerCount.count(page + 1)) of \(FoyerCount.count(pages.count))",
                    step: .micro,
                    color: DesignTokens.muted
                )
                Spacer(minLength: FoyerMeasure.steps(2))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            Button(page == pages.count - 1 ? "Continue" : "Next") {
                if page < pages.count - 1 {
                    page += 1
                } else {
                    Task { await desk.finishWelcome() }
                }
            }
            .buttonStyle(FoyerFillStyle())
            Button("Skip") {
                Task { await desk.finishWelcome() }
            }
            .buttonStyle(FoyerFillStyle(tone: .quiet))
        }
        .padding(FoyerMeasure.steps(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .background(DesignTokens.bg)
    }
}

/// Onboarding screen for the live driver. Skip still writes the completion flag.
struct OnboardingView: View {
    @ObservedObject var desk: FloorDesk

    var body: some View {
        FoyerWelcome(desk: desk)
    }
}
