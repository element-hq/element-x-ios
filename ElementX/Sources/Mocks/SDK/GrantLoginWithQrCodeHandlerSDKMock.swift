//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK
import MatrixRustSDKMocks

extension GrantLoginWithQrCodeHandlerSDKMock {
    struct Configuration {
        var generateDelay: Duration = .seconds(0)
        var generatedBase64QRCode = """
        TUFUUklYAgS0yzZ1QVpQ1jlnoxWX3d5jrWRFfELxjS2gN7pz9y+3PABaaHR0
        cHM6Ly9zeW5hcHNlLW9pZGMubGFiLmVsZW1lbnQuZGV2L19zeW5hcHNlL2Ns
        aWVudC9yZW5kZXp2b3VzLzAxSFg5SzAwUTFINktQRDQ3RUc0RzFUM1hHACVo
        dHRwczovL3N5bmFwc2Utb2lkYy5sYWIuZWxlbWVudC5kZXYv
        """
    }
    
    convenience init(_ configuration: Configuration) {
        self.init()
        
        generateProgressListenerClosure = { listener in
            Task {
                try await Task.sleep(for: configuration.generateDelay)
                let bytes = Data(base64Encoded: configuration.generatedBase64QRCode) ?? Data()
                try listener.onUpdate(state: .qrReady(qrCode: .fromBytes(bytes: bytes)))
            }
        }
    }
}
