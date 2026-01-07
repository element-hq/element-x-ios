//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

// Helpers to remove ECI headers from QR Code raw data
// Originally based on https://gist.github.com/PetrusM/267e2ee8c1d8b5dca17eac085afa7d7c
import AVKit
import Foundation

enum AVMetadataBinaryValueError: Error {
    case unhandledQRSegmentMode(UInt8)
    case bitError(BitError)
    case unknown(Error)
}

extension AVMetadataMachineReadableCodeObject {
    var qrBinaryValue: Data? {
        get throws(AVMetadataBinaryValueError) {
            guard type == .qr else { return nil }
            
            guard let qrCodeDescriptor = descriptor as? CIQRCodeDescriptor else { return nil }
            return try Self.removeQRProtocolData(qrCodeDescriptor.errorCorrectedPayload, symbolVersion: qrCodeDescriptor.symbolVersion)
        }
    }
    
    static func removeQRProtocolData(_ input: Data, symbolVersion: Int) throws(AVMetadataBinaryValueError) -> Data? {
        var bits = input.bits()
        var segment: [UInt8]
        var output: [UInt8] = []
        
        repeat {
            segment = try takeSegment(&bits, version: symbolVersion)
            output.append(contentsOf: segment)
        } while !segment.isEmpty
        
        return Data(output)
    }
    
    private static func takeSegment(_ input: inout [Bit], version: Int) throws(AVMetadataBinaryValueError) -> [UInt8] {
        do {
            let mode = try input.takeBits(4)
            
            return switch mode {
            case 0x02: try input.takeAlphanumericSegment(version) // Alphanumeric
            case 0x04: try input.takeBinarySegment(version) // Binary
            case 0x00: [] // End of data
            default: throw AVMetadataBinaryValueError.unhandledQRSegmentMode(mode)
            }
        } catch let error as BitError {
            throw .bitError(error)
        } catch let error as AVMetadataBinaryValueError {
            throw error
        } catch {
            throw .unknown(error)
        }
    }
}

enum BitError: Error {
    case moreThan8BitsTaken
    case moreThan16BitsTaken
    case unhandledAlphanumericCharacter(UInt8)
}

private struct Bit {
    let value: UInt8
}

private extension [Bit] {
    mutating func takeBits(_ count: Int) throws(BitError) -> UInt8 {
        guard count <= 8 else { throw .moreThan8BitsTaken }
        
        var value: UInt8 = 0
        for _ in 0..<count {
            value = (value << 1) | remove(at: 0).value
        }
        
        return value
    }

    mutating func takeBits16(_ count: Int) throws(BitError) -> UInt16 {
        guard count <= 16 else { throw .moreThan16BitsTaken }
        
        var value: UInt16 = 0
        for _ in 0..<count {
            value = (value << 1) | UInt16(remove(at: 0).value)
        }
        
        return value
    }

    mutating func takeUInt8() throws(BitError) -> UInt8 {
        try takeBits(8)
    }
    
    mutating func takeUInt16() throws(BitError) -> UInt16 {
        try takeBits16(16)
    }
    
    mutating func takeBinarySegment(_ version: Int) throws(BitError) -> [UInt8] {
        let characterCountLength = version > 9 ? 16 : 8
        let charactersCount = try takeBits16(characterCountLength)
        
        var output = [UInt8]()
        for _ in 0..<charactersCount {
            try output.append(takeUInt8())
        }
        return output
    }
    
    mutating func takeAlphanumericSegment(_ version: Int) throws(BitError) -> [UInt8] {
        let characterCountLength = version > 9 ? (version > 26 ? 13 : 11) : 9
        let charactersCount = try takeBits16(characterCountLength)
        
        var output = [UInt8]()
        var charactersRemaining = charactersCount
        while charactersRemaining > 1 {
            if count < 11 {
                // done
                return output
            }
            // read the 11 bits
            let nextTwoCharacters = try takeBits16(11)
            // split into the two characters
            try output.append(Self.alphaToByte(UInt8(nextTwoCharacters / 45)))
            try output.append(Self.alphaToByte(UInt8(nextTwoCharacters % 45)))
            charactersRemaining -= 2
        }
        
        if charactersRemaining == 1 {
            if count < 6 {
                // done
                return output
            }
            let nextCharacter = try takeBits(6)
            try output.append(Self.alphaToByte(nextCharacter))
        }
        return output
    }
    
    private static func alphaToByte(_ input: UInt8) throws(BitError) -> UInt8 {
        let value: UInt8? = switch input {
        case 0...9: input + 0x30 // 0-9
        case 10...35: input - 10 + 0x41 // A-Z
        case 36: " ".utf8.first
        case 37: "$".utf8.first
        case 38: "%".utf8.first
        case 39: "*".utf8.first
        case 40: "+".utf8.first
        case 41: "-".utf8.first
        case 42: ".".utf8.first
        case 43: "/".utf8.first
        case 44: ":".utf8.first
        default: nil
        }
        
        guard let value else { throw .unhandledAlphanumericCharacter(input) }
        return value
    }
}

private extension Data {
    func bits() -> [Bit] {
        var result = [Bit]()
        forEach { (byte: UInt8) in
            result.append(contentsOf: byte.bits())
        }
        return result
    }
}

private extension UInt8 {
    func bits() -> [Bit] {
        var bits: [Bit] = []
        for i in 0..<8 {
            let bitValue = (self >> (7 - i)) & 1
            bits.append(Bit(value: bitValue))
        }
        return bits
    }
}
