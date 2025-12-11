//
//  XORDecryptor.swift
//  XLogDecoder
//

import Foundation

class XORDecryptor {
    private let baseKey: UInt8 = 0xCC
    
    func decrypt(_ data: Data, header: LogHeader) -> Data {
        let key = calculateKey(header: header)
        var decrypted = Data(count: data.count)
        
        for i in 0..<data.count {
            decrypted[i] = data[i] ^ key
        }
        
        return decrypted
    }
    
    private func calculateKey(header: LogHeader) -> UInt8 {
        switch header.magic {
        case .noCompressStart, .compressStart:
            // key = BASE_KEY ^ (length & 0xFF) ^ magic
            return baseKey ^ UInt8(header.length & 0xFF) ^ header.magic.rawValue
            
        default:
            // key = BASE_KEY ^ (sequence & 0xFF) ^ magic
            return baseKey ^ UInt8(header.sequence & 0xFF) ^ header.magic.rawValue
        }
    }
}
