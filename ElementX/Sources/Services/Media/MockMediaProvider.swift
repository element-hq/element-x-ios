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
    
    func loadCurrentUserAvatar(_ completion: @escaping (Result<UIImage?, MediaProviderError>) -> Void) {
        
    }
    
    func imageFromSource(_ source: MediaSource?) -> UIImage? {
        return nil
    }
    
    func loadImageFromSource(_ source: MediaSource) async -> Result<UIImage, MediaProviderError> {
        return .failure(.failedRetrievingImage)
    }
    
    func imageFromURL(_ url: String?) -> UIImage? {
        return nil
    }
    
    func loadImageFromURL(_ url: String, _ completion: @escaping (Result<UIImage, MediaProviderError>) -> Void) {
        
    }
    
    func loadImageFromURL(_ url: String) async -> Result<UIImage, MediaProviderError> {
        return .failure(.failedRetrievingImage)
    }
}
