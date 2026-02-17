//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import CommonCrypto
import Foundation

enum MXAESError: Error {
    case cannotInitializeCryptor
    case decryptionFailed(CCCryptorStatus)
}

enum MXAES {
    /// Decrypt data using AES-256 in CTR mode.
    /// - Parameters:
    ///   - data: The data to decrypt
    ///   - aesKey: The AES decryption key (256-bit)
    ///   - iv: The initialization vector
    /// - Returns: The decrypted data, or nil if decryption fails
    /// - Throws: An error if decryption fails
    static func decrypt(_ data: Data, aesKey: Data, iv: Data) throws -> Data {
        var cryptor: CCCryptorRef?
        var status: CCCryptorStatus
        
        // Create the cryptor
        status = iv.withUnsafeBytes { ivBytes in
            aesKey.withUnsafeBytes { keyBytes in
                CCCryptorCreateWithMode(CCOperation(kCCDecrypt),
                                        CCMode(kCCModeCTR),
                                        CCAlgorithm(kCCAlgorithmAES),
                                        CCPadding(ccNoPadding),
                                        ivBytes.baseAddress,
                                        keyBytes.baseAddress,
                                        kCCKeySizeAES256,
                                        nil,
                                        0,
                                        0,
                                        CCModeOptions(kCCModeOptionCTR_BE),
                                        &cryptor)
            }
        }
        
        guard status == kCCSuccess, let cryptor else {
            MXLog.error("Failed to create cryptor: \(status)")
            throw MXAESError.cannotInitializeCryptor
        }
        
        // Get the output buffer size
        let bufferLength = CCCryptorGetOutputLength(cryptor, data.count, false)
        var buffer = Data(count: bufferLength)
        
        var outLength = 0
        status = data.withUnsafeBytes { dataBytes in
            let count = buffer.count
            return buffer.withUnsafeMutableBytes { bufferBytes in
                CCCryptorUpdate(cryptor,
                                dataBytes.baseAddress,
                                data.count,
                                bufferBytes.baseAddress,
                                count,
                                &outLength)
            }
        }
        
        let releaseStatus = CCCryptorRelease(cryptor)
        status = (status == kCCSuccess && releaseStatus == kCCSuccess) ? CCCryptorStatus(kCCSuccess) : status
        
        guard status == kCCSuccess else {
            MXLog.error("Decryption failed: \(status)")
            throw MXAESError.decryptionFailed(status)
        }
        
        return buffer
    }
}
