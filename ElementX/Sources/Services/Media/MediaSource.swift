//
//  MediaSource.swift
//  ElementX
//
//  Created by Stefan Ceriu on 06/04/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation
import MatrixRustSDK

struct MediaSource: Equatable {
    let underlyingSource: MatrixRustSDK.MediaSource
    
    init(source: MatrixRustSDK.MediaSource) {
        underlyingSource = source
    }
    
    init(urlString: String) {
        underlyingSource = MatrixRustSDK.mediaSourceFromUrl(url: urlString)
    }
    
    // MARK: - Equatable
    
    static func == (lhs: MediaSource, rhs: MediaSource) -> Bool {
        return lhs.underlyingSource.url() == rhs.underlyingSource.url()
    }
}
