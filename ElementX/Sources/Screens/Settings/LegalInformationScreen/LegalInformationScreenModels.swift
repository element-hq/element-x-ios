//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

// periphery:ignore - required for the architecture
enum LegalInformationScreenViewModelAction { }

struct LegalInformationScreenViewState: BindableState {
    let copyrightURL: URL
    let acceptableUseURL: URL
    let privacyURL: URL
}

enum LegalInformationScreenViewAction { }
