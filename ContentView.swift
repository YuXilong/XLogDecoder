//
//  ContentView.swift
//  XLogDecoder
//

import SwiftUI

struct ContentView: View {
    @StateObject private var decoder = XLogDecoder()
    @State private var isTargeted = false
    
    var body: some View {
        HStack(spacing: Spacing.lg) {
            // 左侧主区域 (65%)
            VStack(spacing: Spacing.lg) {
                // 标题
                HStack {
                    Text("XLog Decoder")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.primaryGradient)
                    
                    Spacer()
                    
                    if decoder.state.isDecoding {
                        ProgressView()
                            .scaleEffect(0.7)
                    } else if decoder.state.isComplete {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AppColors.successGreen)
                    }
                }
                .padding(.top, Spacing.lg)
                
                // 文件拖放区域
                FileDropZone(
                    isTargeted: $isTargeted,
                    onFileDrop: { url in
                        Task {
                            await decoder.decodeFile(at: url)
                        }
                    },
                    state: decoder.state
                )
                
                // 进度区域
                VStack(spacing: Spacing.sm) {
                    HStack {
                        Text(decoder.status)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if decoder.state.isDecoding {
                            Text("\(Int(decoder.progress * 100))%")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else if decoder.state.isComplete {
                            Text("100%")
                                .font(.subheadline)
                                .foregroundColor(AppColors.successGreen)
                        }
                    }
                    
                    LiquidProgressBar(progress: decoder.progress)
                    
                    if decoder.state.isDecoding && !decoder.speed.isEmpty {
                        HStack {
                            Text(decoder.speed)
                            Text("•")
                            Text(decoder.timeRemaining)
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
                .frame(height: 60)
                
                // 操作按钮
                HStack(spacing: Spacing.md) {
                    if decoder.state.isComplete {
                        GlassButton(
                            title: "Decode Another",
                            icon: "arrow.clockwise",
                            isPrimary: false,
                            isEnabled: true
                        ) {
                            decoder.reset()
                        }
                    }
                    
                    Spacer()
                    
                    GlassButton(
                        title: "Open in Console",
                        icon: "terminal.fill",
                        isPrimary: decoder.state.isComplete,
                        isEnabled: decoder.state.isComplete
                    ) {
                        decoder.openInConsole()
                    }
                    
                    GlassButton(
                        title: "Open in VS Code",
                        icon: "chevron.left.forwardslash.chevron.right",
                        isPrimary: decoder.state.isComplete,
                        isEnabled: decoder.state.isComplete
                    ) {
                        decoder.openInVSCode()
                    }
                }
                .frame(height: 50)
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, Spacing.xl)
            
            // 右侧日志预览面板 (35%)
            LogPreviewPanel(
                logContent: decoder.logPreview,
                state: decoder.state
            )
            .frame(width: 350)
            .padding(.trailing, Spacing.lg)
            .padding(.vertical, Spacing.lg)
        }
        .frame(minWidth: 900, minHeight: 600)
        .background(.ultraThinMaterial)
        .background(
            LinearGradient(
                colors: [
                    Color.white.opacity(0.3),
                    Color.blue.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

#Preview {
    ContentView()
        .frame(width: 1100, height: 700)
}
