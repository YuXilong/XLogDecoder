//
//  ZlibDecompressor.swift
//  XLogDecoder
//

import Foundation
import zlib

class ZlibDecompressor {
    func decompress(_ data: Data) throws -> Data {
        // xlog使用原始deflate格式(对应Python的-zlib.MAX_WBITS)
        // 需要使用zlib的inflateInit2函数,windowBits设为-15
        
        print("🔧 Attempting raw deflate decompression...")
        print("   Input size: \(data.count) bytes")
        print("   First 4 bytes: \(data.prefix(4).map { String(format: "%02X", $0) }.joined(separator: " "))")
        
        var stream = z_stream()
        var output = Data()
        var status: Int32 = Z_OK
        
        // 使用withUnsafeBytes处理输入数据
        let result = data.withUnsafeBytes { (inputBytes: UnsafeRawBufferPointer) -> Bool in
            guard let inputBaseAddress = inputBytes.baseAddress else {
                print("   ❌ Failed to get input base address")
                return false
            }
            
            stream.avail_in = UInt32(data.count)
            stream.next_in = UnsafeMutablePointer<UInt8>(mutating: inputBaseAddress.assumingMemoryBound(to: UInt8.self))
            
            // 使用-15作为windowBits表示原始deflate格式(无zlib header)
            // 对应Python的-zlib.MAX_WBITS
            status = inflateInit2_(&stream, -15, ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size))
            
            guard status == Z_OK else {
                print("   ❌ inflateInit2 failed with status: \(status)")
                return false
            }
            
            // 解压缩循环
            repeat {
                let outputBufferSize = 65536
                var outputBuffer = [UInt8](repeating: 0, count: outputBufferSize)
                
                outputBuffer.withUnsafeMutableBytes { bufferPtr in
                    stream.avail_out = UInt32(outputBufferSize)
                    stream.next_out = bufferPtr.baseAddress?.assumingMemoryBound(to: UInt8.self)
                }
                
                status = inflate(&stream, Z_NO_FLUSH)
                
                if status != Z_OK && status != Z_STREAM_END {
                    print("   ❌ inflate failed with status: \(status)")
                    inflateEnd(&stream)
                    return false
                }
                
                let have = outputBufferSize - Int(stream.avail_out)
                output.append(contentsOf: outputBuffer.prefix(have))
                
            } while status != Z_STREAM_END
            
            inflateEnd(&stream)
            return true
        }
        
        guard result && status == Z_STREAM_END else {
            print("   ❌ Decompression incomplete, status: \(status)")
            throw DecoderError.decompressionFailed
        }
        
        print("   ✅ Raw deflate decompression succeeded: \(output.count) bytes")
        return output
    }
}
