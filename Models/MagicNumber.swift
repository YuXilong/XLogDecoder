//
//  MagicNumber.swift
//  XLogDecoder
//

import Foundation

enum MagicNumber: UInt8 {
    case noCompressStart = 0x03
    case compressStart = 0x04
    case compressStart1 = 0x05
    case noCompressStart1 = 0x06
    case compressStart2 = 0x07
    case noCompressNoCryptStart = 0x08
    case compressNoCryptStart = 0x09
    
    var cryptKeyLength: Int {
        switch self {
        case .noCompressStart, .compressStart, .compressStart1:
            return 4
        default:
            return 64
        }
    }
    
    var headerLength: Int {
        return 1 + 2 + 1 + 1 + 4 + cryptKeyLength
    }
    
    var needsDecryption: Bool {
        switch self {
        case .noCompressNoCryptStart, .compressNoCryptStart:
            return false
        default:
            return true
        }
    }
    
    var needsDecompression: Bool {
        switch self {
        case .compressStart, .compressStart1, .compressStart2, .compressNoCryptStart:
            return true
        default:
            return false
        }
    }
    
    var needsSegmentedDecompression: Bool {
        // 0x05需要分段处理
        return self == .compressStart1
    }
    
    var decryptionType: DecryptionType {
        switch self {
        case .noCompressStart, .compressStart, .compressStart1, .noCompressStart1:
            return .xor
        case .compressStart2:
            return .tea
        case .noCompressNoCryptStart, .compressNoCryptStart:
            return .none
        }
    }
}

enum DecryptionType {
    case none
    case xor
    case tea
}
