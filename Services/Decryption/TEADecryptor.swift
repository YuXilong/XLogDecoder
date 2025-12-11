//
//  TEADecryptor.swift
//  XLogDecoder
//

import Foundation

class TEADecryptor {
    private let delta: UInt32 = 0x9e37_79b9
    private let blockSize = 8
    
    func decrypt(_ data: Data, key: [UInt32]) -> Data {
        guard key.count == 4 else {
            return data
        }
        
        var result = Data()
        
        // 按8字节块处理
        for i in stride(from: 0, to: data.count, by: blockSize) {
            let end = min(i + blockSize, data.count)
            
            if end - i == blockSize {
                // 完整的8字节块
                let block = data[i..<end]
                let decrypted = decryptBlock(block, key: key)
                result.append(decrypted)
            } else {
                // 不足8字节,直接添加
                result.append(data[i..<end])
            }
        }
        
        return result
    }
    
    private func decryptBlock(_ block: Data, key: [UInt32]) -> Data {
        // 读取两个32位整数
        var v0 = block.withUnsafeBytes { $0.load(as: UInt32.self) }
        var v1 = block.withUnsafeBytes { $0.load(fromByteOffset: 4, as: UInt32.self) }
        
        // TEA解密
        var sum = delta &<< 4  // sum = delta * 16
        
        for _ in 0..<16 {
            v1 = v1 &- (((v0 &<< 4) &+ key[2]) ^ (v0 &+ sum) ^ ((v0 &>> 5) &+ key[3]))
            v0 = v0 &- (((v1 &<< 4) &+ key[0]) ^ (v1 &+ sum) ^ ((v1 &>> 5) &+ key[1]))
            sum = sum &- delta
        }
        
        // 写回Data
        var result = Data(count: 8)
        result.withUnsafeMutableBytes { ptr in
            ptr.storeBytes(of: v0, as: UInt32.self)
            ptr.storeBytes(of: v1, toByteOffset: 4, as: UInt32.self)
        }
        
        return result
    }
}
