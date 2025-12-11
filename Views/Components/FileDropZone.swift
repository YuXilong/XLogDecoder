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
        
        // 尝试多种类型标识符
        let fileURLIdentifier = UTType.fileURL.identifier
        let dataIdentifier = UTType.data.identifier
        
        let hasFileURL = provider.hasItemConformingToTypeIdentifier(fileURLIdentifier)
        let hasData = provider.hasItemConformingToTypeIdentifier(dataIdentifier)
        
        // 优先尝试 file URL
        if hasFileURL {
            loadFileURL(from: provider, typeIdentifier: fileURLIdentifier)
            return true
        }
        
        // 如果没有 file URL，尝试 data 类型
        if hasData {
            loadFileURL(from: provider, typeIdentifier: dataIdentifier)
            return true
        }
        
        return false
    }
    
    private func loadFileURL(from provider: NSItemProvider, typeIdentifier: String) {
        // 使用 loadItem 直接获取 URL，避免文件被复制到临时目录
        provider.loadItem(forTypeIdentifier: typeIdentifier, options: nil) { (item, error) in
            guard error == nil else { 
                print("Error loading item: \(error?.localizedDescription ?? "unknown")")
                return 
            }
            
            var finalURL: URL?
            
            // item 可能是 URL、Data 或其他类型
            if let url = item as? URL {
                // 直接是 URL
                finalURL = url
            } else if let data = item as? Data {
                // 如果是 Data，尝试解码为 URL 字符串
                if let urlString = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                    if urlString.hasPrefix("file://") {
                        finalURL = URL(string: urlString)
                    } else {
                        finalURL = URL(fileURLWithPath: urlString)
                    }
                }
            }
            
            guard let url = finalURL else { 
                print("Failed to get URL from item")
                return 
            }
            
            // 验证文件扩展名
            guard url.pathExtension == "xlog" else {
                print("Invalid file type: \(url.pathExtension)")
                return
            }
            
            DispatchQueue.main.async {
                self.onFileDrop(url)
            }
        }
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
