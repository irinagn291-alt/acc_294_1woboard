import SwiftUI
import UIKit

/// SPEC section 7. The only place these hex values live — reach colours
/// and the font family through here. Keep this file and its values.
enum DesignTokens {
    /// #0F0F0F
    static let bg = Color(red: 0.058824, green: 0.058824, blue: 0.058824)
    static let bgHex = "#0F0F0F"
    /// #1F1F1F
    static let surface = Color(red: 0.121569, green: 0.121569, blue: 0.121569)
    static let surfaceHex = "#1F1F1F"
    /// #FAFAFA
    static let ink = Color(red: 0.980392, green: 0.980392, blue: 0.980392)
    static let inkHex = "#FAFAFA"
    /// #DD5F9E
    static let accent = Color(red: 0.866667, green: 0.372549, blue: 0.619608)
    static let accentHex = "#DD5F9E"
    /// #B2B2B2
    static let muted = Color(red: 0.698039, green: 0.698039, blue: 0.698039)
    static let mutedHex = "#B2B2B2"
    static let fontFamily = "Palatino"

    /// UIKit faces of the same tokens. Views and sprite nodes use these, not new components.
    static let bgUI = UIColor(red: 0.058824, green: 0.058824, blue: 0.058824, alpha: 1)
    static let surfaceUI = UIColor(red: 0.121569, green: 0.121569, blue: 0.121569, alpha: 1)
    static let inkUI = UIColor(red: 0.980392, green: 0.980392, blue: 0.980392, alpha: 1)
    static let accentUI = UIColor(red: 0.866667, green: 0.372549, blue: 0.619608, alpha: 1)
    static let mutedUI = UIColor(red: 0.698039, green: 0.698039, blue: 0.698039, alpha: 1)
}
