//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

// Helpers to remove ECI headers from QR Code raw data
// https://gist.github.com/PetrusM/267e2ee8c1d8b5dca17eac085afa7d7c
import AVKit
import Foundation

extension AVMetadataMachineReadableCodeObject {
    var binaryValue: Data? {
        switch type {
        case .qr:
            guard let binaryValueWithProtocol,
                  let symbolVersion = (descriptor as? CIQRCodeDescriptor)?.symbolVersion else {
                return nil
            }
            return Self.removeQrProtocolData(binaryValueWithProtocol, symbolVersion: symbolVersion)
        case .aztec:
            guard let string = stringValue
            else { return nil }
            return string.data(using: String.Encoding.isoLatin1)
        default:
            return nil
        }
    }
    
    var binaryValueWithProtocol: Data? {
        guard let descriptor else {
            return nil
        }
        switch type {
        case .qr:
            return (descriptor as? CIQRCodeDescriptor)?.errorCorrectedPayload
        case .aztec:
            return (descriptor as? CIAztecCodeDescriptor)?.errorCorrectedPayload
        case .pdf417:
            return (descriptor as? CIPDF417CodeDescriptor)?.errorCorrectedPayload
        case .dataMatrix:
            return (descriptor as? CIDataMatrixCodeDescriptor)?.errorCorrectedPayload
        default:
            return nil
        }
    }
    
    static func removeQrProtocolData(_ input: Data, symbolVersion: Int) -> Data? {
        var bits = input.bits()
        var segment: [UInt8]
        var output: [UInt8] = []
        repeat {
            segment = takeSegment(&bits, version: symbolVersion)
            output.append(contentsOf: segment)
        } while !segment.isEmpty
        return Data(output)
    }
    
    private static func takeSegment(_ input: inout [Bit], version: Int) -> [UInt8] {
        let mode = input.takeBits(4)

        switch mode {
        case 0x02: // Alphanumeric
            return input.takeAlphanumericSegment(version)
        case 0x04: // Binary
            return input.takeBinarySegment(version)
        case 0x00: // End of data
            return []
        default:
            preconditionFailure("Unhandled QR segment mode: \(mode)")
        }
    }
}

private struct Bit {
    let value: UInt8
}

private extension [Bit] {
    mutating func takeBits(_ count: Int) -> UInt8 {
        if count > 8 {
            preconditionFailure("Maximum of 8 bits can be taken at a time.")
        }
        var value: UInt8 = 0
        for _ in 0..<count {
            value = (value << 1) | remove(at: 0).value
        }
        return value
    }

    mutating func takeBits16(_ count: Int) -> UInt16 {
        if count > 16 {
            preconditionFailure("Maximum of 16 bits can be taken at a time.")
        }
        var value: UInt16 = 0
        for _ in 0..<count {
            value = (value << 1) | UInt16(remove(at: 0).value)
        }
        return value
    }

    mutating func takeUInt8() -> UInt8 {
        takeBits(8)
    }
    
    mutating func takeUInt16() -> UInt16 {
        takeBits16(16)
    }
    
    mutating func takeBinarySegment(_ version: Int) -> [UInt8] {
        var output = [UInt8]()
        
        let characterCountLength = version > 9 ? 16 : 8
        
        let charactersCount = takeBits16(characterCountLength)

        for _ in 0..<charactersCount {
            output.append(takeUInt8())
        }
        return output
    }
    
    mutating func takeAlphanumericSegment(_ version: Int) -> [UInt8] {
        var output = [UInt8]()

        let characterCountLength = version > 9 ? (version > 26 ? 13 : 11) : 9

        let charactersCount = takeBits16(characterCountLength)
        var charactersRemaining = charactersCount
        while charactersRemaining > 1 {
            if count < 11 {
                // done
                return output
            }
            // read the 11 bits
            let nextTwoCharacters = takeBits16(11)
            // split into the two characters
            output.append(Array<Bit>.alphaToByte(UInt8(nextTwoCharacters / 45)))
            output.append(Array<Bit>.alphaToByte(UInt8(nextTwoCharacters % 45)))
            charactersRemaining -= 2
        }
        
        if charactersRemaining == 1 {
            if count < 6 {
                // done
                return output
            }
            let nextCharacter = takeBits(6)
            output.append(Array<Bit>.alphaToByte(nextCharacter))
        }
        return output
    }
    
    private static func alphaToByte(_ input: UInt8) -> UInt8 {
        if input <= 9 {
            // 0-9
            return UInt8(input + 0x30)
        }
        if input <= 35 {
            // A-Z
            return UInt8(input - 10 + 0x41)
        }
        switch input {
        case 36: return " ".utf8.first!
        case 37: return "$".utf8.first!
        case 38: return "%".utf8.first!
        case 39: return "*".utf8.first!
        case 40: return "+".utf8.first!
        case 41: return "-".utf8.first!
        case 42: return ".".utf8.first!
        case 43: return "/".utf8.first!
        case 44: return ":".utf8.first!
            
        default:
            preconditionFailure("Unhandled alphanumeric character: \(input)")
        }
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
