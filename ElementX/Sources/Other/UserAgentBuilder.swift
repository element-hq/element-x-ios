//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import UIKit

#if !os(OSX)
import DeviceKit
#endif

enum UserAgentBuilder {
    static func makeASCIIUserAgent() -> String {
        makeUserAgent()?.asciified() ?? "unknown"
    }
    
    static func makeUserAgent() -> String? {
        let clientName = InfoPlistReader.app.bundleDisplayName
        let clientVersion = InfoPlistReader.app.bundleShortVersionString

        #if os(iOS)
        let scale = UIScreen.main.scale
        return if ProcessInfo.processInfo.isiOSAppOnMac {
            String(format: "%@/%@ (Mac; macOS %@; Scale/%0.2f)",
                   clientName,
                   clientVersion,
                   ProcessInfo.processInfo.operatingSystemVersionString,
                   scale)
        } else {
            String(format: "%@/%@ (%@; iOS %@; Scale/%0.2f)",
                   clientName,
                   clientVersion,
                   Device.current.safeDescription,
                   UIDevice.current.systemVersion,
                   scale)
        }
        #elseif os(tvOS)
        return String(format: "%@/%@ (%@; tvOS %@; Scale/%0.2f)",
                      clientName,
                      clientVersion,
                      Device.current.safeDescription,
                      UIDevice.current.systemVersion,
                      UIScreen.main.scale)
        #elseif os(watchOS)
        return String(format: "%@/%@ (%@; watchOS %@; Scale/%0.2f)",
                      clientName,
                      clientVersion,
                      Device.current.safeDescription,
                      WKInterfaceDevice.current.systemVersion,
                      WKInterfaceDevice.currentDevice.screenScale)
        #elseif os(OSX)
        return String(format: "%@/%@ (Mac; macOS %@)",
                      clientName,
                      clientVersion,
                      NSProcessInfo.processInfo.operatingSystemVersionString)
        #else
        return nil
        #endif
    }
}
