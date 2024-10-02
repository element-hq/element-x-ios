//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

extension MediaProviderMock {
    struct Configuration { }
    
    convenience init(configuration: Configuration) {
        self.init()
        
        imageFromSourceSizeClosure = { mediaSource, _ in
            guard mediaSource != nil else {
                return nil
            }
            
            if mediaSource?.url == .picturesDirectory {
                return Asset.Images.appLogo.image
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
        
        loadFileFromSourceBodyReturnValue = .failure(.failedRetrievingFile)
        
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
