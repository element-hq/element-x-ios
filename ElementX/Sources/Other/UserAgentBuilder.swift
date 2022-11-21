//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation
import UIKit

#if !os(OSX)
import DeviceKit
#endif

final class UserAgentBuilder {
    class func makeASCIIUserAgent() -> String? {
        makeUserAgent()?.asciified()
    }
    
    private class func makeUserAgent() -> String? {
        let clientName = InfoPlistReader.target.bundleDisplayName
        let clientVersion = InfoPlistReader.target.bundleShortVersionString

        #if os(iOS)
        return String(
            format: "%@/%@ (%@; iOS %@; Scale/%0.2f)",
            clientName,
            clientVersion,
            Device.current.safeDescription,
            UIDevice.current.systemVersion,
            UIScreen.main.scale
        )
        #elseif os(tvOS)
        return String(
            format: "%@/%@ (%@; tvOS %@; Scale/%0.2f)",
            clientName,
            clientVersion,
            Device.current.safeDescription,
            UIDevice.current.systemVersion,
            UIScreen.main.scale
        )
        #elseif os(watchOS)
        return String(
            format: "%@/%@ (%@; watchOS %@; Scale/%0.2f)",
            clientName,
            clientVersion,
            Device.current.safeDescription,
            WKInterfaceDevice.current.systemVersion,
            WKInterfaceDevice.currentDevice.screenScale
        )
        #elseif os(OSX)
        return String(
            format: "%@/%@ (Mac; Mac OS X %@)",
            clientName,
            clientVersion,
            NSProcessInfo.processInfo.operatingSystemVersionString
        )
        #else
        return nil
        #endif
    }
}
