//
//  FileManager.swift
//  ElementX
//
//  Created by Doug on 19/07/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation

extension FileManager {
    /// The URL of the primary app group container.
    var appGroupContainerURL: URL? {
        containerURL(forSecurityApplicationGroupIdentifier: ElementInfoPlist.appGroupIdentifier)
    }
}
