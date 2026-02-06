//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import UIKit

#if !os(OSX)
import DeviceKit
#endif

@MainActor
enum DiagnosticsTemplateBuilder {
    static func buildTemplate(userSession: UserSessionProtocol? = nil) -> String {
        let appVersion = InfoPlistReader.main.bundleShortVersionString
        let buildNumber = InfoPlistReader.main.bundleVersion
        let iOSVersion = UIDevice.current.systemVersion
        let locale = Locale.current.identifier
        let timezone = TimeZone.current.identifier
        let userID = userSession?.clientProxy.userID ?? UntranslatedL10n.quickDiagnosticsNotLoggedIn
        let deviceID = userSession?.clientProxy.deviceID ?? UntranslatedL10n.quickDiagnosticsUnknown
        
        #if !os(OSX)
        let deviceModel = Device.current.safeDescription
        #else
        let deviceModel = "Mac"
        #endif
        
        return UntranslatedL10n.quickDiagnosticsReportTemplate(UntranslatedL10n.quickDiagnosticsDescribeProblem,
                                                              appVersion,
                                                              buildNumber,
                                                              iOSVersion,
                                                              deviceModel,
                                                              locale,
                                                              timezone,
                                                              userID,
                                                              deviceID)
    }
}
