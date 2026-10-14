import SwiftUI

/// Permanent floor root. Station plan, ticket timeline, and bracket rail stay on screen.
struct FloorCanvas: View {
    @ObservedObject var desk: FloorDesk
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var shown = false
    @State private var stationName = ""
    @State private var slateStation: UUID?
    @State private var slateData = Data()
    @State private var success = false

    var body: some View {
        Group {
            if desk.chart.isBare {
                emptyFloor
            } else {
                populated
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignTokens.bg)
        .scrollDismissesKeyboard(.immediately)
        .foyerKeyboardDone()
        .sheet(item: $desk.sheet) { sheet in
            sheetBody(sheet)
        }
        .onAppear { shown = true }
    }

    private var populated: some View {
        ScrollViewReader { proxy in
        ScrollView {
            VStack(alignment: .leading, spacing: FoyerMeasure.steps(3)) {
                masthead
                FoyerBand(name: "clb_HeaderDecor", steps: 6)
                if let notice = desk.notice {
                    noticeBand(notice)
                }
                if success {
                    successBand
                }
                plan
                if slateStation != nil {
                    slatePanel
                        .id("slate")
                }
                tickets
                floatStrip
                rail
                destinations
            }
            .padding(.horizontal, FoyerMeasure.steps(3))
            .padding(.vertical, FoyerMeasure.steps(2))
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onChange(of: slateStation) { _, id in
            guard id != nil else { return }
            if reduceMotion {
                proxy.scrollTo("slate", anchor: .top)
            } else {
                withAnimation(.easeOut(duration: 0.28)) {
                    proxy.scrollTo("slate", anchor: .top)
                }
            }
        }
        }
    }

    private var masthead: some View {
        HStack(alignment: .top, spacing: FoyerMeasure.steps(2)) {
            VStack(alignment: .leading, spacing: FoyerMeasure.steps(1)) {
                phaseChip
                FoyerLine(text: "Ring the station", step: .display, heavy: true)
                FoyerLine(text: nextTap, step: .body, color: DesignTokens.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            FoyerArt(name: "clb_TwistHero", steps: 10)
        }
        .foyerStagger(index: 0, shown: shown, reduceMotion: reduceMotion)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var phaseChip: some View {
        FoyerLine(text: phaseWord, step: .caption, heavy: true)
            .padding(.horizontal, FoyerMeasure.steps(2))
            .padding(.vertical, FoyerMeasure.steps(1))
            .background(DesignTokens.surface, in: RoundedRectangle(cornerRadius: FoyerMeasure.chip))
            .accessibilityLabel(phaseWord)
    }

    private var phaseWord: String {
        switch desk.chart.phase {
        case .dark: "Dark"
        case .onShift: "OnShift"
        case .live: "Live"
        }
    }

    private var nextTap: String {
        if desk.chart.isBare {
            return "Place the first station, then clock a volunteer."
        }
        if let front = hero, front.posture == .covered {
            return "Tap Ring on \(front.name) to take the walk-in."
        }
        if desk.chart.phase == .dark {
            return "Open Shifts and clock a volunteer in."
        }
        return "Tap Cover on a healthy station, then ring it."
    }

    private var emptyFloor: some View {
        GeometryReader { geo in
        ScrollView {
        VStack(alignment: .leading, spacing: FoyerMeasure.steps(2)) {
            if let notice = desk.notice {
                noticeBand(notice)
            }
            FoyerArt(name: "clb_EmptyHome", steps: 16)
            FoyerLine(text: "The floor is empty", step: .title, heavy: true)
            FoyerLine(text: "Place the first station", step: .body, color: DesignTokens.muted)
            Spacer(minLength: FoyerMeasure.steps(2))
            TextField("Name", text: $stationName)
                .font(FoyerStep.body.font())
                .foregroundStyle(DesignTokens.ink)
                .padding(FoyerMeasure.steps(2))
                .background(DesignTokens.surface, in: RoundedRectangle(cornerRadius: FoyerMeasure.chip))
            Button {
                run { await desk.placeStation(name: stationName) }
            } label: {
                FoyerLine(text: "Place station", step: .headline, heavy: true, color: DesignTokens.bg)
            }
            .buttonStyle(FoyerFillStyle(busy: desk.busy))
            .disabled(desk.busy)
            destination("Settings", "Contact, replay, or reset", "gearshape", .settings)
        }
        .padding(FoyerMeasure.steps(3))
        .frame(maxWidth: .infinity, minHeight: geo.size.height, alignment: .leading)
        }
        }
        .foyerStagger(index: 1, shown: shown, reduceMotion: reduceMotion)
    }

    private var plan: some View {
        VStack(alignment: .leading, spacing: FoyerMeasure.steps(2)) {
            FoyerLine(text: "Floor", step: .headline, heavy: true)
            ZStack {
                LampField(lamps: desk.chart.stations.map { station in
                    let score = health(station)
                    return LampSpec(
                        id: station.id,
                        covered: station.posture == .covered,
                        dim: score < StationHealth.coverMinimum
                    )
                })
                .frame(maxWidth: .infinity)
                .frame(height: FoyerMeasure.steps(10))
                .allowsHitTesting(false)
                .accessibilityHidden(true)
                HStack(spacing: FoyerMeasure.unit) {
                    ForEach(desk.chart.stations) { station in
                        Button {
                            run { await desk.ring(stationID: station.id) }
                        } label: {
                            Color.clear
                                .frame(maxWidth: .infinity, minHeight: FoyerMeasure.hit)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(LampHitStyle())
                        .disabled(desk.busy)
                        .accessibilityLabel("Ring \(station.name), \(postureWord(station)), health \(FoyerCount.count(health(station)))")
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: FoyerMeasure.steps(10))
            if let hero {
                heroTicket(hero)
            }
            if !others.isEmpty {
                otherStations
            }
        }
        .foyerStagger(index: 1, shown: shown, reduceMotion: reduceMotion)
    }

    private var hero: Station? {
        desk.chart.stations.first { $0.posture == .covered } ?? desk.chart.stations.first
    }

    private var others: [Station] {
        guard let hero else { return [] }
        return desk.chart.stations.filter { $0.id != hero.id }
    }

    private func heroTicket(_ station: Station) -> some View {
        VStack(alignment: .leading, spacing: FoyerMeasure.steps(2)) {
            HStack(alignment: .top, spacing: FoyerMeasure.steps(2)) {
                FoyerArt(name: "clb_StationPlinth", steps: 12)
                VStack(alignment: .leading, spacing: FoyerMeasure.steps(1)) {
                    FoyerLine(text: postureWord(station), step: .caption, color: DesignTokens.accent)
                    FoyerLine(text: station.name, step: .title, heavy: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    FoyerLine(text: "Health \(FoyerCount.count(health(station)))", step: .headline, heavy: true)
                        .monospacedDigit()
                }
            }
            controls(station, accentRing: true)
        }
        .padding(FoyerMeasure.steps(2))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            Image("clb_CardBackdrop")
                .resizable()
                .scaledToFill()
                .overlay(.regularMaterial)
                .accessibilityHidden(true)
        }
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: FoyerMeasure.card))
        .onLongPressGesture(minimumDuration: 0.48) {
            openSlate(station)
        }
    }

    private var otherStations: some View {
        VStack(alignment: .leading, spacing: FoyerMeasure.steps(2)) {
            ForEach(others) { station in
                VStack(alignment: .leading, spacing: FoyerMeasure.steps(1)) {
                    HStack(alignment: .firstTextBaseline, spacing: FoyerMeasure.steps(2)) {
                        FoyerLine(text: station.name, step: .headline, heavy: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        FoyerLine(
                            text: "\(postureWord(station)) \(FoyerCount.count(health(station)))",
                            step: .caption,
                            color: DesignTokens.muted
                        )
                        .monospacedDigit()
                    }
                    controls(station, accentRing: false)
                }
                .onLongPressGesture(minimumDuration: 0.48) {
                    openSlate(station)
                }
            }
        }
        .padding(FoyerMeasure.steps(2))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: FoyerMeasure.card))
    }

    private func controls(_ station: Station, accentRing: Bool) -> some View {
        VStack(alignment: .leading, spacing: FoyerMeasure.steps(1)) {
            Button("Ring") {
                run { await desk.ring(stationID: station.id) }
            }
            .buttonStyle(FoyerFillStyle(tone: accentRing ? .accent : .quiet, busy: desk.busy))
            .disabled(desk.busy)
            .accessibilityLabel("Ring \(station.name)")
            Button("Cover") {
                run { await desk.cover(stationID: station.id) }
            }
            .buttonStyle(FoyerFillStyle(tone: .quiet, busy: desk.busy))
            .disabled(desk.busy || station.posture == .covered)
            .accessibilityLabel("Cover \(station.name)")
            Button("File incident") {
                openSlate(station)
            }
            .buttonStyle(FoyerFillStyle(tone: .quiet))
            .accessibilityLabel("File incident on \(station.name)")
            if health(station) < StationHealth.coverMinimum {
                Button("Maintain") {
                    run { await desk.maintain(stationID: station.id) }
                }
                .buttonStyle(FoyerFillStyle(tone: .quiet, busy: desk.busy))
                .disabled(desk.busy)
            }
        }
    }

    private var tickets: some View {
        VStack(alignment: .leading, spacing: FoyerMeasure.steps(2)) {
            FoyerLine(text: "Tonight", step: .headline, heavy: true)
            if ticketItems.isEmpty {
                FoyerArt(name: "clb_TicketStub", steps: 10)
                FoyerLine(text: "No tickets yet. Ring a covered station.", step: .body, color: DesignTokens.muted)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: FoyerMeasure.steps(2)) {
                        ForEach(Array(ticketItems.enumerated()), id: \.element.id) { index, item in
                            ticket(item, active: index == 0)
                        }
                    }
                    .padding(.vertical, FoyerMeasure.unit)
                }
            }
        }
        .foyerStagger(index: 2, shown: shown, reduceMotion: reduceMotion)
    }

    private var ticketItems: [TicketItem] {
        let today = DayKey.make(Date())
        let tills = desk.chart.tillMarks.filter { $0.daykey == today }.map {
            TicketItem(id: $0.id, title: desk.stationName($0.stationID), detail: FoyerCount.amount($0.amount), kind: "Till")
        }
        let gaps = desk.chart.gapMarks.filter { $0.daykey == today }.map {
            TicketItem(id: $0.id, title: desk.stationName($0.stationID), detail: "Gap", kind: "Open ring")
        }
        return (tills + gaps).reversed()
    }

    private func ticket(_ item: TicketItem, active: Bool) -> some View {
        VStack(alignment: .leading, spacing: FoyerMeasure.unit) {
            if active {
                FoyerBand(name: "clb_TicketStub", steps: 8)
            }
            FoyerLine(
                text: item.kind,
                step: .caption,
                playful: active,
                color: active ? DesignTokens.accent : DesignTokens.muted
            )
            FoyerLine(text: item.title, step: .headline, heavy: true)
            FoyerLine(text: item.detail, step: active ? .title : .headline, heavy: true)
                .monospacedDigit()
        }
        .padding(FoyerMeasure.steps(2))
        .frame(width: FoyerMeasure.steps(active ? 28 : 20), alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: FoyerMeasure.card))
    }

    private var floatStrip: some View {
        let today = DayKey.make(Date())
        let balance = desk.chart.float.balance(daykey: today, tillMarks: desk.chart.tillMarks)
        return HStack(alignment: .firstTextBaseline, spacing: FoyerMeasure.steps(2)) {
            FoyerArt(name: "clb_ControlFace", steps: 6)
            FoyerLine(text: "Float tonight", step: .caption, color: DesignTokens.muted)
            Spacer(minLength: FoyerMeasure.steps(1))
            FoyerLine(text: FoyerCount.amount(balance), step: .headline, heavy: true)
                .monospacedDigit()
        }
        .padding(FoyerMeasure.steps(2))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: FoyerMeasure.card))
        .foyerStagger(index: 3, shown: shown, reduceMotion: reduceMotion)
    }

    private var rail: some View {
        VStack(alignment: .leading, spacing: FoyerMeasure.steps(2)) {
            HStack(alignment: .center, spacing: FoyerMeasure.steps(2)) {
                FoyerArt(name: "clb_BoutPair", steps: 8)
                FoyerLine(text: "On deck", step: .headline, heavy: true)
            }
            if let bout = desk.chart.bouts.last(where: \.hasOnDeck) {
                FoyerLine(text: bout.title, step: .body, color: DesignTokens.muted)
                ForEach(bout.order, id: \.self) { entrantID in
                    let onDeck = bout.onDeck.contains(entrantID)
                    HStack(alignment: .center, spacing: FoyerMeasure.steps(1)) {
                        FoyerLine(
                            text: desk.entrantName(entrantID),
                            step: .body,
                            color: onDeck ? DesignTokens.ink : DesignTokens.muted
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                        if onDeck {
                            FoyerLine(text: "On deck", step: .caption, color: DesignTokens.accent)
                        } else {
                            FoyerLine(text: "Waiting", step: .caption, color: DesignTokens.muted)
                        }
                    }
                    if onDeck {
                        Button("Advance") {
                            run { await desk.advance(boutID: bout.id, entrantID: entrantID) }
                        }
                        .buttonStyle(FoyerFillStyle(busy: desk.busy))
                        .disabled(desk.busy)
                        .accessibilityLabel("Advance \(desk.entrantName(entrantID))")
                    }
                }
            } else {
                FoyerLine(text: "No pair is on deck. Open Bracket and seed a bout.", step: .body, color: DesignTokens.muted)
            }
        }
        .padding(FoyerMeasure.steps(2))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: FoyerMeasure.card))
        .foyerStagger(index: 4, shown: shown, reduceMotion: reduceMotion)
    }

    private var destinations: some View {
        VStack(alignment: .leading, spacing: FoyerMeasure.steps(1)) {
            FoyerLine(text: "Also tonight", step: .headline)
            VStack(alignment: .leading, spacing: FoyerMeasure.unit) {
                destination("Shifts", "Clock a volunteer in or out", "clock", .shifts)
                destination("Finance", "Reconcile tonight's float", "banknote", .finance)
                destination("Bracket", "Seat the next pair", "rectangle.split.2x1", .bracket)
                destination("Door", "Read a comp or member code", "qrcode", .door)
                destination("Settings", "Contact, replay, or reset", "gearshape", .settings)
            }
            .padding(FoyerMeasure.steps(2))
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: FoyerMeasure.card))
        }
        .foyerStagger(index: 5, shown: shown, reduceMotion: reduceMotion)
    }

    private func destination(_ title: String, _ detail: String, _ symbol: String, _ sheet: FloorDesk.Sheet) -> some View {
        Button {
            desk.sheet = sheet
        } label: {
            HStack(alignment: .center, spacing: FoyerMeasure.steps(2)) {
                Image(systemName: symbol)
                    .font(FoyerStep.headline.font())
                    .foregroundStyle(DesignTokens.ink)
                    .frame(width: FoyerMeasure.hit, height: FoyerMeasure.hit)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: FoyerMeasure.unit) {
                    FoyerLine(text: title, step: .headline, color: DesignTokens.ink)
                    FoyerLine(text: detail, step: .caption, color: DesignTokens.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(FoyerIndexStyle())
        .accessibilityLabel("\(title). \(detail)")
    }

    private var successBand: some View {
        HStack(spacing: FoyerMeasure.steps(2)) {
            FoyerArt(name: "clb_SuccessMark", steps: 6)
            FoyerLine(text: "Saved on this floor", step: .headline, heavy: true)
        }
        .padding(FoyerMeasure.steps(2))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: FoyerMeasure.card))
        .transition(.opacity)
    }

    private func noticeBand(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: FoyerMeasure.steps(1)) {
            FoyerLine(text: text, step: .body)
            Button("Retry") { Task { await desk.retryNotice() } }
                .buttonStyle(FoyerFillStyle(tone: .quiet))
        }
        .padding(FoyerMeasure.steps(2))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: FoyerMeasure.card))
    }

    private func postureWord(_ station: Station) -> String {
        station.posture == .covered ? "Covered" : "Open"
    }

    private func health(_ station: Station) -> Int {
        StationHealth.score(station, today: DayKey.make(Date()))
    }

    private func openSlate(_ station: Station) {
        slateData = Data()
        slateStation = station.id
    }

    private func run(_ work: @escaping () async -> Void) {
        Task {
            await work()
            guard desk.notice == nil else { return }
            let motion = reduceMotion
            withAnimation(.easeOut(duration: motion ? 0.2 : 0.28)) {
                success = true
            }
            try? await Task.sleep(nanoseconds: 900_000_000)
            withAnimation(.easeOut(duration: motion ? 0.2 : 0.28)) {
                success = false
            }
        }
    }

    @ViewBuilder
    private func sheetBody(_ sheet: FloorDesk.Sheet) -> some View {
        NavigationStack {
            switch sheet {
            case .shifts:
                ShiftsView(desk: desk)
            case .bracket:
                BracketView(desk: desk)
            case .finance:
                FinanceView(desk: desk)
            case .door:
                DoorView(desk: desk)
            case .settings:
                HouseSettings(desk: desk)
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(FoyerMeasure.card)
        .presentationBackground(.regularMaterial)
    }

    private var slatePanel: some View {
        VStack(alignment: .leading, spacing: FoyerMeasure.steps(2)) {
            HStack(alignment: .center, spacing: FoyerMeasure.steps(2)) {
                FoyerLine(
                    text: "Incident on \(desk.stationName(slateStation ?? UUID()))",
                    step: .title,
                    heavy: true
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                Button {
                    slateStation = nil
                } label: {
                    Image(systemName: "xmark")
                        .font(FoyerStep.headline.font())
                        .foregroundStyle(DesignTokens.ink)
                        .frame(width: FoyerMeasure.hit, height: FoyerMeasure.hit)
                        .background(DesignTokens.surface, in: Capsule())
                        .contentShape(Capsule())
                }
                .buttonStyle(FoyerIndexStyle(expands: false))
                .accessibilityLabel("Close")
            }
            FoyerLine(text: "Draw what failed. Saving lowers health.", step: .body, color: DesignTokens.muted)
            IncidentSlate(drawingData: $slateData)
                .frame(maxWidth: .infinity, minHeight: FoyerMeasure.steps(28))
                .clipShape(RoundedRectangle(cornerRadius: FoyerMeasure.card))
            Button("Save incident") {
                guard let stationID = slateStation else { return }
                Task {
                    await desk.fileIncident(stationID: stationID, drawing: slateData)
                    if desk.notice == nil {
                        slateStation = nil
                    }
                }
            }
            .buttonStyle(FoyerFillStyle(busy: desk.busy))
            .disabled(desk.busy)
        }
        .padding(FoyerMeasure.steps(2))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: FoyerMeasure.card))
    }
}

private struct LampHitStyle: ButtonStyle {
    @Environment(\.isEnabled) private var enabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background {
                Circle()
                    .fill(DesignTokens.accent.opacity(configuration.isPressed && enabled ? 0.45 : 0))
                    .frame(width: FoyerMeasure.hit, height: FoyerMeasure.hit)
            }
            .scaleEffect(reduceMotion || !configuration.isPressed || !enabled ? 1 : 0.96)
            .opacity(enabled ? 1 : 0.4)
            .animation(.easeOut(duration: reduceMotion ? 0.2 : 0.28), value: configuration.isPressed)
    }
}

private struct TicketItem: Identifiable {
    var id: UUID
    var title: String
    var detail: String
    var kind: String
}

