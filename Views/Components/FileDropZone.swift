//
//  FileDropZone.swift
//  XLogDecoder
//

import SwiftUI
import UniformTypeIdentifiers

struct FileDropZone: View {
    @Binding var isTargeted: Bool
    let onFileDrop: (URL) -> Void
    let state: DecoderState
    
    var body: some View {
        VStack(spacing: Spacing.md) {
            // 图标和文本根据状态变化
            if case .decoding(let fileName, let fileSize) = state {
                // 解码中状态
                VStack(spacing: Spacing.md) {
                    Image(systemName: "doc.badge.gearshape")
                        .font(.system(size: 64))
                        .foregroundStyle(AppColors.primaryGradient)
                    
                    VStack(spacing: Spacing.xs) {
                        Text(fileName)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(formatFileSize(fileSize))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    ProgressView()
                        .scaleEffect(0.8)
                }
            } else if case .complete(let fileName, let inputSize, let outputSize, let duration) = state {
                // 完成状态
                VStack(spacing: Spacing.md) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(AppColors.successGreen)
                    
                    Text("Decoding Complete!")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(fileName)
                            .font(.caption)
                        Text("\(formatFileSize(inputSize)) → \(formatFileSize(outputSize))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Completed in \(String(format: "%.1f", duration))s")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                // 初始状态
                Image(systemName: "doc.badge.plus")
                    .font(.system(size: 64))
                    .foregroundStyle(
                        isTargeted ?
                        AppColors.primaryGradient :
                        LinearGradient(colors: [.gray], startPoint: .top, endPoint: .bottom)
                    )
                    .scaleEffect(isTargeted ? 1.1 : 1.0)
                
                VStack(spacing: Spacing.xs) {
                    Text("Drop .xlog files here")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("or click to browse")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 280)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.large)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.large)
                .strokeBorder(
                    isTargeted ?
                    AppColors.primaryGradient :
                    LinearGradient(colors: [.gray.opacity(0.3)], startPoint: .top, endPoint: .bottom),
                    style: StrokeStyle(lineWidth: 2, dash: [10, 5])
                )
        )
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            handleDrop(providers)
        }
        .onTapGesture {
            selectFile()
        }
        .animation(.spring(response: 0.3), value: isTargeted)
    }
    
    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        
        provider.loadDataRepresentation(forTypeIdentifier: UTType.fileURL.identifier) { data, error in
            guard let data = data,
                  let path = String(data: data, encoding: .utf8),
                  let url = URL(string: path) else { return }
            
            // 验证文件扩展名
            guard url.pathExtension == "xlog" else { return }
            
            DispatchQueue.main.async {
                onFileDrop(url)
            }
        }
        
        return true
    }
    
    private func selectFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [UTType(filenameExtension: "xlog")!]
        
        if panel.runModal() == .OK, let url = panel.url {
            onFileDrop(url)
        }
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
