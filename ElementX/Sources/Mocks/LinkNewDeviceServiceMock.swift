//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

extension LinkNewDeviceServiceMock {
    static var mockQRCodeImage: UIImage {
        mockBase64QRCode.data(using: .utf8).flatMap { UIImage(qrCodeData: $0) } ?? UIImage()
    }
    
    static let mockBase64QRCode = """
    TUFUUklYAgS0yzZ1QVpQ1jlnoxWX3d5jrWRFfELxjS2gN7pz9y+3PABaaHR0
    cHM6Ly9zeW5hcHNlLW9pZGMubGFiLmVsZW1lbnQuZGV2L19zeW5hcHNlL2Ns
    aWVudC9yZW5kZXp2b3VzLzAxSFg5SzAwUTFINktQRDQ3RUc0RzFUM1hHACVo
    dHRwczovL3N5bmFwc2Utb2lkYy5sYWIuZWxlbWVudC5kZXYv
    """
    
    struct Configuration {
        var linkMobileProgressPublisher: LinkNewDeviceService.LinkMobileProgressPublisher = .init(.starting)
        var linkDesktopProgressPublisher: LinkNewDeviceService.LinkDesktopProgressPublisher = .init(.starting)
    }
    
    convenience init(_ configuration: Configuration) {
        self.init()
        
        linkMobileDeviceReturnValue = configuration.linkMobileProgressPublisher
        linkDesktopDeviceWithReturnValue = configuration.linkDesktopProgressPublisher
    }
}
