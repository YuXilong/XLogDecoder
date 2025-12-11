//
//  LogPreviewPanel.swift
//  XLogDecoder
//

import SwiftUI

struct LogPreviewPanel: View {
    let logContent: String
    let state: DecoderState
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 标题栏
            HStack {
                Image(systemName: "doc.text")
                    .foregroundColor(.secondary)
                Text("Log Preview")
                    .font(.headline)
                Spacer()
            }
            .padding()
            .background(
                colorScheme == .dark 
                    ? Color.white.opacity(0.03)
                    : Color.black.opacity(0.03)
            )
            
            // 分隔线
            Divider()
            
            // 日志内容
            ScrollView {
                if state == .idle {
                    // 空状态
                    Text("No logs yet")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .padding()
                } else {
                    // 有内容状态
                    Text(logContent.isEmpty ? "Decoding..." : logContent)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(.primary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.large)
                .fill(.regularMaterial)
        )
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.large)
                .strokeBorder(
                    colorScheme == .dark
                        ? Color.white.opacity(0.1)
                        : Color.black.opacity(0.1),
                    lineWidth: 1
                )
        )
        .shadow(
            color: colorScheme == .dark 
                ? .black.opacity(0.3)
                : .black.opacity(0.1),
            radius: 8,
            x: 0,
            y: 4
        )
    }
}
