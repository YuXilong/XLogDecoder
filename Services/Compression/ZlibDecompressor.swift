//
//  ZlibDecompressor.swift
//  XLogDecoder
//

import Foundation
import Compression

class ZlibDecompressor {
    func decompress(_ data: Data) throws -> Data {
        // 预分配输出缓冲区 (通常解压后是原始大小的6倍)
        let bufferSize = max(data.count * 6, 4096)
        var output = Data(count: bufferSize)
        
        let decompressedSize = data.withUnsafeBytes { inputPtr -> Int in
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
        
        guard decompressedSize > 0 else {
            throw DecoderError.decompressionFailed
        }
        
        return output.prefix(decompressedSize)
    }
}
