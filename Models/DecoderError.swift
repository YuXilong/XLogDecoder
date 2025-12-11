//
//  DecoderError.swift
//  XLogDecoder
//

import Foundation

enum DecoderError: LocalizedError {
    case invalidFormat
    case invalidHeader
    case unknownMagicNumber(UInt8)
    case headerTooShort
    case invalidEndMarker
    case decompressionFailed
    case decryptionFailed
    case fileReadError
    case fileWriteError
    case noXLogFilesFound
    
    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "Invalid xlog file format"
        case .invalidHeader:
            return "Invalid log header"
        case .unknownMagicNumber(let byte):
            return "Unknown magic number: 0x\(String(byte, radix: 16))"
        case .headerTooShort:
            return "Header too short"
        case .invalidEndMarker:
            return "Invalid end marker"
        case .decompressionFailed:
            return "Decompression failed"
        case .decryptionFailed:
            return "Decryption failed"
        case .fileReadError:
            return "Failed to read file"
        case .fileWriteError:
            return "Failed to write output file"
        case .noXLogFilesFound:
            return "No .xlog files found in ZIP archive"
        }
    }
}
