//
//  MockMediaProvider.swift
//  ElementX
//
//  Created by Stefan Ceriu on 17/03/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation
import UIKit

struct MockMediaProvider: MediaProviderProtocol {
    
    func imageFromSource(_ source: MediaSource?) -> UIImage? {
        return nil
    }
    
    func loadImageFromSource(_ source: MediaSource) async -> Result<UIImage, MediaProviderError> {
        return .failure(.failedRetrievingImage)
    }
    
    func imageFromURLString(_ urlString: String?) -> UIImage? {
        return nil
    }
        
    func loadImageFromURLString(_ urlString: String) async -> Result<UIImage, MediaProviderError> {
        return .failure(.failedRetrievingImage)
    }
}
