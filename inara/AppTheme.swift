//
//  AppTheme.swift
//  inara
//
//  Consolidated design system: colors, typography, icons, and animations
//

import SwiftUI

// MARK: - Colors

struct AppColors {
    static let surface = Color("surface", bundle: .main)
    static let tulum = Color("tulum", bundle: .main)
    static let outline = Color("outline", bundle: .main)
    static let white = Color.white
    static let transparent = Color.white.opacity(0.0)
}

// MARK: - Typography

struct AppTypography {
    static let titleSize: CGFloat = 20
    static let titleKerning: CGFloat = 1
    static let titleWeight: Font.Weight = .regular
    
    static let subtitleSize: CGFloat = 15
    static let subtitleKerning: CGFloat = 0.75
    static let subtitleWeight: Font.Weight = .regular
    
    static let startButtonSize: CGFloat = 34
    static let startButtonTracking: CGFloat = 4
    static let startButtonWeight: Font.Weight = .light
}

// MARK: - Icons

struct AppIconStyle {
    static let size: CGFloat = 17
    static let weight: Font.Weight = .medium
    
    static let largeSize: CGFloat = 34
    static let largeWeight: Font.Weight = .medium
}

// MARK: - Animation

enum AppAnimation {
    static let springResponse: Double = 1
    static let springDamping: Double = 0.85

    static var spring: Animation {
        .spring(response: springResponse, dampingFraction: springDamping)
    }
}

// MARK: - View Extensions

extension View {
    // Typography
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
    
    // Icons
    func iconStyle(color: Color = AppColors.tulum) -> some View {
        self
            .font(.system(size: AppIconStyle.size, weight: AppIconStyle.weight))
            .foregroundColor(color)
    }
    
    func largeIconStyle(color: Color = AppColors.tulum) -> some View {
        self
            .font(.system(size: AppIconStyle.largeSize, weight: AppIconStyle.largeWeight))
            .foregroundColor(color)
    }
    
    // Animation
    func fadeSlideIn(isVisible: Binding<Bool>, response: Double = AppAnimation.springResponse, damping: Double = AppAnimation.springDamping, offsetY: CGFloat = 12) -> some View {
        self.modifier(FadeSlideInModifier(isVisible: isVisible, response: response, damping: damping, offsetY: offsetY))
    }

    func springAnimated<T: Equatable>(response: Double = AppAnimation.springResponse, damping: Double = AppAnimation.springDamping, value: T) -> some View {
        self.animation(.spring(response: response, dampingFraction: damping), value: value)
    }
}

// MARK: - Animation Modifier

struct FadeSlideInModifier: ViewModifier {
    @Binding var isVisible: Bool
    var response: Double
    var damping: Double
    var offsetY: CGFloat

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : offsetY)
            .animation(.spring(response: response, dampingFraction: damping), value: isVisible)
            .onAppear {
                isVisible = false
                withAnimation(.spring(response: response, dampingFraction: damping)) {
                    isVisible = true
                }
            }
            .onDisappear {
                withAnimation(.spring(response: response, dampingFraction: damping)) {
                    isVisible = false
                }
            }
    }
}

