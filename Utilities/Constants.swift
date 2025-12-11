//
//  Constants.swift
//  XLogDecoder
//

import SwiftUI

enum AppColors {
    static let primaryGradient = LinearGradient(
        colors: [Color(hex: "007AFF"), Color(hex: "5856D6")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let successGradient = LinearGradient(
        colors: [Color(hex: "34C759"), Color(hex: "30D158")],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let accentBlue = Color(hex: "0A84FF")
    static let successGreen = Color(hex: "34C759")
    static let warningOrange = Color(hex: "FF9500")
    static let errorRed = Color(hex: "FF3B30")
    
    static let textPrimary = Color(hex: "1D1D1F")
    static let textSecondary = Color(hex: "86868B")
    static let textTertiary = Color(hex: "C7C7CC")
}

enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

enum CornerRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let xlarge: CGFloat = 20
}
