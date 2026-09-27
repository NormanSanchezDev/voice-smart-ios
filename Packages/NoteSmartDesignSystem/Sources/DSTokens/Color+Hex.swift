import SwiftUI
import UIKit

extension UInt32 {
    /// `0xRRGGBB` to a 0...1 channel pair.
    var rgb: (red: Double, green: Double, blue: Double) {
        (
            red: Double((self >> 16) & 0xFF) / 255,
            green: Double((self >> 8) & 0xFF) / 255,
            blue: Double(self & 0xFF) / 255
        )
    }
}

extension UIColor {
    convenience init(hex: UInt32, alpha: Double = 1) {
        let c = hex.rgb
        self.init(red: c.red, green: c.green, blue: c.blue, alpha: alpha)
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(uiColor: UIColor(hex: hex))
    }

    /// A color that resolves per trait collection, so the design system needs no
    /// asset catalog and both appearances stay defined next to each other.
    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { traits in
            UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }

    /// Relative luminance, used to pick readable foreground colors on top of a fill.
    var luminance: Double {
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        func channel(_ c: CGFloat) -> CGFloat {
            c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b)
    }

    /// Black or white, whichever stays readable on this color.
    var readableForeground: Color {
        luminance > 0.45 ? Color(hex: 0x14141A) : .white
    }
}
