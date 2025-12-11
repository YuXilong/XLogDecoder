//
//  LogPreviewPanel.swift
//  XLogDecoder
//

import SwiftUI

struct LogPreviewPanel: View {
    let logContent: String
    let state: DecoderState
    
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
            .background(Color.white.opacity(0.05))
            
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
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
            }
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.large)
                .strokeBorder(.white.opacity(0.2), lineWidth: 1)
        )
    }
}
