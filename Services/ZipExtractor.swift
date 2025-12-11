//
//  ZipExtractor.swift
//  XLogDecoder
//

import Foundation

class ZipExtractor {
    
    /// 解压ZIP文件到临时目录
    func extract(zipURL: URL) throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("XLogDecoder_\(UUID().uuidString)")
        
        // 创建临时目录
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        print("📦 Extracting ZIP to: \(tempDir.path)")
        
        // 使用unzip命令解压
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-o", "-q", zipURL.path, "-d", tempDir.path]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            let errorData = pipe.fileHandleForReading.readDataToEndOfFile()
            let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            print("❌ Unzip failed: \(errorMessage)")
            throw ZipExtractorError.extractionFailed(errorMessage)
        }
        
        print("✅ ZIP extraction complete")
        return tempDir
    }
    
    /// 递归查找目录中所有的xlog文件
    func findXLogFiles(in directory: URL) throws -> [URL] {
        var xlogFiles: [URL] = []
        
        let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        )
        
        while let fileURL = enumerator?.nextObject() as? URL {
            if fileURL.pathExtension.lowercased() == "xlog" {
                xlogFiles.append(fileURL)
            }
        }
        
        print("📋 Found \(xlogFiles.count) xlog files in ZIP")
        return xlogFiles.sorted { $0.lastPathComponent < $1.lastPathComponent }
    }
    
    /// 清理临时目录
    func cleanup(directory: URL) {
        do {
            try FileManager.default.removeItem(at: directory)
            print("🧹 Cleaned up temp directory: \(directory.path)")
        } catch {
            print("⚠️ Failed to cleanup: \(error.localizedDescription)")
        }
    }
}

enum ZipExtractorError: LocalizedError {
    case extractionFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .extractionFailed(let message):
            return "ZIP extraction failed: \(message)"
        }
    }
}
