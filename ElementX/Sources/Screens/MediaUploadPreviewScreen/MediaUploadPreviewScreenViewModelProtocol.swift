//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine

@MainActor
protocol MediaUploadPreviewScreenViewModelProtocol {
    var actions: AnyPublisher<MediaUploadPreviewScreenViewModelAction, Never> { get }
    var context: MediaUploadPreviewScreenViewModelType.Context { get }
    
    /// Stops any ongoing media processing tasks.
    func stopProcessing()
}
