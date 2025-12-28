import SwiftUI

// MARK: - Reusable Animation Modifiers

/// A modifier that fades and slightly slides content when it becomes visible.
struct FadeSlideInOnAppear: ViewModifier {
    @Binding var isVisible: Bool
    var response: Double = 0.5
    var damping: Double = 0.85
    var offsetY: CGFloat = 12

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
                isVisible = false
            }
    }
}

extension View {
    /// Applies a fade and slight slide-in animation driven by a boolean binding.
    func fadeSlideIn(isVisible: Binding<Bool>, response: Double = 0.5, damping: Double = 0.85, offsetY: CGFloat = 12) -> some View {
        self.modifier(FadeSlideInOnAppear(isVisible: isVisible, response: response, damping: damping, offsetY: offsetY))
    }

    /// Applies a spring implicit animation tied to a changing value.
    func springAnimated<T: Equatable>(response: Double = 0.5, damping: Double = 0.85, value: T) -> some View {
        self.animation(.spring(response: response, dampingFraction: damping), value: value)
    }
}
