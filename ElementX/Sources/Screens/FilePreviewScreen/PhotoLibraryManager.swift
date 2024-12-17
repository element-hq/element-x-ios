//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Photos

enum PhotoLibraryManagerError: Error {
    case notAuthorized
    case unknown(Error)
}

// sourcery: AutoMockable
protocol PhotoLibraryManagerProtocol {
    func addResource(_ type: PHAssetResourceType, at url: URL) async -> Result<Void, PhotoLibraryManagerError>
}

struct PhotoLibraryManager: PhotoLibraryManagerProtocol {
    func addResource(_ type: PHAssetResourceType, at url: URL) async -> Result<Void, PhotoLibraryManagerError> {
        do {
            try await PHPhotoLibrary.shared().performChanges {
                let request = PHAssetCreationRequest.forAsset()
                let options = PHAssetResourceCreationOptions()
                request.addResource(with: type, fileURL: url, options: options)
            }
            return .success(())
        } catch {
            if (error as NSError).code == PHPhotosError.accessUserDenied.rawValue {
                return .failure(.notAuthorized)
            } else {
                return .failure(.unknown(error))
            }
        }
    }
}
