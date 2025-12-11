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
    
    private var startTime: Date?
    private var lastSequence: UInt16 = 0
    
    func decodeFile(at url: URL) async {
        startTime = Date()
        lastSequence = 0
        
        do {
            // 获取文件信息
            let fileAttributes = try FileManager.default.attributesOfItem(atPath: url.path)
            let fileSize = fileAttributes[.size] as? Int64 ?? 0
            
            state = .decoding(fileName: url.lastPathComponent, fileSize: fileSize)
            status = "Reading file..."
            
            // 读取文件
            let data = try Data(contentsOf: url)
            
            status = "Finding log start position..."
            
            // 查找起始位置
            guard let startPos = headerParser.findLogStartPosition(in: data) else {
                throw DecoderError.invalidFormat
            }
            
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
            let outputURL = url.deletingPathExtension().appendingPathExtension("xlog.log")
            try output.write(to: outputURL)
            
            // 更新预览 (只显示前10KB)
            let previewData = output.prefix(10240)
            logPreview = String(data: previewData, encoding: .utf8) ?? "Unable to preview (binary data)"
            
            decodedFileURL = outputURL
            
            let duration = Date().timeIntervalSince(startTime ?? Date())
            state = .complete(
                fileName: url.lastPathComponent,
                inputSize: fileSize,
                outputSize: Int64(output.count),
                duration: duration
            )
            status = "Complete!"
            progress = 1.0
            
        } catch {
            state = .error(error.localizedDescription)
            status = "Error: \(error.localizedDescription)"
        }
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
        
        // 解密
        if header.magic.needsDecryption {
            logData = try decryptData(logData, header: header)
        }
        
        // 解压
        if header.magic.needsDecompression {
            logData = try decompressor.decompress(logData)
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
