//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias LegalInformationScreenViewModelType = StateStoreViewModel<LegalInformationScreenViewState, LegalInformationScreenViewAction>

class LegalInformationScreenViewModel: LegalInformationScreenViewModelType, LegalInformationScreenViewModelProtocol {
    init(appSettings: AppSettings) {
        super.init(initialViewState: LegalInformationScreenViewState(copyrightURL: appSettings.copyrightURL,
                                                                     acceptableUseURL: appSettings.acceptableUseURL,
                                                                     privacyURL: appSettings.privacyURL))
    }
}
