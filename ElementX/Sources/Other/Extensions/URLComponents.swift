//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

extension URLComponents {
    var fragmentQueryItems: [URLQueryItem]? {
        get {
            guard let fragment,
                  let fragmentQuery = fragment.components(separatedBy: "?").last else {
                return nil
            }
            
            var fragmentComponents = URLComponents()
            fragmentComponents.query = fragmentQuery
            
            return fragmentComponents.queryItems
        }
        
        set {
            var fragmentComponents = URLComponents()
            fragmentComponents.queryItems = newValue
            
            guard let fragmentQuery = fragmentComponents.query else {
                MXLog.error("Failed building fragment query")
                return
            }
            
            if let fragment, !fragment.isEmpty {
                var fragmentComponents = fragment.components(separatedBy: "?")
                
                guard let firstFragmentComponent = fragmentComponents.first else {
                    self.fragment = fragmentQuery
                    return
                }
                
                fragmentComponents = [firstFragmentComponent, fragmentQuery]
                
                self.fragment = fragmentComponents.joined(separator: "?")
                
            } else {
                fragment = "?" + fragmentQuery
            }
        }
    }
}
