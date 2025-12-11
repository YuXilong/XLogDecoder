//
//  LiquidProgressBar.swift
//  XLogDecoder
//

import SwiftUI

struct LiquidProgressBar: View {
    let progress: Double
    @State private var animatedProgress: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // 背景轨道
                RoundedRectangle(cornerRadius: 3)
                    .fill(.ultraThinMaterial)
                    .frame(height: 6)
                
                // 进度填充
                RoundedRectangle(cornerRadius: 3)
                    .fill(
                        progress >= 1.0 ?
                        AppColors.successGradient :
                        AppColors.primaryGradient
                    )
                    .frame(width: geometry.size.width * animatedProgress, height: 6)
                    .shadow(color: .blue.opacity(0.5), radius: 4, x: 0, y: 2)
            }
        }
        .frame(height: 6)
        .onChange(of: progress) { oldValue, newValue in
            withAnimation(.easeInOut(duration: 0.5)) {
                animatedProgress = newValue
            }
        }
        .onAppear {
            animatedProgress = progress
        }
    }
}
