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

import AnalyticsEvents

enum AnalyticsMessageType {
    case location(LocationType)
    case poll
    case text
    case voiceMessage

    enum LocationType {
        case pin
        case user
    }
}

extension AnalyticsEvent.Composer.MessageType {
    init(_ analyticsMessageType: AnalyticsMessageType) {
        switch analyticsMessageType {
        case .location(let locationType):
            self = .init(locationType)
        case .poll:
            self = .Poll
        case .text:
            self = .Text
        case .voiceMessage:
            self = .VoiceMessage
        }
    }

    private init(_ locationType: AnalyticsMessageType.LocationType) {
        switch locationType {
        case .pin:
            self = .LocationPin
        case .user:
            self = .LocationUser
        }
    }
}
