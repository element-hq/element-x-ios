//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import UIKit

#if !os(OSX)
import DeviceKit
#endif

nonisolated enum UserAgentBuilder {
    /// The screen scale used in the user agent. It never changes at runtime, so it's captured once
    /// on the main actor at launch (see the app coordinator) and read freely from any thread/process.
    /// Contexts without a screen (e.g. the NSE) keep the default.
    nonisolated(unsafe) static var displayScale: CGFloat = 2.0
    
    static func makeASCIIUserAgent() -> String {
        makeUserAgent()?.asciified() ?? "unknown"
    }
    
    static func makeUserAgent() -> String? {
        let clientName = InfoPlistReader.app.bundleDisplayName
        let clientVersion = InfoPlistReader.app.bundleShortVersionString
        
        #if os(iOS)
        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        let systemVersion = "\(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)"
        return if ProcessInfo.processInfo.isiOSAppOnMac {
            String(format: "%@/%@ (Mac; macOS %@; Scale/%0.2f)",
                   clientName,
                   clientVersion,
                   ProcessInfo.processInfo.operatingSystemVersionString,
                   displayScale)
        } else {
            String(format: "%@/%@ (%@; iOS %@; Scale/%0.2f)",
                   clientName,
                   clientVersion,
                   Device.current.safeDescription,
                   systemVersion,
                   displayScale)
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
