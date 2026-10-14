import PencilKit
import SwiftUI

/// Incident slate on the floor. The saved drawing is the incident that lowers health.
struct IncidentSlate: UIViewRepresentable {
    @Binding var drawingData: Data

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.drawingPolicy = .anyInput
        canvas.tool = PKInkingTool(.pen, color: DesignTokens.inkUI, width: 3)
        canvas.backgroundColor = DesignTokens.surfaceUI
        canvas.delegate = context.coordinator
        canvas.isOpaque = false
        if let drawing = try? PKDrawing(data: drawingData) {
            canvas.drawing = drawing
        }
        return canvas
    }

    func updateUIView(_ canvas: PKCanvasView, context: Context) {
        context.coordinator.parent = self
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: IncidentSlate

        init(_ parent: IncidentSlate) {
            self.parent = parent
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            parent.drawingData = canvasView.drawing.dataRepresentation()
        }
    }
}
