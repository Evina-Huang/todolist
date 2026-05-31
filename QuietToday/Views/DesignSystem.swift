import SwiftUI

enum QuietColor {
    static let background = Color(red: 0.965, green: 0.957, blue: 0.925)
    static let surface = Color(red: 0.996, green: 0.992, blue: 0.972)
    static let ink = Color(red: 0.115, green: 0.122, blue: 0.108)
    static let secondaryInk = Color(red: 0.430, green: 0.455, blue: 0.407)
    static let mist = Color(red: 0.785, green: 0.818, blue: 0.745)
    static let sage = Color(red: 0.376, green: 0.506, blue: 0.420)
    static let line = Color(red: 0.855, green: 0.850, blue: 0.800)
}

extension View {
    func quietScreen() -> some View {
        background(QuietColor.background.ignoresSafeArea())
            .foregroundStyle(QuietColor.ink)
    }
}
