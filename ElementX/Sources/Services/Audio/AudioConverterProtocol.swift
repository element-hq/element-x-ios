//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

protocol AudioConverterProtocol {
    func convertToOpusOgg(sourceURL: URL, destinationURL: URL) throws
    func convertToMPEG4AAC(sourceURL: URL, destinationURL: URL) throws
}

// sourcery: AutoMockable
extension AudioConverterProtocol { }
