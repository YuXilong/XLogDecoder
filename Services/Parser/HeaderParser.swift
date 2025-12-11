//
//  HeaderParser.swift
//  XLogDecoder
//

import Foundation

class HeaderParser {
    private let magicEnd: UInt8 = 0x00
    
    func parse(from buffer: Data, at offset: Int) throws -> LogHeader {
        // 检查最小长度
        guard offset + 9 <= buffer.count else {
            throw DecoderError.headerTooShort
        }
        
        // 解析魔数
        let magicByte = buffer[offset]
        guard let magic = MagicNumber(rawValue: magicByte) else {
            throw DecoderError.unknownMagicNumber(magicByte)
        }
        
        let headerLen = magic.headerLength
        guard offset + headerLen <= buffer.count else {
            throw DecoderError.headerTooShort
        }
        
        // 解析序列号 (2字节)
        let sequence = buffer.withUnsafeBytes { ptr in
            ptr.load(fromByteOffset: offset + 1, as: UInt16.self)
        }
        
        // 解析开始小时 (1字节)
        let beginHour = buffer[offset + 3]
        
        // 解析结束小时 (1字节)
        let endHour = buffer[offset + 4]
        
        // 解析长度 (4字节)
        let length = buffer.withUnsafeBytes { ptr in
            ptr.load(fromByteOffset: offset + 5, as: UInt32.self)
        }
        
        // 解析加密密钥 (如果有)
        var cryptKey: Data? = nil
        if magic.cryptKeyLength > 0 {
            let keyStart = offset + 9
            let keyEnd = keyStart + magic.cryptKeyLength
            cryptKey = buffer[keyStart..<keyEnd]
        }
        
        return LogHeader(
            magic: magic,
            sequence: sequence,
            beginHour: beginHour,
            endHour: endHour,
            length: length,
            cryptKey: cryptKey
        )
    }
    
    func isValidLogBuffer(buffer: Data, offset: Int, count: Int = 1) -> Bool {
        guard offset < buffer.count else {
            return offset == buffer.count
        }
        
        // 检查魔数
        let magicByte = buffer[offset]
        guard let magic = MagicNumber(rawValue: magicByte) else {
            return false
        }
        
        let headerLen = magic.headerLength
        
        // 检查header长度
        guard offset + headerLen + 1 <= buffer.count else {
            return false
        }
        
        // 解析长度
        let length = buffer.withUnsafeBytes { ptr in
            ptr.load(fromByteOffset: offset + 5, as: UInt32.self)
        }
        
        // 检查总长度
        guard offset + headerLen + Int(length) + 1 <= buffer.count else {
            return false
        }
        
        // 检查结束标记
        let endMarkerPos = offset + headerLen + Int(length)
        guard buffer[endMarkerPos] == magicEnd else {
            return false
        }
        
        // 递归检查下一条日志
        if count > 1 {
            let nextOffset = endMarkerPos + 1
            return isValidLogBuffer(buffer: buffer, offset: nextOffset, count: count - 1)
        }
        
        return true
    }
    
    func findLogStartPosition(in buffer: Data, count: Int = 2) -> Int? {
        for offset in 0..<buffer.count {
            let byte = buffer[offset]
            if let _ = MagicNumber(rawValue: byte) {
                if isValidLogBuffer(buffer: buffer, offset: offset, count: count) {
                    return offset
                }
            }
        }
        return nil
    }
}
