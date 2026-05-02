import SwiftUI

struct AntigravityTheme {
    // MARK: - Colors
    static let mint = Color(red: 0.88, green: 0.98, blue: 0.95)
    static let lavender = Color(red: 0.94, green: 0.92, blue: 1.0)
    static let softRose = Color(red: 1.0, green: 0.92, blue: 0.94)
    static let skyBlue = Color(red: 0.92, green: 0.96, blue: 1.0)
    
    static let textPrimary = Color(white: 0.15)
    static let textSecondary = Color(white: 0.45)
    static let textTertiary = Color(white: 0.65)
    
    static let cardBackground = Color.white.opacity(0.85)
    static let glassBackground = Color.white.opacity(0.4)
    
    // MARK: - Gradients
    static let backgroundGradient = LinearGradient(
        colors: [skyBlue, lavender, softRose],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let accentGradient = LinearGradient(
        colors: [Color(red: 0.4, green: 0.5, blue: 0.9), Color(red: 0.6, green: 0.4, blue: 0.9)],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    // MARK: - Design Tokens
    static let cornerRadiusLarge: CGFloat = 32
    static let cornerRadiusMedium: CGFloat = 20
    static let shadowRadius: CGFloat = 12
    static let shadowOffset = CGSize(width: 0, height: 4)
    static let shadowColor = Color.black.opacity(0.05)
    
    // MARK: - Typography
    static func titleFont() -> Font {
        .system(size: 34, weight: .bold, design: .rounded)
    }
    
    static func headlineFont() -> Font {
        .system(size: 24, weight: .semibold, design: .rounded)
    }
    
    static func bodyFont() -> Font {
        .system(size: 17, weight: .medium, design: .rounded)
    }
    
    static func captionFont() -> Font {
        .system(size: 14, weight: .regular, design: .rounded)
    }
}

// MARK: - View Modifiers
struct AntigravityCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(24)
            .background(AntigravityTheme.cardBackground)
            .cornerRadius(AntigravityTheme.cornerRadiusLarge)
            .shadow(color: AntigravityTheme.shadowColor, radius: AntigravityTheme.shadowRadius, x: 0, y: 4)
    }
}

extension View {
    func antigravityCard() -> some View {
        self.modifier(AntigravityCard())
    }
}
