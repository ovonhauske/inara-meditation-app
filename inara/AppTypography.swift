import SwiftUI

// MARK: - Typography Styles

struct AppTypography {
    // Title: Used for card titles, detail view titles
    static let titleSize: CGFloat = 20
    static let titleKerning: CGFloat = 1
    static let titleWeight: Font.Weight = .semibold
    
    // Subtitle: Used for subtitles, timer, sheet labels
    static let subtitleSize: CGFloat = 15
    static let subtitleKerning: CGFloat = 0.75
    static let subtitleWeight: Font.Weight = .medium
    
    // Start Button
    static let startButtonSize: CGFloat = 34
    static let startButtonTracking: CGFloat = 4
    static let startButtonWeight: Font.Weight = .light
}

// MARK: - View Extensions

extension View {
    func titleStyle(color: Color = AppColors.tulum) -> some View {
        self
            .font(.system(size: AppTypography.titleSize, weight: AppTypography.titleWeight))
            .kerning(AppTypography.titleKerning)
            .textCase(.uppercase)
            .foregroundColor(color)
    }
    
    func subtitleStyle(color: Color = AppColors.tulum) -> some View {
        self
            .font(.system(size: AppTypography.subtitleSize, weight: AppTypography.subtitleWeight))
            .kerning(AppTypography.subtitleKerning)
            .foregroundColor(color)
    }
    
    func startButtonStyle(color: Color = AppColors.tulum) -> some View {
        self
            .font(.system(size: AppTypography.startButtonSize, weight: AppTypography.startButtonWeight))
            .tracking(AppTypography.startButtonTracking)
            .foregroundColor(color)
    }
}

