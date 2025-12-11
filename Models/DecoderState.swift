//
//  DecoderState.swift
//  XLogDecoder
//

import Foundation

enum DecoderState: Equatable {
    case idle
    case decoding(fileName: String, fileSize: Int64)
    case complete(fileName: String, inputSize: Int64, outputSize: Int64, duration: TimeInterval)
    case error(String)
    
    var isDecoding: Bool {
        if case .decoding = self {
            return true
        }
        return false
    }
    
    var isComplete: Bool {
        if case .complete = self {
            return true
        }
        return false
    }
    
    var isError: Bool {
        if case .error = self {
            return true
        }
        return false
    }
}
