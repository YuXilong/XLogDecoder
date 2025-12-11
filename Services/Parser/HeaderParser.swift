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
        
        // 解析序列号 (2字节) - 安全读取
        let sequence = readUInt16(from: buffer, at: offset + 1)
        
        // 解析开始小时 (1字节)
        let beginHour = buffer[offset + 3]
        
        // 解析结束小时 (1字节)
        let endHour = buffer[offset + 4]
        
        // 解析长度 (4字节) - 安全读取
        let length = readUInt32(from: buffer, at: offset + 5)
        
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
    
    // 安全读取UInt16 (小端序)
    private func readUInt16(from data: Data, at offset: Int) -> UInt16 {
        guard offset + 2 <= data.count else { return 0 }
        let byte0 = UInt16(data[offset])
        let byte1 = UInt16(data[offset + 1])
        return byte0 | (byte1 << 8)
    }
    
    // 安全读取UInt32 (小端序)
    private func readUInt32(from data: Data, at offset: Int) -> UInt32 {
        guard offset + 4 <= data.count else { return 0 }
        let byte0 = UInt32(data[offset])
        let byte1 = UInt32(data[offset + 1])
        let byte2 = UInt32(data[offset + 2])
        let byte3 = UInt32(data[offset + 3])
        return byte0 | (byte1 << 8) | (byte2 << 16) | (byte3 << 24)
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
        
        // 解析长度 - 安全读取
        let length = readUInt32(from: buffer, at: offset + 5)
        
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
