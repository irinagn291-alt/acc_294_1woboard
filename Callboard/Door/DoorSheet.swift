import AVFoundation
import SwiftUI
import UIKit

/// Door sheet. Captures a QR for a comp or a member code. Session stops on disappear.
struct DoorSheet: View {
    @ObservedObject var desk: FloorDesk
    @Environment(\.scenePhase) private var scenePhase
    @State private var status = AVCaptureDevice.authorizationStatus(for: .video)
    @State private var manual = ""
    @State private var accepted: String?
    @State private var running = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FoyerMeasure.steps(2)) {
                FoyerArt(name: "clb_DoorCrest", steps: 12)
                FoyerLine(text: "Door code", step: .title, heavy: true)
                FoyerLine(text: "Read a comp or a member code. Digits only, eight to fourteen.", step: .body, color: DesignTokens.muted)
                if let accepted {
                    FoyerLine(text: "Filed \(accepted)", step: .headline, heavy: true)
                        .monospacedDigit()
                }
                cameraBlock
                TextField("Type a code", text: $manual)
                    .font(FoyerStep.body.font())
                    .foregroundStyle(DesignTokens.ink)
                    .keyboardType(.numberPad)
                    .padding(FoyerMeasure.steps(2))
                    .background(DesignTokens.surface, in: RoundedRectangle(cornerRadius: FoyerMeasure.chip))
                Button("File code") { file(manual) }
                    .buttonStyle(FoyerFillStyle())
                #if targetEnvironment(simulator)
                FoyerLine(text: "Sample codes", step: .caption, color: DesignTokens.muted)
                Button("012345678905") { file("012345678905") }
                    .buttonStyle(FoyerFillStyle(tone: .quiet))
                Button("1234567890123") { file("member 1234567890123 door") }
                    .buttonStyle(FoyerFillStyle(tone: .quiet))
                #endif
            }
            .padding(FoyerMeasure.steps(2))
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(DesignTokens.bg)
        .navigationTitle("Door")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.immediately)
        .foyerKeyboardDone()
        .onDisappear { running = false }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { running = false }
        }
    }

    @ViewBuilder
    private var cameraBlock: some View {
        switch status {
        case .notDetermined:
            FoyerLine(text: "The next step asks the system about the camera.", step: .body, color: DesignTokens.muted)
            Button("Continue") {
                AVCaptureDevice.requestAccess(for: .video) { _ in
                    Task { @MainActor in
                        status = AVCaptureDevice.authorizationStatus(for: .video)
                    }
                }
            }
            .buttonStyle(FoyerFillStyle())
        case .authorized:
            DoorPreview(running: running) { raw in
                file(raw)
            }
            .frame(maxWidth: .infinity, minHeight: FoyerMeasure.steps(28))
            .clipShape(RoundedRectangle(cornerRadius: FoyerMeasure.card))
        case .denied, .restricted:
            FoyerLine(text: "The camera is unavailable. You can still type a code, or open Settings.", step: .body)
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(FoyerFillStyle(tone: .quiet))
        @unknown default:
            FoyerLine(text: "The camera state is unknown. Type the code instead.", step: .body)
        }
    }

    private func file(_ raw: String) {
        guard let code = DoorCode.accept(raw) else {
            desk.report("That code needs a run of 8 to 14 digits.")
            return
        }
        accepted = code
        desk.report("")
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

/// Door screen for the live driver. A QR or a typed code files a comp.
struct DoorView: View {
    @ObservedObject var desk: FloorDesk

    var body: some View {
        DoorSheet(desk: desk)
    }
}

struct DoorPreview: UIViewRepresentable {
    var running: Bool
    var onCode: (String) -> Void

    func makeUIView(context: Context) -> DoorHost {
        let host = DoorHost()
        host.onCode = onCode
        return host
    }

    func updateUIView(_ host: DoorHost, context: Context) {
        host.onCode = onCode
        if running {
            host.start()
        } else {
            host.stop()
        }
    }

    static func dismantleUIView(_ host: DoorHost, coordinator: ()) {
        host.stop()
    }
}

final class DoorHost: UIView, AVCaptureMetadataOutputObjectsDelegate {
    var onCode: ((String) -> Void)?
    private let session = AVCaptureSession()
    private var started = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = DesignTokens.surfaceUI
    }

    required init?(coder: NSCoder) {
        return nil
    }

    func start() {
        guard !started else {
            if !session.isRunning { session.startRunning() }
            return
        }
        started = true
        session.beginConfiguration()
        session.sessionPreset = .high
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            session.commitConfiguration()
            return
        }
        session.addInput(input)
        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else {
            session.commitConfiguration()
            return
        }
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        output.metadataObjectTypes = [.qr]
        session.commitConfiguration()
        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = bounds
        layer.addSublayer(preview)
        session.startRunning()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.sublayers?.forEach { $0.frame = bounds }
    }

    func stop() {
        if session.isRunning { session.stopRunning() }
    }

    nonisolated func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let value = object.stringValue else { return }
        Task { @MainActor in
            self.onCode?(value)
            self.stop()
        }
    }
}
