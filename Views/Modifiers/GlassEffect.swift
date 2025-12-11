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

// MARK: - Glass Effect Modifier (组件玻璃效果)
struct GlassEffect: ViewModifier {
    var cornerRadius: CGFloat = CornerRadius.large
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color(red: 0.15, green: 0.17, blue: 0.22).opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.08),
                                        Color.white.opacity(0.02)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.2),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Window Glass Background (全窗口背景 - 统一暗色)
struct WindowGlassBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // 统一深色渐变背景 (与Il2CppDumper风格一致)
                    LinearGradient(
                        colors: [
                            Color(red: 0.12, green: 0.14, blue: 0.18),
                            Color(red: 0.10, green: 0.12, blue: 0.16)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                    
                    // 底层玻璃效果
                    VisualEffectView(
                        material: .underWindowBackground,
                        blendingMode: .behindWindow
                    )
                    .ignoresSafeArea()
                    .opacity(0.3)
                }
            )
    }
}

// MARK: - Input Field Style (输入框/拖放区域样式)
struct InputFieldStyle: ViewModifier {
    var cornerRadius: CGFloat = CornerRadius.medium
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color(red: 0.12, green: 0.14, blue: 0.18))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
    }
}

// MARK: - Card Style (卡片样式)
struct CardStyle: ViewModifier {
    var cornerRadius: CGFloat = CornerRadius.large
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color(red: 0.13, green: 0.15, blue: 0.19))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
    }
}

extension View {
    func glassEffect(cornerRadius: CGFloat = CornerRadius.large) -> some View {
        modifier(GlassEffect(cornerRadius: cornerRadius))
    }
    
    func windowGlassBackground() -> some View {
        modifier(WindowGlassBackground())
    }
    
    func inputFieldStyle(cornerRadius: CGFloat = CornerRadius.medium) -> some View {
        modifier(InputFieldStyle(cornerRadius: cornerRadius))
    }
    
    func cardStyle(cornerRadius: CGFloat = CornerRadius.large) -> some View {
        modifier(CardStyle(cornerRadius: cornerRadius))
    }
}
