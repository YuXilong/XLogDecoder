//
//  ZlibDecompressor.swift
//  XLogDecoder
//

import Foundation
import Compression

class ZlibDecompressor {
    func decompress(_ data: Data) throws -> Data {
        // xlog使用原始deflate格式(对应Python的-zlib.MAX_WBITS)
        // 先尝试LZFSE,如果失败再尝试ZLIB
        
        print("🔧 Attempting decompression...")
        print("   Input size: \(data.count) bytes")
        print("   First 4 bytes: \(data.prefix(4).map { String(format: "%02X", $0) }.joined(separator: " "))")
        
        // 预分配输出缓冲区
        let bufferSize = max(data.count * 10, 65536)
        var output = Data(count: bufferSize)
        
        // 尝试1: LZFSE (可能支持原始deflate)
        var decompressedSize = data.withUnsafeBytes { inputPtr -> Int in
            output.withUnsafeMutableBytes { outputPtr -> Int in
                guard let inputBaseAddress = inputPtr.baseAddress,
                      let outputBaseAddress = outputPtr.baseAddress else {
                    return 0
                }
                
                return compression_decode_buffer(
                    outputBaseAddress,
                    bufferSize,
                    inputBaseAddress,
                    data.count,
                    nil,
                    COMPRESSION_LZFSE
                )
            }
        }
        
        if decompressedSize > 0 {
            print("   ✅ LZFSE decompression succeeded: \(decompressedSize) bytes")
            return output.prefix(decompressedSize)
        }
        
        // 尝试2: ZLIB
        decompressedSize = data.withUnsafeBytes { inputPtr -> Int in
            output.withUnsafeMutableBytes { outputPtr -> Int in
                guard let inputBaseAddress = inputPtr.baseAddress,
                      let outputBaseAddress = outputPtr.baseAddress else {
                    return 0
                }
                
                return compression_decode_buffer(
                    outputBaseAddress,
                    bufferSize,
                    inputBaseAddress,
                    data.count,
                    nil,
                    COMPRESSION_ZLIB
                )
            }
        }
        
        if decompressedSize > 0 {
            print("   ✅ ZLIB decompression succeeded: \(decompressedSize) bytes")
            return output.prefix(decompressedSize)
        }
        
        // 尝试3: LZ4
        decompressedSize = data.withUnsafeBytes { inputPtr -> Int in
            output.withUnsafeMutableBytes { outputPtr -> Int in
                guard let inputBaseAddress = inputPtr.baseAddress,
                      let outputBaseAddress = outputPtr.baseAddress else {
                    return 0
                }
                
                return compression_decode_buffer(
                    outputBaseAddress,
                    bufferSize,
                    inputBaseAddress,
                    data.count,
                    nil,
                    COMPRESSION_LZ4
                )
            }
        }
        
        if decompressedSize > 0 {
            print("   ✅ LZ4 decompression succeeded: \(decompressedSize) bytes")
            return output.prefix(decompressedSize)
        }
        
        print("   ❌ All decompression methods failed")
        throw DecoderError.decompressionFailed
    }
}
