import SwiftUI

/// Filled capsule for the live verb. Destructive stays off the accent fill.
struct FoyerFillStyle: ButtonStyle {
    var tone: Tone = .accent
    var busy: Bool = false

    enum Tone {
        case accent
        case quiet
        case destructive
    }

    @Environment(\.isEnabled) private var enabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(FoyerStep.headline.font(heavy: true))
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity, minHeight: FoyerMeasure.hit)
            .padding(.horizontal, FoyerMeasure.steps(2))
            .background(fill(pressed: configuration.isPressed && enabled), in: Capsule())
            .scaleEffect(reduceMotion || !configuration.isPressed || !enabled ? 1 : 0.97)
            .opacity(!enabled || busy ? 0.4 : (configuration.isPressed ? 0.82 : 1))
            .contentShape(Capsule())
            .animation(.easeOut(duration: reduceMotion ? 0.2 : 0.28), value: configuration.isPressed)
    }

    private var foreground: Color {
        switch tone {
        case .accent: DesignTokens.bg
        case .quiet: DesignTokens.ink
        case .destructive: DesignTokens.muted
        }
    }

    private func fill(pressed: Bool) -> Color {
        let base: Color
        switch tone {
        case .accent: base = DesignTokens.accent
        case .quiet: base = DesignTokens.surface
        case .destructive: base = DesignTokens.surface
        }
        return pressed ? base.opacity(0.72) : base
    }
}

/// Row inside one floor index. Pressed state stays on the row, radius stays on the card.
struct FoyerIndexStyle: ButtonStyle {
    var expands = true
    @Environment(\.isEnabled) private var enabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: expands ? .infinity : nil, minHeight: FoyerMeasure.hit, alignment: .leading)
            .contentShape(Rectangle())
            .opacity(!enabled ? 0.4 : (configuration.isPressed ? 0.72 : 1))
            .scaleEffect(reduceMotion || !configuration.isPressed || !enabled ? 1 : 0.98)
            .animation(.easeOut(duration: reduceMotion ? 0.2 : 0.28), value: configuration.isPressed)
    }
}
