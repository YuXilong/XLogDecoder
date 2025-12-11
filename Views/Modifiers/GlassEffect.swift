//
//  GlassEffect.swift
//  XLogDecoder
//

import SwiftUI

struct GlassEffect: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.large)
                    .fill(.white.opacity(0.3))
                    .background(.regularMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.large)
                    .strokeBorder(.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

extension View {
    func glassEffect() -> some View {
        modifier(GlassEffect())
    }
}
