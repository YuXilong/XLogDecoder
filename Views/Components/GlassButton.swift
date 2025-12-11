//
//  GlassButton.swift
//  XLogDecoder
//

import SwiftUI

struct GlassButton: View {
    let title: String
    let icon: String
    let isPrimary: Bool
    let isEnabled: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    init(
        title: String,
        icon: String,
        isPrimary: Bool = false,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isPrimary = isPrimary
        self.isEnabled = isEnabled
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(isPrimary ? .white : .primary)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background {
                if isPrimary {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AppColors.primaryGradient)
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.regularMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white.opacity(0.1))
                        )
                }
            }
            .shadow(
                color: isPrimary ? .blue.opacity(0.3) : .black.opacity(0.05),
                radius: isHovered ? 8 : 4,
                x: 0,
                y: isHovered ? 4 : 2
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .opacity(isEnabled ? 1.0 : 0.5)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering && isEnabled
            }
        }
    }
}
