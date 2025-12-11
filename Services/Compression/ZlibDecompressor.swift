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
        print("   First 16 bytes: \(data.prefix(16).map { String(format: "%02X", $0) }.joined(separator: " "))")
        
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
                if let msg = stream.msg {
                    print("   Error message: \(String(cString: msg))")
                }
                return false
            }
            
            print("   ✅ inflateInit2 succeeded, starting decompression...")
            
            // 解压缩循环
            var iteration = 0
            repeat {
                iteration += 1
                let outputBufferSize = 65536
                var outputBuffer = [UInt8](repeating: 0, count: outputBufferSize)
                
                outputBuffer.withUnsafeMutableBytes { bufferPtr in
                    stream.avail_out = UInt32(outputBufferSize)
                    stream.next_out = bufferPtr.baseAddress?.assumingMemoryBound(to: UInt8.self)
                }
                
                let prevAvailIn = stream.avail_in
                // 当没有更多输入数据时使用Z_FINISH,否则使用Z_NO_FLUSH
                let flushFlag = (stream.avail_in == 0) ? Z_FINISH : Z_NO_FLUSH
                status = inflate(&stream, flushFlag)
                let consumedBytes = prevAvailIn - stream.avail_in
                
                print("   Iteration \(iteration): consumed \(consumedBytes) bytes, status: \(status), flush: \(flushFlag == Z_FINISH ? "FINISH" : "NO_FLUSH")")
                
                if status != Z_OK && status != Z_STREAM_END {
                    print("   ❌ inflate failed with status: \(status)")
                    if let msg = stream.msg {
                        print("   Error message: \(String(cString: msg))")
                    }
                    print("   avail_in: \(stream.avail_in), avail_out: \(stream.avail_out)")
                    inflateEnd(&stream)
                    return false
                }
                
                let have = outputBufferSize - Int(stream.avail_out)
                if have > 0 {
                    output.append(contentsOf: outputBuffer.prefix(have))
                    print("   Produced \(have) bytes, total output: \(output.count)")
                }
                
            } while status != Z_STREAM_END  // 继续直到流结束,不检查avail_in
            
            inflateEnd(&stream)
            
            // 如果输入数据全部消耗且状态为Z_OK,也视为成功
            // (某些压缩数据可能不会明确返回Z_STREAM_END)
            let success = (status == Z_STREAM_END) || (status == Z_OK && stream.avail_in == 0 && output.count > 0)
            return success
        }
        
        guard result else {
            print("   ❌ Decompression failed")
            throw DecoderError.decompressionFailed
        }
        
        print("   ✅ Raw deflate decompression succeeded: \(output.count) bytes")
        return output
    }
}
