import SwiftUI

/// Bracket sheet. A seated bout shows the on-deck names and Advance.
/// An empty bracket asks for names, then Seed.
struct BracketSheet: View {
    @ObservedObject var desk: FloorDesk
    @State private var title = ""
    @State private var typed = ""
    @State private var names: [DraftEntrant] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FoyerMeasure.steps(3)) {
                if let notice = desk.notice {
                    FoyerLine(text: notice, step: .body)
                    Button("Retry") { Task { await desk.retryNotice() } }
                        .buttonStyle(FoyerFillStyle(tone: .quiet))
                }
                if let bout = desk.chart.bouts.last(where: \.hasOnDeck) {
                    seated(bout)
                } else {
                    seedForm
                }
            }
            .padding(FoyerMeasure.steps(3))
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(DesignTokens.bg)
        .navigationTitle("Bracket")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.immediately)
        .foyerKeyboardDone()
    }

    private func seated(_ bout: Bout) -> some View {
        let deck = bout.onDeck
        let pair = deck.map { desk.entrantName($0) }.joined(separator: " and ")
        return VStack(alignment: .leading, spacing: FoyerMeasure.steps(2)) {
            FoyerLine(text: bout.title, step: .display, heavy: true)
            FoyerLine(
                text: "\(pair) are on deck. Tap who wins this pair.",
                step: .body,
                color: DesignTokens.muted
            )
            ForEach(deck, id: \.self) { entrantID in
                let name = desk.entrantName(entrantID)
                Button {
                    Task { await desk.advance(boutID: bout.id, entrantID: entrantID) }
                } label: {
                    FoyerLine(text: "Advance \(name)", step: .headline, heavy: true, color: DesignTokens.bg)
                        .frame(maxWidth: .infinity, minHeight: FoyerMeasure.hit)
                }
                .buttonStyle(FoyerFillStyle(busy: desk.busy))
                .disabled(desk.busy)
                .accessibilityLabel("Advance \(name)")
            }
            let waiting = bout.order.filter { !deck.contains($0) }
            if !waiting.isEmpty {
                FoyerLine(text: "Still seated", step: .headline, heavy: true)
                ForEach(waiting, id: \.self) { entrantID in
                    FoyerLine(text: desk.entrantName(entrantID), step: .body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(FoyerMeasure.steps(2))
                        .background(DesignTokens.surface, in: RoundedRectangle(cornerRadius: FoyerMeasure.card))
                }
            }
        }
    }

    private var seedForm: some View {
        VStack(alignment: .leading, spacing: FoyerMeasure.steps(2)) {
            FoyerLine(text: "Seat a bout", step: .display, heavy: true)
            FoyerLine(
                text: "Add two, four, or eight names, then seed the bracket.",
                step: .body,
                color: DesignTokens.muted
            )
            TextField("Bout name", text: $title)
                .font(FoyerStep.body.font())
                .foregroundStyle(DesignTokens.ink)
                .padding(FoyerMeasure.steps(2))
                .background(DesignTokens.surface, in: RoundedRectangle(cornerRadius: FoyerMeasure.chip))
            HStack(spacing: FoyerMeasure.steps(1)) {
                TextField("Person name", text: $typed)
                    .font(FoyerStep.body.font())
                    .foregroundStyle(DesignTokens.ink)
                    .padding(FoyerMeasure.steps(2))
                    .background(DesignTokens.surface, in: RoundedRectangle(cornerRadius: FoyerMeasure.chip))
                Button {
                    let trimmed = typed.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty { names.append(DraftEntrant(title: trimmed)) }
                    typed = ""
                } label: {
                    FoyerLine(text: "Add", step: .headline, heavy: true, color: DesignTokens.ink)
                }
                .buttonStyle(FoyerFillStyle(tone: .quiet))
                .frame(width: FoyerMeasure.steps(16))
            }
            if names.isEmpty {
                FoyerLine(text: "Names you add sit here until you seed.", step: .body, color: DesignTokens.muted)
            } else {
                ForEach(names) { name in
                    FoyerLine(text: name.title, step: .body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(FoyerMeasure.steps(2))
                        .background(DesignTokens.surface, in: RoundedRectangle(cornerRadius: FoyerMeasure.card))
                }
            }
            Button {
                Task { await desk.seedBout(title: title, names: names.map(\.title)) }
            } label: {
                FoyerLine(text: "Seed bout", step: .headline, heavy: true, color: DesignTokens.bg)
                    .frame(maxWidth: .infinity, minHeight: FoyerMeasure.hit)
            }
            .buttonStyle(FoyerFillStyle(busy: desk.busy))
            .disabled(desk.busy)
        }
    }
}

private struct DraftEntrant: Identifiable {
    let id = UUID()
    var title: String
}

/// Bracket screen for the live driver. Seed interleaves a power-of-two bout.
struct BracketView: View {
    @ObservedObject var desk: FloorDesk

    var body: some View {
        BracketSheet(desk: desk)
    }
}
