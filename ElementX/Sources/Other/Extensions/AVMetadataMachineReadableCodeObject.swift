//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
        var halves = input.halfBytes()
        var batch = takeBatch(&halves, version: symbolVersion)
        var output = batch
        while !batch.isEmpty {
            batch = takeBatch(&halves, version: symbolVersion)
            output.append(contentsOf: batch)
        }
        let data = Data(output)
        return data
    }

    private static func takeBatch(_ input: inout [HalfByte], version: Int) -> [UInt8] {
        let characterCountLength = version > 9 ? 16 : 8
        let mode = input.remove(at: 0)
        var output = [UInt8]()
        switch mode.value {
        // If there is not only binary in the QRCode, then cases should be added here.
        case 0x04: // Binary
            let charactersCount: UInt16
            if characterCountLength == 8 {
                charactersCount = UInt16(input.takeUInt8())
            } else {
                charactersCount = UInt16(input.takeUInt16())
            }
            for _ in 0..<charactersCount {
                output.append(input.takeUInt8())
            }
            return output
        case 0x00: // End of data
            return []
        default:
            return []
        }
    }
}

private struct HalfByte {
    let value: UInt8
}

private extension [HalfByte] {
    mutating func takeUInt8() -> UInt8 {
        let left = remove(at: 0)
        let right = remove(at: 0)
        return UInt8(left, right)
    }

    mutating func takeUInt16() -> UInt16 {
        let first = remove(at: 0)
        let second = remove(at: 0)
        let third = remove(at: 0)
        let fourth = remove(at: 0)
        return UInt16(first, second, third, fourth)
    }
}

private extension Data {
    func halfBytes() -> [HalfByte] {
        var result = [HalfByte]()
        forEach { (byte: UInt8) in
            result.append(contentsOf: byte.halfBytes())
        }
        return result
    }
}

private extension UInt8 {
    func halfBytes() -> [HalfByte] {
        [HalfByte(value: self >> 4), HalfByte(value: self & 0x0F)]
    }

    init(_ left: HalfByte, _ right: HalfByte) {
        self.init((left.value << 4) + (right.value & 0x0F))
    }
}

private extension UInt16 {
    init(_ first: HalfByte, _ second: HalfByte, _ third: HalfByte, _ fourth: HalfByte) {
        let first = UInt16(first.value) << 12
        let second = UInt16(second.value) << 8
        let third = UInt16(third.value) << 4
        let fourth = UInt16(fourth.value) & 0x0F
        let result = first + second + third + fourth
        self.init(result)
    }
}
