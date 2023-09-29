//
// Copyright 2023 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
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
