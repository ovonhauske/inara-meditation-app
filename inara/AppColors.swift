import SwiftUI

// MARK: - Color Tokens (from Figma Design System)
struct AppColors {
    // Background Colors
    // App background color (from Assets: color.xcassets → surface)
    static let surface = Color("surface", bundle: .main)
    static let playerSurface = Color("playerSurface", bundle: .main)

    // Text Colors
    // Primary text color (from Assets: color.xcassets → text)
    static let textPrimary = Color("text", bundle: .main) // #333333
    static let textSecondary = Color(red: 0.094, green: 0.075, blue: 0.067) // #181311 - Cacao/800
    
    // Accent Colors
    // Accent color (from Assets: color.xcassets → accent)
    static let accent = Color("accent", bundle: .main)
    static let accentDarker = Color(red: 0.345, green: 0.455, blue: 0.443) // #587471 - Tulum/600
    static let outline = Color("outline", bundle: .main)

    // UI Element Colors
    static let white = Color.white
    static let whiteTransparent = Color.white.opacity(0.3)
    static let whiteTransparentLight = Color.white.opacity(0.1)
    static let transsparent = Color.white.opacity(0.0)
    
    // Progress Colors
    static let progressStroke = Color(red: 0.09, green: 0.07, blue: 0.07).opacity(0.1)
    static let progressActive = Color(red: 0.451, green: 0.588, blue: 0.576) // #739693 - Tulum/500 (teal)
    static let progressPaused = Color(red: 1, green: 1, blue: 1) // White (from your change)
    
    // Button Colors
    static let buttonBackground = Color(red: 0.451, green: 0.588, blue: 0.576) // #739693 - Tulum/500
    static let buttonIcon = Color(red: 0.451, green: 0.588, blue: 0.576) // #739693 - Tulum/500
    
    // Circle Background Colors
    static let circleBackground = Color.white.opacity(0.3) // White with 30% opacity
    static let circleStroke = Color(red: 0.09, green: 0.07, blue: 0.07).opacity(0.1)
    
    // Sheet Colors
    static let sheetBackground = Color(red: 0.945, green: 0.933, blue: 0.890) // #f1eee3 - Luum/300
    static let sheetOverlay = Color.black.opacity(0.5) // rgba(24,19,17,0.5)
    static let sliderTrack = Color.white // #ffffff - Luum/100
    static let sliderProgress = Color(red: 0.345, green: 0.455, blue: 0.443) // #587471 - Tulum/600
    static let grabber = Color(red: 0.235, green: 0.235, blue: 0.263, opacity: 0.3) // rgba(60,60,67,0.3)
}


