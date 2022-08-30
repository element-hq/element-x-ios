//
// Copyright 2021 New Vector Ltd
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

/// An analytics settings event from the user's account data.
struct AnalyticsSettings: Codable {
    static let eventType = "im.vector.analytics"
    
    /// A randomly generated analytics token for this user.
    /// This is suggested to be a UUID string.
    let id: String?
    
    /// Whether the user has opted in on web or not. This is unused on iOS but necessary
    /// to store here so that it's value is preserved when updating the account data if we
    /// generated an ID on iOS.
    ///
    /// `true` if opted in on web, `false` if opted out on web and `nil` if the web prompt is not yet seen.
    private let webOptIn: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id
        case webOptIn = "pseudonymousAnalyticsOptIn"
    }
}

extension AnalyticsSettings {
    #warning("Probably unnecessary now.")
    /// A dictionary representation of the settings.
    var dictionary: [AnyHashable: Any] {
        var dictionary = [AnyHashable: Any]()
        dictionary[CodingKeys.id.rawValue] = id
        dictionary[CodingKeys.webOptIn.rawValue] = webOptIn
        
        return dictionary
    }
}

extension AnalyticsSettings {
    #warning("This doesn't have the same level of protection as EI has…")
    static func new(currentEvent: AnalyticsSettings?) -> AnalyticsSettings {
        AnalyticsSettings(id: currentEvent?.id ?? UUID().uuidString,
                          webOptIn: currentEvent?.webOptIn)
    }
}
