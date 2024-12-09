//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

extension MediaProviderMock {
    struct Configuration { }
    
    // swiftlint:disable:next cyclomatic_complexity
    convenience init(configuration: Configuration) {
        self.init()
        
        imageFromSourceSizeClosure = { mediaSource, _ in
            guard mediaSource != nil else {
                return nil
            }
            
            if mediaSource?.url == .mockMXCImage {
                if let url = Bundle.main.url(forResource: "preview_image", withExtension: "jpg"),
                   let data = try? Data(contentsOf: url) {
                    return UIImage(data: data)
                }
            } else if mediaSource?.url == .mockMXCVideo {
                if let url = Bundle.main.url(forResource: "preview_video", withExtension: "jpg"),
                   let data = try? Data(contentsOf: url) {
                    return UIImage(data: data)
                }
            } else if mediaSource?.url == .mockMXCAvatar {
                if let url = Bundle.main.url(forResource: "preview_avatar_room", withExtension: "jpg"),
                   let data = try? Data(contentsOf: url) {
                    return UIImage(data: data)
                }
            } else if mediaSource?.url == .mockMXCUserAvatar {
                if let url = Bundle.main.url(forResource: "preview_avatar_user", withExtension: "jpg"),
                   let data = try? Data(contentsOf: url) {
                    return UIImage(data: data)
                }
            }
            
            return UIImage(systemName: "photo")
        }
        
        loadImageFromSourceSizeClosure = { _, _ in
            guard let image = UIImage(systemName: "photo") else {
                fatalError()
            }
            
            return .success(image)
        }
        
        loadImageDataFromSourceClosure = { _ in
            guard let image = UIImage(systemName: "photo"),
                  let data = image.pngData() else {
                fatalError()
            }
            
            return .success(data)
        }
        
        loadFileFromSourceFilenameClosure = { _, _ in
            guard let url = Bundle.main.url(forResource: "preview_image", withExtension: "jpg") else {
                return .failure(.failedRetrievingFile)
            }
            
            return .success(.unmanaged(url: url))
        }
        
        loadImageRetryingOnReconnectionSizeClosure = { _, _ in
            Task {
                guard let image = UIImage(systemName: "photo") else {
                    fatalError()
                }
                
                return image
            }
        }
    }
}
