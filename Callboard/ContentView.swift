import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var desk: FloorDesk

    var body: some View {
        Group {
            if !desk.ready {
                VStack(alignment: .leading, spacing: FoyerMeasure.steps(2)) {
                    FoyerLine(text: "1Woboard", step: .display, heavy: true)
                    FoyerLine(text: "Opening the floor.", step: .body, color: DesignTokens.muted)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(FoyerMeasure.steps(3))
            } else if desk.chart.onboardingComplete {
                FloorCanvas(desk: desk)
            } else {
                OnboardingView(desk: desk)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignTokens.bg.ignoresSafeArea())
    }
}
