//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum WaveformSource: Equatable {
    /// File URL of the source audio file
    case url(URL)
    /// Array of small number of pre-computed samples
    case data([Float])
}
