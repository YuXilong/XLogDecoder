//
//  GlassEffect.swift
//  XLogDecoder
//

import SwiftUI
import AppKit

// MARK: - Visual Effect View (液态玻璃效果)
struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

// MARK: - Glass Effect Modifier
struct GlassEffect: ViewModifier {
    var cornerRadius: CGFloat = CornerRadius.large
    var material: NSVisualEffectView.Material = .hudWindow
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // 底层玻璃效果
                    VisualEffectView(
                        material: material,
                        blendingMode: .behindWindow
                    )
                    
                    // 渐变叠加层
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.15),
                            Color.white.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
    }
}

// MARK: - Window Glass Effect (全窗口背景)
struct WindowGlassBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // 深色渐变背景
                    LinearGradient(
                        colors: [
                            Color(red: 0.1, green: 0.12, blue: 0.18),
                            Color(red: 0.08, green: 0.1, blue: 0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    // 液态玻璃效果
                    VisualEffectView(
                        material: .sidebar,
                        blendingMode: .behindWindow
                    )
                    .opacity(0.5)
                    
                    // 微光泽叠加
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.05),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            )
    }
}

extension View {
    func glassEffect(cornerRadius: CGFloat = CornerRadius.large) -> some View {
        modifier(GlassEffect(cornerRadius: cornerRadius))
    }
    
    func windowGlassBackground() -> some View {
        modifier(WindowGlassBackground())
    }
}
