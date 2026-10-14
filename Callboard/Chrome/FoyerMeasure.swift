import SwiftUI
import UIKit

/// Spacing, radius, and type for the floor. One unit, two radii, Palatino only.
enum FoyerMeasure {
    static let unit: CGFloat = 8
    static func steps(_ count: Int) -> CGFloat { unit * CGFloat(count) }
    static let card: CGFloat = 28
    static let chip: CGFloat = 14
    static let hit: CGFloat = 44
    static let stagger: Double = 0.05
    static let staggerCap: Double = 0.36
}

enum FoyerStep {
    case display, title, headline, body, caption, micro

    var point: CGFloat {
        switch self {
        case .display: 34
        case .title: 28
        case .headline: 22
        case .body: 17
        case .caption: 14
        case .micro: 12
        }
    }

    var style: Font.TextStyle {
        switch self {
        case .display: .largeTitle
        case .title: .title
        case .headline: .title2
        case .body: .body
        case .caption: .caption
        case .micro: .caption2
        }
    }

    var lines: Int {
        switch self {
        case .display, .title: 2
        case .headline: 3
        default: 4
        }
    }

    func font(playful: Bool = false, heavy: Bool = false) -> Font {
        let name: String
        if playful {
            name = "Palatino-Italic"
        } else if heavy || self == .display || self == .title {
            name = "Palatino-Bold"
        } else {
            name = "Palatino-Roman"
        }
        return .custom(name, size: point, relativeTo: style)
    }
}

struct FoyerLine: View {
    var text: String
    var step: FoyerStep
    var playful: Bool = false
    var heavy: Bool = false
    var color: Color = DesignTokens.ink

    @Environment(\.dynamicTypeSize) private var typeSize
    @ScaledMetric(relativeTo: .largeTitle) private var displaySize: CGFloat = 34
    @ScaledMetric(relativeTo: .title) private var titleSize: CGFloat = 28
    @ScaledMetric(relativeTo: .title2) private var headlineSize: CGFloat = 22
    @ScaledMetric(relativeTo: .body) private var bodySize: CGFloat = 17
    @ScaledMetric(relativeTo: .caption) private var captionSize: CGFloat = 14
    @ScaledMetric(relativeTo: .caption2) private var microSize: CGFloat = 12

    var body: some View {
        Text(text)
            .font(face)
            .foregroundStyle(color)
            .lineLimit(step.lines)
            .minimumScaleFactor(0.75)
    }

    private var scaled: CGFloat {
        let raw: CGFloat
        switch step {
        case .display: raw = displaySize
        case .title: raw = titleSize
        case .headline: raw = headlineSize
        case .body: raw = bodySize
        case .caption: raw = captionSize
        case .micro: raw = microSize
        }
        return raw
    }

    private var face: Font {
        let name: String
        if typeSize >= .accessibility3 {
            name = "New York"
        } else if playful {
            name = "Palatino-Italic"
        } else if heavy || step == .display || step == .title {
            name = "Palatino-Bold"
        } else {
            name = "Palatino-Roman"
        }
        return .custom(name, size: scaled)
    }
}

enum FoyerCount {
    static let whole: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    static let money: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    static func count(_ value: Int) -> String {
        whole.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    static func amount(_ value: Double) -> String {
        money.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}

extension View {
    func foyerStagger(index: Int, shown: Bool, reduceMotion: Bool) -> some View {
        let delay = reduceMotion ? 0 : min(FoyerMeasure.stagger * Double(index), FoyerMeasure.staggerCap)
        return opacity(shown ? 1 : 0)
            .animation(.easeOut(duration: reduceMotion ? 0.2 : 0.28).delay(delay), value: shown)
    }

    func foyerKeyboardDone() -> some View {
        toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil,
                        from: nil,
                        for: nil
                    )
                }
            }
        }
    }
}

/// Cutout art in a fixed frame so a later fill does not shift the layout.
struct FoyerArt: View {
    var name: String
    var steps: Int

    var body: some View {
        Image(name)
            .resizable()
            .scaledToFit()
            .frame(width: FoyerMeasure.steps(steps), height: FoyerMeasure.steps(steps))
            .accessibilityHidden(true)
    }
}

/// Wide art band, clipped so it cannot paint over the neighbor.
struct FoyerBand: View {
    var name: String
    var steps: Int

    var body: some View {
        Image(name)
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity)
            .frame(height: FoyerMeasure.steps(steps))
            .clipped()
            .accessibilityHidden(true)
    }
}
