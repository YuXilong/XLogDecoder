//
//  XLogDecoder.swift
//  XLogDecoder
//

import Foundation
import SwiftUI

@MainActor
class XLogDecoder: ObservableObject {
    @Published var state: DecoderState = .idle
    @Published var progress: Double = 0
    @Published var status: String = "Ready to decode"
    @Published var logPreview: String = ""
    @Published var decodedFileURL: URL?
    @Published var speed: String = ""
    @Published var timeRemaining: String = ""
    
    private let headerParser = HeaderParser()
    private let decompressor = ZlibDecompressor()
    private let xorDecryptor = XORDecryptor()
    private let teaDecryptor = TEADecryptor()
    private let zipExtractor = ZipExtractor()
    
    private var startTime: Date?
    private var lastSequence: UInt16 = 0
    
    func decodeFile(at url: URL) async {
        startTime = Date()
        lastSequence = 0
        
        // 检查是否是ZIP文件
        if url.pathExtension.lowercased() == "zip" {
            await decodeZipFile(at: url)
        } else {
            await decodeSingleFile(at: url)
        }
    }
    
    /// 解压并解码ZIP中的所有xlog文件
    private func decodeZipFile(at url: URL) async {
        var tempDir: URL?
        
        do {
            let fileAttributes = try FileManager.default.attributesOfItem(atPath: url.path)
            let fileSize = fileAttributes[.size] as? Int64 ?? 0
            
            state = .decoding(fileName: url.lastPathComponent, fileSize: fileSize)
            status = "Extracting ZIP file..."
            
            // 解压ZIP
            tempDir = try zipExtractor.extract(zipURL: url)
            
            // 查找所有xlog文件
            let xlogFiles = try zipExtractor.findXLogFiles(in: tempDir!)
            
            if xlogFiles.isEmpty {
                throw DecoderError.noXLogFilesFound
            }
            
            status = "Found \(xlogFiles.count) xlog files, decoding..."
            
            var processedCount = 0
            var lastOutputURL: URL?
            var totalOutputSize: Int64 = 0
            
            // 解码每个xlog文件
            for xlogURL in xlogFiles {
                status = "Decoding \(xlogURL.lastPathComponent) (\(processedCount + 1)/\(xlogFiles.count))..."
                
                if let outputURL = try await decodeSingleXLogFile(at: xlogURL, outputDir: url.deletingLastPathComponent()) {
                    lastOutputURL = outputURL
                    if let attrs = try? FileManager.default.attributesOfItem(atPath: outputURL.path),
                       let size = attrs[.size] as? Int64 {
                        totalOutputSize += size
                    }
                }
                
                processedCount += 1
                updateProgress(Double(processedCount) / Double(xlogFiles.count))
            }
            
            // 清理临时目录
            if let dir = tempDir {
                zipExtractor.cleanup(directory: dir)
            }
            
            decodedFileURL = lastOutputURL
            
            let duration = Date().timeIntervalSince(startTime ?? Date())
            state = .complete(
                fileName: "\(xlogFiles.count) files from \(url.lastPathComponent)",
                inputSize: fileSize,
                outputSize: totalOutputSize,
                duration: duration
            )
            status = "Complete! Decoded \(xlogFiles.count) files"
            progress = 1.0
            
        } catch {
            // 清理临时目录
            if let dir = tempDir {
                zipExtractor.cleanup(directory: dir)
            }
            state = .error(error.localizedDescription)
            status = "Error: \(error.localizedDescription)"
        }
    }
    
    /// 解码单个xlog文件
    private func decodeSingleFile(at url: URL) async {
        do {
            // 获取文件信息
            let fileAttributes = try FileManager.default.attributesOfItem(atPath: url.path)
            let fileSize = fileAttributes[.size] as? Int64 ?? 0
            
            state = .decoding(fileName: url.lastPathComponent, fileSize: fileSize)
            status = "Reading file..."
            
            if let outputURL = try await decodeSingleXLogFile(at: url, outputDir: url.deletingLastPathComponent()) {
                decodedFileURL = outputURL
                
                let duration = Date().timeIntervalSince(startTime ?? Date())
                let outputAttrs = try FileManager.default.attributesOfItem(atPath: outputURL.path)
                let outputSize = outputAttrs[.size] as? Int64 ?? 0
                
                state = .complete(
                    fileName: url.lastPathComponent,
                    inputSize: fileSize,
                    outputSize: outputSize,
                    duration: duration
                )
                status = "Complete!"
                progress = 1.0
            }
            
        } catch {
            state = .error(error.localizedDescription)
            status = "Error: \(error.localizedDescription)"
        }
    }
    
    /// 解码单个xlog文件并返回输出URL
    private func decodeSingleXLogFile(at url: URL, outputDir: URL) async throws -> URL? {
        // 读取文件
        let data = try Data(contentsOf: url)
        print("📁 File loaded: \(data.count) bytes")
            
            status = "Finding log start position..."
            
            // 查找起始位置
            guard let startPos = headerParser.findLogStartPosition(in: data) else {
                print("❌ Failed to find log start position")
                throw DecoderError.invalidFormat
            }
            print("✅ Found log start at offset: \(startPos)")
            
            status = "Decoding..."
            
            var output = Data()
            var offset = startPos
            var processedBytes = 0
            
            // 解码所有日志
            while offset < data.count {
                guard let nextOffset = try await decodeBuffer(
                    buffer: data,
                    offset: offset,
                    output: &output
                ) else {
                    break
                }
                
                processedBytes = nextOffset
                updateProgress(Double(processedBytes) / Double(data.count))
                offset = nextOffset
            }
            
        // 保存输出文件
        status = "Saving output..."
        
        // 将输出转换为字符串用于UID提取和预览
        let outputString = String(data: output, encoding: .utf8) ?? ""
        
        // 提取UID并构建输出文件名
        var outputName = url.deletingPathExtension().lastPathComponent
        if let uid = extractUID(from: outputString) {
            outputName += "_\(uid)"
            print("📋 Extracted UID: \(uid)")
        }
        
        let outputURL = outputDir
            .appendingPathComponent(outputName)
            .appendingPathExtension("log")
        try output.write(to: outputURL)
        print("💾 Saved to: \(outputURL.path)")
        
        // 更新预览 (只显示前10KB)
        let previewData = output.prefix(10240)
        logPreview = String(data: previewData, encoding: .utf8) ?? "Unable to preview (binary data)"
        
        return outputURL
    }
    
    /// 从日志内容中提取UID
    private func extractUID(from content: String) -> String? {
        // 匹配 _uid=数字 格式
        let pattern = "_uid=(\\d+)"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
              let match = regex.firstMatch(in: content, options: [], range: NSRange(content.startIndex..., in: content)),
              let range = Range(match.range(at: 1), in: content) else {
            return nil
        }
        return String(content[range])
    }
    
    private func decodeBuffer(buffer: Data, offset: Int, output: inout Data) async throws -> Int? {
        // 验证缓冲区
        guard headerParser.isValidLogBuffer(buffer: buffer, offset: offset, count: 1) else {
            // 尝试查找下一个有效位置
            let remainingData = buffer[offset...]
            if let fixPos = headerParser.findLogStartPosition(in: Data(remainingData), count: 1) {
                let errorMsg = "[F] Decode error at offset \(offset), skipped \(fixPos) bytes\n"
                output.append(errorMsg.data(using: .utf8) ?? Data())
                return offset + fixPos
            }
            return nil
        }
        
        // 解析header
        let header = try headerParser.parse(from: buffer, at: offset)
        print("📋 Header parsed - Magic: 0x\(String(format: "%02X", header.magic.rawValue)), Seq: \(header.sequence), Length: \(header.length)")
        print("   Needs decryption: \(header.magic.needsDecryption), Needs decompression: \(header.magic.needsDecompression)")
        
        // 检查序列号
        if header.sequence != 0 && header.sequence != 1 && lastSequence != 0 && header.sequence != (lastSequence + 1) {
            let errorMsg = "[F] Log seq:\(lastSequence + 1)-\(header.sequence - 1) is missing\n"
            output.append(errorMsg.data(using: .utf8) ?? Data())
        }
        
        if header.sequence != 0 {
            lastSequence = header.sequence
        }
        
        // 提取日志数据
        let dataStart = offset + header.headerLength
        let dataEnd = dataStart + Int(header.length)
        var logData = buffer[dataStart..<dataEnd]
        print("📦 Extracted \(logData.count) bytes of data (offset: \(dataStart)-\(dataEnd))")
        
        // 解密
        if header.magic.needsDecryption {
            print("🔓 Decrypting with \(header.magic.decryptionType)...")
            let beforeSize = logData.count
            logData = try decryptData(logData, header: header)
            print("   Decrypted: \(beforeSize) -> \(logData.count) bytes")
        }
        
        // 解压
        if header.magic.needsDecompression {
            print("📤 Decompressing \(logData.count) bytes...")
            let beforeSize = logData.count
            do {
                // 0x05需要先分段处理
                if header.magic.needsSegmentedDecompression {
                    print("   🔀 Segmented decompression (magic 0x05)")
                    var decompressData = Data()
                    var offset = 0
                    
                    while offset < logData.count {
                        // 读取2字节长度
                        guard offset + 2 <= logData.count else { break }
                        let segmentLength = Int(readUInt16(from: logData, at: offset))
                        offset += 2
                        
                        // 提取分段数据
                        guard offset + segmentLength <= logData.count else { break }
                        let segment = logData[offset..<(offset + segmentLength)]
                        decompressData.append(segment)
                        offset += segmentLength
                        
                        print("      Segment: \(segmentLength) bytes")
                    }
                    
                    print("   Total extracted: \(decompressData.count) bytes from \(logData.count) bytes")
                    logData = try decompressor.decompress(decompressData)
                } else {
                    // 0x04, 0x09等直接解压
                    logData = try decompressor.decompress(logData)
                }
                print("   ✅ Decompressed: \(beforeSize) -> \(logData.count) bytes")
            } catch {
                print("   ❌ Decompression failed: \(error)")
                print("   First 16 bytes: \(logData.prefix(16).map { String(format: "%02X", $0) }.joined(separator: " "))")
                throw error
            }
        }
        
        output.append(logData)
        
        return dataEnd + 1 // +1 for magic end marker
    }
    
    private func decryptData(_ data: Data, header: LogHeader) throws -> Data {
        switch header.magic.decryptionType {
        case .none:
            return data
            
        case .xor:
            return xorDecryptor.decrypt(data, header: header)
            
        case .tea:
            // TEA解密需要ECDH密钥,暂时跳过
            throw DecoderError.decryptionFailed
        }
    }
    
    // 安全读取UInt16 (小端序)
    private func readUInt16(from data: Data, at offset: Int) -> UInt16 {
        guard offset + 2 <= data.count else { return 0 }
        let byte0 = UInt16(data[offset])
        let byte1 = UInt16(data[offset + 1])
        return byte0 | (byte1 << 8)
    }
    
    private func updateProgress(_ newProgress: Double) {
        progress = newProgress
        
        // 计算速度和剩余时间
        guard let startTime = startTime else { return }
        
        let elapsed = Date().timeIntervalSince(startTime)
        if elapsed > 0 {
            let bytesProcessed = progress * 100 // 假设总大小
            let bytesPerSecond = bytesProcessed / elapsed
            speed = String(format: "%.1f MB/s", bytesPerSecond / 1_000_000)
            
            if progress > 0 {
                let remaining = (1.0 - progress) * elapsed / progress
                timeRemaining = String(format: "%.0f seconds", remaining)
            }
        }
    }
    
    func reset() {
        state = .idle
        progress = 0
        status = "Ready to decode"
        logPreview = ""
        decodedFileURL = nil
        speed = ""
        timeRemaining = ""
        lastSequence = 0
    }
    
    func openInConsole() {
        guard let url = decodedFileURL else { return }
        
        NSWorkspace.shared.open(
            [url],
            withApplicationAt: URL(fileURLWithPath: "/System/Applications/Utilities/Console.app"),
            configuration: NSWorkspace.OpenConfiguration()
        ) { _, error in
            if let error = error {
                print("Failed to open in Console: \(error)")
            }
        }
    }
    
    func openInVSCode() {
        guard let url = decodedFileURL else { return }
        
        let task = Process()
        task.launchPath = "/usr/local/bin/code"
        task.arguments = [url.path]
        
        do {
            try task.run()
        } catch {
            print("Failed to open in VS Code: \(error)")
        }
    }
}
