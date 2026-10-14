import SpriteKit
import SwiftUI

/// Lamp accent on the floor plan. One lamp per station for health and cover.
struct LampSpec: Equatable, Identifiable {
    var id: UUID
    var covered: Bool
    var dim: Bool
}

struct LampField: UIViewRepresentable {
    var lamps: [LampSpec]

    func makeUIView(context: Context) -> SKView {
        let view = SKView()
        view.allowsTransparency = true
        view.backgroundColor = .clear
        let scene = LampScene(size: CGSize(width: 320, height: 160))
        scene.scaleMode = .resizeFill
        scene.backgroundColor = .clear
        view.presentScene(scene)
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ view: SKView, context: Context) {
        guard let scene = view.scene as? LampScene else { return }
        scene.sync(lamps)
    }
}

final class LampScene: SKScene {
    private var lamps: [LampSpec] = []

    func sync(_ lamps: [LampSpec]) {
        self.lamps = lamps
        redraw()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        redraw()
    }

    private func redraw() {
        removeAllChildren()
        guard !lamps.isEmpty, size.width > 1, size.height > 1 else { return }
        let span = size.width / CGFloat(lamps.count)
        for (index, lamp) in lamps.enumerated() {
            let node = SKShapeNode(circleOfRadius: min(22, span * 0.22))
            node.fillColor = lamp.covered ? DesignTokens.accentUI : (lamp.dim ? DesignTokens.mutedUI : DesignTokens.inkUI)
            node.strokeColor = .clear
            node.position = CGPoint(
                x: span * (CGFloat(index) + 0.5),
                y: size.height * 0.62
            )
            addChild(node)
        }
    }

}
