// View+CardStyle.swift
import SwiftUI

private enum Tokens {
    static let cardCorner: CGFloat = 30
}

private struct SolidCardStyle: ViewModifier {
    let fill: Color
    let outline: Color

    func body(content: Content) -> some View {
        content
            .background(
                fill,
                in: RoundedRectangle(cornerRadius: Tokens.cardCorner, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Tokens.cardCorner, style: .continuous)
                    .stroke(outline, lineWidth: 1)
            )
    }
}

extension View {
    /// No corner param exposed — always uses Tokens.cardCorner.
    func solidCardStyle(fill: Color, outline: Color) -> some View {
        modifier(SolidCardStyle(fill: fill, outline: outline))
    }
}
