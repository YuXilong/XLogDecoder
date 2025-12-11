//
//  LogHeader.swift
//  XLogDecoder
//

import Foundation

struct LogHeader {
    let magic: MagicNumber
    let sequence: UInt16
    let beginHour: UInt8
    let endHour: UInt8
    let length: UInt32
    let cryptKey: Data?
    
    var headerLength: Int {
        return magic.headerLength
    }
    
    var totalLength: Int {
        return headerLength + Int(length) + 1 // +1 for magic end
    }
}
