import SwiftUI

// Cross-platform helpers so the same code builds on iOS and macOS.

extension View {
    func inlineNavigationTitle() -> some View {
#if os(iOS)
        self.navigationBarTitleDisplayMode(.inline)
#else
        self
#endif
    }
}

// Semantic colors that adapt across platforms and dark/light mode.
extension Color {
    static var cellBackground: Color { Color.primary.opacity(0.07) }
    static var cardBackground: Color  { Color.primary.opacity(0.04) }
}
